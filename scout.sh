#!/usr/bin/env sh
# Scout installer — https://install.north9.org/scout.sh
# Usage:  curl -fsSL https://install.north9.org/scout.sh | sh
set -eu

REPO="North9-Labs/Scout"

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: '$1' is required but not found" >&2
        exit 1
    fi
}

check_python() {
    for cmd in python3 python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            ver=$("$cmd" -c 'import sys; print(sys.version_info >= (3,10))' 2>/dev/null || echo False)
            if [ "$ver" = "True" ]; then echo "$cmd"; return; fi
        fi
    done
    echo "error: Python 3.10+ is required" >&2; exit 1
}

main() {
    need curl
    PYTHON=$(check_python)
    printf 'fetching latest release…\n'
    LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    if [ -z "$LATEST" ]; then
        INSTALL_URL="git+https://github.com/${REPO}.git#egg=scout"
        printf 'no release — installing from main\n'
    else
        INSTALL_URL="git+https://github.com/${REPO}.git@${LATEST}#egg=scout"
        printf 'installing scout %s…\n' "$LATEST"
    fi
    "$PYTHON" -m pip install --quiet "$INSTALL_URL"
    "$PYTHON" -m scout --install
    printf '\n\033[32m✓\033[0m  scout installed — restart Claude Code\n'
    printf '\n    Web memory: fetch any URL, search its content later\n\n'
}

main "$@"
