#!/usr/bin/env bash

set -e
if [ $# -lt 2 ]; then
    echo "Usage: $0 <nixpkgs-commit-hash> <package-name1> [<package-name2> ...]"
    exit 1
fi
COMMIT_HASH="$1"
shift
PACKAGES=("$@")
NIXPKGS_URL="https://github.com/NixOS/nixpkgs/archive/${COMMIT_HASH}.tar.gz"
NIXPKGS_PATH="nixpkgs-${COMMIT_HASH}"

if [ ! -d "$NIXPKGS_PATH" ]; then
    echo "Downloading nixpkgs at commit $COMMIT_HASH..."
    curl -L "$NIXPKGS_URL" -o "${COMMIT_HASH}.tar.gz"
    tar -xzf "${COMMIT_HASH}.tar.gz"
    rm "${COMMIT_HASH}.tar.gz"
fi
nix-shell -I nixpkgs="./${NIXPKGS_PATH}" -p "${PACKAGES[@]}"

