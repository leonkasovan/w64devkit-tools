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

    if [ "$FORCE_UPDATE" != "true" ] && ( pkg-config --exists "$pkgconfig_name" 2>/dev/null || [ -f "$lib_path" ] ); then
        echo "[SKIPPED] $display_name already installed"
        exit 0
    fi
}
