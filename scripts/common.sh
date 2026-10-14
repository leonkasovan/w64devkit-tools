#!/bin/bash
# common.sh - Shared preamble for w64devkit install scripts
# Source this at the top of each install_*.sh script.
# Provides: INSTALL_PREFIX, FORCE_UPDATE, skip_if_installed()

INSTALL_PREFIX="${1:-C:/w64devkit}"
FORCE_UPDATE="${2:-false}"

skip_if_installed() {
    local pkgconfig_name="$1"
    local lib_path="$2"
    local display_name="$3"

    local pc_dir prefix_norm pc_norm
    if [ "$FORCE_UPDATE" != "true" ]; then
        prefix_norm=$(printf '%s' "$INSTALL_PREFIX" | tr '\\' '/' | sed 's:/*$::')
        pc_dir=$(pkg-config --variable=pcfiledir "$pkgconfig_name" 2>/dev/null || true)
        pc_norm=$(printf '%s' "$pc_dir" | tr '\\' '/' | tr '[:upper:]' '[:lower:]')
        prefix_norm=$(printf '%s' "$prefix_norm" | tr '[:upper:]' '[:lower:]')

        # A package found through inherited pkg-config paths is not evidence
        # that it is installed in this selected prefix.
        case "$pc_norm/" in
            "$prefix_norm/lib/pkgconfig/"*|"$prefix_norm/share/pkgconfig/"*)
                echo "[SKIPPED] $display_name already installed"
                exit 0
                ;;
        esac

        if [ -f "$lib_path" ]; then
            echo "[SKIPPED] $display_name already installed"
            exit 0
        fi
    fi
}
