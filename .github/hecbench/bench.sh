#!/usr/bin/env bash
# Build and run the HeCBench HIP subset for the amdgcnspirv SPIR-V backend,
# self-verifying each benchmark's output. Results land in a bench_logs_* dir;
# the CI "Gate on HeCBench results" step reads those logs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ==============================================================================
# DEFAULTS
# ==============================================================================

# "amdgcnspirv-be" is the user-facing token (log dir suffix, prints); the make
# HIP_ARCH is plain amdgcnspirv, built via the default SPIR-V backend.
ARCH="amdgcnspirv-be"
HIPCC_ARCH="amdgcnspirv"

TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-300}
GPU_ID=${GPU_ID:-0}
BENCHMARK_FILTER=${BENCHMARK_FILTER:-}

show_usage() {
    cat <<EOF
Usage: $SCRIPT_NAME --filter LIST [OPTIONS]

Build and run the HeCBench HIP subset for the amdgcnspirv SPIR-V backend.

Options:
    --filter LIST      Comma-separated benchmark dir names (e.g. dp4a-hip,fft-hip)
    --timeout SECONDS  Per-benchmark timeout (default: $TIMEOUT_SECONDS)
    --gpu-id N         ROCR_VISIBLE_DEVICES value (default: $GPU_ID)
    --help, -h         Show this help

Environment Variables:
    ROCM_PATH          REQUIRED. Path to ROCm installation.
    HECBENCH_SRC       Path to HeCBench src (auto-detected if not set)
    HIP_CLANG_PATH     clang bin dir for hipcc to drive (default: \$ROCM_PATH/bin)

Output:
    $HECBENCH_LOG_DIR (CI), else bench_logs_YYYYMMDD_HHMMSS_amdgcnspirv-be/
        timings.csv    benchmark,build_seconds,run_seconds
        success.log    built and ran cleanly
        failed.log     non-zero exit (build or run)
        suspect.log    exit 0 but output contains validation failures
        timeout.log    exceeded --timeout
        <benchmark>.log per-benchmark combined build+run output
EOF
}

# ==============================================================================
# ARG PARSING
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)    show_usage; exit 0 ;;
        --filter)     BENCHMARK_FILTER="$2"; shift 2 ;;
        --timeout)    TIMEOUT_SECONDS="$2"; shift 2 ;;
        --gpu-id)     GPU_ID="$2"; shift 2 ;;
        *)            log_error "Unknown argument: $1"; show_usage; exit 1 ;;
    esac
done

if [[ -z "$BENCHMARK_FILTER" ]]; then
    log_error "--filter is required"
    show_usage
    exit 1
fi

# ==============================================================================
# VALIDATION & SETUP
# ==============================================================================

require_rocm_path || exit 1
HECBENCH_SRC=$(find_hecbench_src "$SCRIPT_DIR") || {
    log_error "Cannot find HeCBench src directory"
    exit 1
}

# CI sets HECBENCH_LOG_DIR (single source of truth); local runs get a timestamp.
LOG_DIR="${HECBENCH_LOG_DIR:-${SCRIPT_DIR}/bench_logs_$(date +%Y%m%d_%H%M%S)_${ARCH}}"
mkdir -p "$LOG_DIR"

export PATH="${ROCM_PATH}/bin:${PATH}"
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${LD_LIBRARY_PATH:-}"
export HIP_PATH="${ROCM_PATH}"
# HIP_CLANG_PATH points hipcc at the clang to drive; CI sets it to the freshly
# built LLVM bin dir. Unset -> fall back to $ROCM_PATH/bin.
if [[ -n "${HIP_CLANG_PATH:-}" ]]; then
    export HIP_CLANG_PATH
    export PATH="${HIP_CLANG_PATH}:${PATH}"
    export LD_LIBRARY_PATH="$(dirname "${HIP_CLANG_PATH}")/lib:${LD_LIBRARY_PATH}"
fi
# Runtime JIT (comgr) honors this for AMDGCN bitcode lookup; device libs are
# installed at the canonical ROCm layout ${ROCM_PATH}/amdgcn/bitcode.
export HIP_DEVICE_LIB_PATH="${ROCM_PATH}/amdgcn/bitcode"
export ROCR_VISIBLE_DEVICES="$GPU_ID"
ulimit -s unlimited 2>/dev/null || true

# libhipcxx <chrono> hard-errors on amdgcnspirv (no compile-time __gfx*__ macro);
# the define lets it through. NDEBUG keeps host asserts out of timing paths.
declare -a MAKE_ARGS=(
    HIP_ARCH="$HIPCC_ARCH"
    "EXTRA_CFLAGS=-D_LIBCUDACXX_ALLOW_UNSUPPORTED_ARCHITECTURE -DNDEBUG"
)

echo "benchmark,build_seconds,run_seconds" > "$LOG_DIR/timings.csv"
touch "$LOG_DIR/success.log" \
      "$LOG_DIR/failed.log" \
      "$LOG_DIR/suspect.log" \
      "$LOG_DIR/timeout.log"

log_info "==========================================="
log_info "HeCBench bench (build+run merged)"
log_info "==========================================="
log_info "ROCm path:    $ROCM_PATH"
log_info "HeCBench src: $HECBENCH_SRC"
log_info "Arch:         $ARCH"
log_info "Timeout:      ${TIMEOUT_SECONDS}s"
log_info "GPU ID:       $GPU_ID"
log_info "Logs:         $LOG_DIR"

