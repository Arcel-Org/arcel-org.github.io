#!/usr/bin/env sh
# Seamless installer — https://install.north9.org/seamless.sh
# Usage:  curl -fsSL https://install.north9.org/seamless.sh | sh
# Builds from source — requires Rust 1.88+ and Seam cloned as a sibling directory.
set -eu

SEAM_REPO="https://github.com/North9-Labs/Seam"
SEAMLESS_REPO="https://github.com/North9-Labs/Seamless"
INSTALL_DIR="${SEAMLESS_INSTALL_DIR:-$HOME/.local/bin}"

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: '$1' is required — please install it" >&2
        exit 1
    fi
}

check_rust() {
    if ! command -v cargo >/dev/null 2>&1; then
        echo "error: Rust not found — install from https://rustup.rs" >&2
        exit 1
    fi
    VER=$(cargo --version | sed 's/cargo //' | cut -d. -f1-2)
    echo "  found cargo $VER"
}

main() {
    need git
    need curl
    check_rust

    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    printf 'cloning Seam (dependency)...\n'
    git clone --depth 1 "$SEAM_REPO" "${TMPDIR}/Seam" 2>&1 | tail -1

    printf 'cloning Seamless...\n'
    git clone --depth 1 "$SEAMLESS_REPO" "${TMPDIR}/Seamless" 2>&1 | tail -1

    printf 'building (this may take a few minutes)...\n'
    cd "${TMPDIR}/Seamless"
    cargo build --release --bin seamless --bin seamless-relay 2>&1 | tail -5

    mkdir -p "$INSTALL_DIR"
    cp "${TMPDIR}/Seamless/target/release/seamless" "${INSTALL_DIR}/seamless"
    cp "${TMPDIR}/Seamless/target/release/seamless-relay" "${INSTALL_DIR}/seamless-relay"

    printf '\n\033[32m✓\033[0m  installed seamless → %s/seamless\n' "$INSTALL_DIR"
    printf '\033[32m✓\033[0m  installed seamless-relay → %s/seamless-relay\n' "$INSTALL_DIR"

    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            printf '\n\033[33madd to your shell profile:\033[0m\n'
            printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
            ;;
    esac
}

main "$@"
