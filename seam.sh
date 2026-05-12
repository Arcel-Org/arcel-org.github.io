#!/usr/bin/env sh
# Seam installer — https://install.north9.org/seam.sh
# Usage:  curl -fsSL https://install.north9.org/seam.sh | sh
#         SEAM_INSTALL_DIR=/usr/local/bin sh seam.sh
set -eu

REPO="North9-Labs/Seam"
INSTALL_DIR="${SEAM_INSTALL_DIR:-$HOME/.local/bin}"

# ── Detect target triple ──────────────────────────────────────────────────────
detect_target() {
    OS=$(uname -s)
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64)         ARCH="x86_64" ;;
        aarch64|arm64)  ARCH="aarch64" ;;
        *)
            echo "error: unsupported architecture: $ARCH" >&2
            exit 1
            ;;
    esac

    case "$OS" in
        Linux)  echo "${ARCH}-unknown-linux-musl" ;;
        Darwin) echo "${ARCH}-apple-darwin" ;;
        *)
            echo "error: unsupported OS: $OS (try Windows Subsystem for Linux on Windows)" >&2
            exit 1
            ;;
    esac
}

# ── Require a command ─────────────────────────────────────────────────────────
need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: '$1' is required but not found — please install it" >&2
        exit 1
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    need curl
    need tar

    TARGET=$(detect_target)

    printf 'fetching latest release…\n'
    LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

    if [ -z "$LATEST" ]; then
        echo "error: could not fetch latest release — check your internet connection" >&2
        exit 1
    fi

    ASSET="seam-${TARGET}.tar.gz"
    BASE_URL="https://github.com/${REPO}/releases/download/${LATEST}"
    DOWNLOAD_URL="${BASE_URL}/${ASSET}"
    CHECKSUM_URL="${BASE_URL}/checksums.sha256"

    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    printf 'downloading seam %s for %s…\n' "$LATEST" "$TARGET"
    curl -fL --progress-bar "$DOWNLOAD_URL" -o "${TMPDIR}/${ASSET}" 2>/dev/tty \
        || curl -fL "$DOWNLOAD_URL" -o "${TMPDIR}/${ASSET}"

    printf 'verifying checksum…\n'
    curl -fsSL "$CHECKSUM_URL" -o "${TMPDIR}/checksums.sha256"
    cd "$TMPDIR"
    if command -v sha256sum >/dev/null 2>&1; then
        grep "$ASSET" checksums.sha256 | sha256sum -c - >/dev/null
    elif command -v shasum >/dev/null 2>&1; then
        grep "$ASSET" checksums.sha256 | shasum -a 256 -c - >/dev/null
    else
        printf 'warning: no sha256sum/shasum found — skipping checksum verification\n' >&2
    fi

    tar -xzf "$ASSET" -C "$TMPDIR"
    chmod +x "${TMPDIR}/seam"

    mkdir -p "$INSTALL_DIR"
    mv "${TMPDIR}/seam" "${INSTALL_DIR}/seam"

    printf '\n\033[32m✓\033[0m  installed seam %s → %s/seam\n' "$LATEST" "$INSTALL_DIR"

    case ":${PATH}:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            printf '\n\033[33madd to your shell profile:\033[0m\n'
            printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
            ;;
    esac
}

main "$@"