# Clear the COMGR JIT cache: keys are the SPIR-V hash, so a runtime-only update
# (same SPIR-V) would otherwise serve stale native code.
if [[ -d "${HOME}/.cache/comgr" ]]; then
    log_info "Clearing COMGR cache (${HOME}/.cache/comgr) ..."
    rm -rf "${HOME}/.cache/comgr"
fi

echo ""

# ==============================================================================
# PER-BENCHMARK
# ==============================================================================

# check_output_validation() is defined in lib/common.sh.

bench_one() {
    local dir="$1"
    local name; name=$(basename "$dir")
    local log="$LOG_DIR/${name}.log"

    # Reclaim leaked OpenMPI/RCCL backing files in /dev/shm so an MPI benchmark
    # whose predecessor was SIGKILL'd doesn't fail with "not enough space".
    cleanup_stale_shm

    cd "$dir" || { log_error "$name: cannot cd to $dir"; return; }

    # Clean to ensure a deterministic build state.
    make clean &>/dev/null || true

    local build_start build_elapsed run_start run_elapsed rc

    # ---- Phase 1: BUILD (default target only) ----
    build_start=$(date +%s.%N)
    set +e
    timeout "$TIMEOUT_SECONDS" make "${MAKE_ARGS[@]}" &>"$log"
    rc=$?
    set -e
    build_elapsed=$(awk "BEGIN {printf \"%.3f\", $(date +%s.%N) - $build_start}")

    if [[ $rc -ne 0 ]]; then
        if [[ $rc -eq 124 ]]; then
            log_error "Timeout (build): $name (>${TIMEOUT_SECONDS}s)"
            echo "$name" >> "$LOG_DIR/timeout.log"
        else
            log_error "Failed (build): $name (exit $rc)"
            echo "$name" >> "$LOG_DIR/failed.log"
        fi
        cd "$SCRIPT_DIR"
        return
    fi

    # ---- Phase 2: RUN (no make overhead) ----
    # Ask the Makefile what `make run` runs (binary already built, so -n just
    # prints); join backslash-continuation lines into whole commands.
    local -a runcmds=()
    local accum=""
    while IFS= read -r line; do
        if [[ "$line" == *'\' ]]; then
            accum+="${line%\\} "
        else
            accum+="$line"
            [[ -n "$accum" ]] && runcmds+=("$accum")
            accum=""
        fi
    done < <(make -n run "${MAKE_ARGS[@]}" 2>/dev/null)
    [[ -n "$accum" ]] && runcmds+=("$accum")

    if [[ ${#runcmds[@]} -eq 0 ]]; then
        log_error "Failed: $name (no run commands found)"
        echo "$name" >> "$LOG_DIR/failed.log"
        cd "$SCRIPT_DIR"
        return
    fi

    run_start=$(date +%s.%N)
    set +e
    rc=0
    for cmd in "${runcmds[@]}"; do
        echo "+ $cmd" >>"$log"
        timeout "$TIMEOUT_SECONDS" bash -c "$cmd" &>>"$log" 2>&1
        rc=$?
        [[ $rc -ne 0 ]] && break
    done
    set -e
    run_elapsed=$(awk "BEGIN {printf \"%.3f\", $(date +%s.%N) - $run_start}")

    if [[ $rc -eq 0 ]]; then
        local time_detail="build ${build_elapsed}s, run ${run_elapsed}s"
        if check_output_validation "$log" >/dev/null; then
            log_success "$name (${time_detail})"
            echo "$name" >> "$LOG_DIR/success.log"
        else
            log_warn "$name (${time_detail}) — exit 0 but output validation suspect"
            echo "$name" >> "$LOG_DIR/suspect.log"
        fi
        echo "$name,$build_elapsed,$run_elapsed" >> "$LOG_DIR/timings.csv"
    elif [[ $rc -eq 124 ]]; then
        log_error "Timeout (run): $name (>${TIMEOUT_SECONDS}s)"
        echo "$name" >> "$LOG_DIR/timeout.log"
    else
        log_error "Failed (run): $name (exit $rc)"
        echo "$name" >> "$LOG_DIR/failed.log"
    fi

    cd "$SCRIPT_DIR"
}

# ==============================================================================
# DISCOVER & ITERATE
# ==============================================================================

declare -a dirs=()
IFS=',' read -ra wanted <<< "$BENCHMARK_FILTER"
for w in "${wanted[@]}"; do
    w="${w## }"; w="${w%% }"
    [[ -z "$w" ]] && continue
    local_dir="$HECBENCH_SRC/$w"
    [[ -d "$local_dir" ]] && dirs+=("$local_dir")
done
if [[ ${#dirs[@]} -eq 0 ]]; then
    log_error "Filter matched no benchmarks: $BENCHMARK_FILTER"
    exit 1
fi

log_info "Processing ${#dirs[@]} benchmarks..."
echo ""

for d in "${dirs[@]}"; do
    bench_one "$d"
done

# ==============================================================================
# SUMMARY
# ==============================================================================

count() {
    local f="$LOG_DIR/$1"
    [[ -f "$f" ]] && wc -l <"$f" | tr -d ' ' || echo 0
}

echo ""
log_info "==========================================="
log_info "Summary"
log_info "==========================================="
log_info "  Success:       $(count success.log)"
log_info "  Suspect:       $(count suspect.log)  (exit 0 but output has failures)"
log_info "  Failed:        $(count failed.log)"
log_info "  Timeout:       $(count timeout.log)"
log_info ""
log_info "Logs:    $LOG_DIR"
log_info "Timings: $LOG_DIR/timings.csv"
