#!/bin/bash
set -e

REPO="unger1984/codepatrol"
PLATFORM="${1:-claude}"

if [[ "$PLATFORM" != "claude" && "$PLATFORM" != "codex" ]]; then
    echo "Usage: $0 [claude|codex]"
    echo "  claude  — install to ~/.claude/skills/ (default)"
    echo "  codex   — install to ~/.codex/skills/"
    exit 1
fi

# Get latest release tag
TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
if [ -z "$TAG" ]; then
    echo "Error: could not fetch latest release"
    exit 1
fi

VERSION="${TAG#v}"
ARCHIVE="codepatrol-${VERSION}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading CodePatrol ${TAG}..."
curl -fsSL -o "$TMPDIR/$ARCHIVE" "$URL"

echo "Extracting..."
tar -xzf "$TMPDIR/$ARCHIVE" -C "$TMPDIR"

echo "Installing for ${PLATFORM}..."
cd "$TMPDIR" && bash install.sh "$PLATFORM"

echo ""
echo "CodePatrol ${TAG} installed for ${PLATFORM}."
