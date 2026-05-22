#!/usr/bin/env sh
# Sift installer — https://install.north9.org/sift.sh
# Usage:  curl -fsSL https://install.north9.org/sift.sh | sh
set -eu

REPO="North9-Labs/Sift"

need() { command -v "$1" >/dev/null 2>&1 || { echo "error: '$1' required" >&2; exit 1; }; }

check_python() {
    for cmd in python3 python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            ver=$("$cmd" -c 'import sys; print(sys.version_info >= (3,10))' 2>/dev/null || echo False)
            [ "$ver" = "True" ] && echo "$cmd" && return
        fi
    done
    echo "error: Python 3.10+ required" >&2; exit 1
}

main() {
    need curl; PYTHON=$(check_python)
    LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    if [ -z "$LATEST" ]; then
        INSTALL_URL="git+https://github.com/${REPO}.git#egg=sift"
    else
        INSTALL_URL="git+https://github.com/${REPO}.git@${LATEST}#egg=sift"
        printf 'installing sift %s…\n' "$LATEST"
    fi
    "$PYTHON" -m pip install --quiet "$INSTALL_URL"
    "$PYTHON" -m sift --install
    printf '\n\033[32m✓\033[0m  sift installed — restart Claude Code\n'
    printf '\n    SQL: query any CSV or JSON file without reading it all\n\n'
}

main "$@"
