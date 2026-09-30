#!/usr/bin/env bash
# Append --offload-arch=$(HIP_ARCH) to bare "hipcc" in HeCBench HIP Makefiles.
# HIP_ARCH (not ARCH) avoids clashing with benchmarks that use ARCH (e.g. dp4a-hip).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh" || {
    echo "ERROR: Failed to load common library" >&2
    exit 1
}

require_rocm_path || exit 1

HECBENCH_SRC=$(find_hecbench_src "$SCRIPT_DIR") || {
    log_error "Cannot find HeCBench src directory"
    exit 1
}

# ==============================================================================
# FUNCTIONS
# ==============================================================================

find_makefiles() {
    local makefiles=()
    while IFS= read -r -d '' makefile; do
        makefiles+=("$makefile")
    done < <(find "$HECBENCH_SRC" -path "*-hip/*" -name "Makefile" -type f ! -name "*.bak*" -print0 | sort -z)

    if [[ ${#makefiles[@]} -eq 0 ]]; then
        log_error "No Makefiles found in $HECBENCH_SRC"
        return 1
    fi

    printf '%s\n' "${makefiles[@]}"
    return 0
}

uses_hipcc() {
    grep -q "\bhipcc\b" "$1"
}

# Returns: 0 modified, 3 no hipcc usage.
modify_makefile() {
    local makefile="$1"
    local rel_path="${makefile#$HECBENCH_SRC/}"

    # Skip Makefiles that don't use hipcc (wrappers, pytorch).
    if ! uses_hipcc "$makefile"; then
        return 3
    fi

    # Provide a HIP_ARCH default unless the Makefile sets its own (e.g. dp-hip).
    if ! grep -q "^HIP_ARCH.*=" "$makefile"; then
        {
            echo "# User-configurable architecture (default: gfx906)"
            echo "HIP_ARCH ?= gfx906"
            echo ""
            cat "$makefile"
        } > "${makefile}.tmp" && mv "${makefile}.tmp" "$makefile"
    fi

    # Append the flag to bare hipcc; the grep guard makes re-runs idempotent.
    if ! grep -qF 'hipcc --offload-arch=$(HIP_ARCH)' "$makefile"; then
        sed -i "s#\(^\|[^/})]\)\bhipcc\b#\1hipcc --offload-arch=\$(HIP_ARCH)#g" "$makefile"
    fi

    log_success "Modified: $rel_path"
    return 0
}

process_makefiles() {
    local -a makefiles
    mapfile -t makefiles < <(find_makefiles)
    if [[ ${#makefiles[@]} -eq 0 ]]; then
        return 1
    fi

    log_info "Processing ${#makefiles[@]} Makefiles..."
    echo ""

    local modified=0 no_hipcc=0 failed=0
    for makefile in "${makefiles[@]}"; do
        local rel_path="${makefile#$HECBENCH_SRC/}"
        modify_makefile "$makefile"
        case $? in
            0) modified=$((modified + 1)) ;;
            3) no_hipcc=$((no_hipcc + 1)) ;;
            *) log_error "Failed to modify: $rel_path"; failed=$((failed + 1)) ;;
        esac
    done

    echo ""
    log_info "========================================"
    log_info "Total Makefiles: ${#makefiles[@]}"
    log_success "Modified: $modified"
    log_info "No hipcc usage: $no_hipcc"
    [[ $failed -gt 0 ]] && { log_error "Failed: $failed"; return 2; }
    return 0
}

# ==============================================================================
# MAIN
# ==============================================================================

log_info "========================================"
log_info "HeCBench Makefile Modifier"
log_info "========================================"
log_info "ROCm Path:       $ROCM_PATH"
log_info "HeCBench Source: $HECBENCH_SRC"
echo ""

process_makefiles || exit $?

echo ""
log_success "Makefile modification complete!"
