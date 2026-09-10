#!/usr/bin/env bash
# Shared logging, validation, and utility functions for the HeCBench CI scripts.

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

# Colors for output (disabled if NO_COLOR is set or not a terminal)
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    readonly RED=$'\033[0;31m'
    readonly GREEN=$'\033[0;32m'
    readonly YELLOW=$'\033[1;33m'
    readonly BLUE=$'\033[0;34m'
    readonly NC=$'\033[0m' # No Color
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*" >&2
    fi
}

# ==============================================================================
# PATH VALIDATION & DETECTION
# ==============================================================================

# Validate ROCm installation is complete.
validate_rocm_path() {
    local path="$1"
    [[ -d "$path" ]] || return 1
    [[ -x "$path/bin/hipcc" ]] || return 1
    [[ -d "$path/lib" ]] || return 1
    return 0
}

# Require ROCM_PATH to be explicitly set and valid.
require_rocm_path() {
    if [[ -z "${ROCM_PATH:-}" ]]; then
        log_error "ROCM_PATH environment variable is not set"
        log_error "  export ROCM_PATH=/path/to/ROCm"
        return 1
    fi

    # Strip trailing slashes to prevent double slashes in paths.
    ROCM_PATH="${ROCM_PATH%/}"

    if ! validate_rocm_path "$ROCM_PATH"; then
        log_error "ROCM_PATH is set but invalid: $ROCM_PATH"
        log_error "ROCm installation must contain bin/hipcc and lib/"
        return 1
    fi

    log_success "Using ROCM_PATH: $ROCM_PATH"
    return 0
}

# Validate HeCBench source directory (has *-hip benchmark dirs).
validate_hecbench_src() {
    local path="$1"
    [[ -d "$path" ]] || return 1
    local hip_dirs
    hip_dirs=$(find "$path" -maxdepth 2 -name "*-hip" -type d 2>/dev/null | head -1)
    [[ -n "$hip_dirs" ]]
}

# Find HeCBench source directory: $HECBENCH_SRC, else relative to the script dir.
find_hecbench_src() {
    local script_dir="$1"

    if [[ -n "${HECBENCH_SRC:-}" ]]; then
        if validate_hecbench_src "$HECBENCH_SRC"; then
            echo "$HECBENCH_SRC"
            return 0
        else
            log_warn "HECBENCH_SRC is set but invalid: $HECBENCH_SRC"
        fi
    fi

    local relative_paths=(
        "$script_dir/../HeCBench/src"
        "$script_dir/../../HeCBench/src"
        "$script_dir/HeCBench/src"
    )

    for path in "${relative_paths[@]}"; do
        local abs_path
        abs_path=$(cd "$path" 2>/dev/null && pwd)
        if [[ -n "$abs_path" ]] && validate_hecbench_src "$abs_path"; then
            log_debug "Found HeCBench source at: $abs_path"
            echo "$abs_path"
            return 0
        fi
    done

    return 1
}

# ==============================================================================
# SHARED-MEMORY (/dev/shm) HOUSEKEEPING
# ==============================================================================
# OpenMPI/RCCL leave per-rank backing files in /dev/shm; a SIGKILL'd or timed-out
# run leaks them, and on a small /dev/shm (Docker default 64 MiB) they accumulate
# until mpirun fails with "not enough space". Call between benchmarks. Scoped to
# the current user so other tenants on shared hosts are untouched.
cleanup_stale_shm() {
    [[ -d /dev/shm ]] || return 0
    local user="${USER:-$(id -un)}"
    # -user filter prevents touching other tenants' files on shared hosts.
    # 2>/dev/null swallows the harmless ENOENT when the glob has no matches.
    find /dev/shm -maxdepth 1 -user "$user" \
        \( -name 'vader_segment.*' -o -name 'nccl-*' \) \
        -delete 2>/dev/null || true
}

# ==============================================================================
# BENCHMARK OUTPUT VALIDATION
# ==============================================================================

# Scan a benchmark's log file for validation failures that the exit code missed.
# Many HeCBench benchmarks print PASS/FAIL but exit 0 regardless.
# Returns 0 if output looks clean, 1 if suspect lines were found.
# Writes the first few suspect lines to stdout for logging.
check_output_validation() {
    local log="$1"

    [[ ! -s "$log" ]] && return 0

    local hits
    hits=$(
        grep -i -E \
            -e '\bFAIL(ED)?\b' \
            -e '\bMISMATCH\b' \
            -e '\bwrong result\b' \
            -e '\bdoes not match\b' \
            -e '\bTest Failed\b' \
            -e '\bincorrect\S*:\s*[1-9]' \
            -e 'hipblas\S+ failed' \
            -e 'rocblas\S+ failed' \
            -e ':\s*nan\b' \
            -e 'No such file or directory' \
            "$log" 2>/dev/null \
        | grep -v -i \
            -e '0 .* failed' \
            -e 'fail\(ures\?\|ed\):.\?[[:space:]]*0' \
            -e '\bno fail' \
            -e '\bwithout fail' \
            -e '\bif .*fail' \
            -e '\bon fail' \
            -e '#.*fail' \
            -e 'incorrect\S*:\s*0' \
            -e 'warning:' \
            -e 'note:' \
            -e '^\s*[0-9]\+\s*|' \
            -e '^/.*\.\(cpp\|c\|h\|hpp\|cc\)\b' \
            -e '^make\[' \
            -e '^hipcc' \
            -e '^amdclang' \
            -e '\.cpp:' \
            -e '\.cu:' \
            -e '\.h:' \
            -e 'hypre_assert' \
            -e 'hypre_error' \
        || true
    )

    if [[ -n "$hits" ]]; then
        echo "$hits" | head -5
        return 1
    fi

    return 0
}
