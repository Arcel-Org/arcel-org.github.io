#!/usr/bin/env sh
# Vault installer — https://install.north9.org/vault.sh
# Usage:  curl -fsSL https://install.north9.org/vault.sh | sh
set -eu

REPO="North9-Labs/Vault"

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
            if [ "$ver" = "True" ]; then
                echo "$cmd"
                return
            fi
        fi
    done
    echo "error: Python 3.10+ is required" >&2
    exit 1
}

main() {
    need curl
    PYTHON=$(check_python)

    printf 'fetching latest release…\n'
    LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

    if [ -z "$LATEST" ]; then
        INSTALL_URL="git+https://github.com/${REPO}.git#egg=vault"
        printf 'no release found — installing from main branch\n'
    else
        INSTALL_URL="git+https://github.com/${REPO}.git@${LATEST}#egg=vault"
        printf 'installing vault %s…\n' "$LATEST"
    fi

    "$PYTHON" -m pip install --quiet "$INSTALL_URL"
    "$PYTHON" -m vault --install

    printf '\n\033[32m✓\033[0m  vault installed — restart Claude Code\n'
    printf '\n    Secrets: encrypted credential store for agents (set NORTH9_VAULT_KEY first)\n\n'
}

main "$@"
