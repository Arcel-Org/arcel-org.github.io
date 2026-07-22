#!/usr/bin/env sh
# arcel installer — https://install.arcel.org/arcel.sh
# Usage:  curl -fsSL https://install.arcel.org/arcel.sh | sh
set -eu

REPO="Arcel-Org/arcel"

# ── Require a command ─────────────────────────────────────────────────────────
need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: '$1' is required but not found — please install it" >&2
        exit 1
    fi
}

# ── Check Python version ──────────────────────────────────────────────────────
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
    echo "error: Python 3.10+ is required — https://python.org" >&2
    exit 1
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    need curl
    need docker

    PYTHON=$(check_python)

    printf 'fetching latest release…\n'
    LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

    if [ -z "$LATEST" ]; then
        # fall back to installing from main
        INSTALL_URL="git+https://github.com/${REPO}.git#egg=arcel[mcp]"
        printf 'no release found — installing from main branch\n'
    else
        INSTALL_URL="git+https://github.com/${REPO}.git@${LATEST}#egg=arcel[mcp]"
        printf 'installing arcel %s…\n' "$LATEST"
    fi

    "$PYTHON" -m pip install --quiet "$INSTALL_URL"

    printf 'running arcel install (hooks + MCP server)…\n'
    "$PYTHON" -m arcel --install

    printf '\n\033[32m✓\033[0m  arcel installed — restart Claude Code\n'
    printf '\n    Sandbox: every command runs in Docker — your machine is always safe\n'
    printf '    Memory:  structured state survives /compact and session restarts\n\n'
}

main "$@"
