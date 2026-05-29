#!/usr/bin/env sh
# Fob installer — https://install.north9.org/fob.sh
# Usage:  curl -fsSL https://install.north9.org/fob.sh | sh
# Builds from source — requires Rust 1.75+.
set -eu

FOB_REPO="https://github.com/North9-Labs/Fob"
INSTALL_DIR="${FOB_INSTALL_DIR:-$HOME/.local/bin}"

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: '$1' is required — please install it" >&2
        exit 1
    fi
}

main() {
    need git
    if ! command -v cargo >/dev/null 2>&1; then
        echo "error: Rust not found — install from https://rustup.rs" >&2
        exit 1
    fi

    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    printf 'cloning Fob...\n'
    git clone --depth 1 "$FOB_REPO" "${TMPDIR}/Fob" 2>&1 | tail -1

    printf 'building (this may take a few minutes)...\n'
    cd "${TMPDIR}/Fob"
    cargo build --release -p fob-cli 2>&1 | tail -5

    mkdir -p "$INSTALL_DIR"
    cp "${TMPDIR}/Fob/target/release/fob" "${INSTALL_DIR}/fob"

    printf '\n\033[32m✓\033[0m  installed fob → %s/fob\n' "$INSTALL_DIR"

    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            printf '\n\033[33madd to your shell profile:\033[0m\n'
            printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
            ;;
    esac
}

main "$@"
