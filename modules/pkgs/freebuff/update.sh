#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq nix coreutils gnused

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

data=$(curl -sL https://registry.npmjs.org/freebuff/latest)
version=$(echo "$data" | jq -r .version)

sed -i 's/version = "[^"]*"/version = "'"$version"'"/' package.nix

for system in x86_64-linux aarch64-linux; do
  case "$system" in
    x86_64-linux) key="linux-x64" ;;
    aarch64-linux) key="linux-arm64" ;;
  esac
  raw_hash=$(echo "$data" | jq -r ".binaryChecksums[\"$key\"]")
  sri_hash=$(nix-hash --type sha256 --to-sri "$raw_hash")
  # The hashes live as `hash = "sha256-..."` inside each per-system block,
  # so scope the replacement to that system's block (the old
  # `${system} = "sha256-..."` pattern never matched).
  sed -i "/^[[:space:]]*${system} = {/,/^[[:space:]]*};/ s#hash = \"sha256-[^\"]*\"#hash = \"${sri_hash}\"#" package.nix
done
