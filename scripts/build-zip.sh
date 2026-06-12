#!/usr/bin/env bash
# Build the distributable skill archive from the archify/ folder.
# Usage: scripts/build-zip.sh [output.zip]
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$repo_root/archify.zip}"

# Stage a clean copy: node_modules never ships; test/ is repo-only (the golden
# harness compares against ../examples at the repo root, which does not exist
# in an installed skill) — and the npm scripts that point at it are stripped
# from the shipped package.json so `npm test` can't crash for skill users.
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
rsync -a --exclude 'node_modules' --exclude 'test' --exclude '.DS_Store' \
  "$repo_root/archify/" "$stage/archify/"
node -e "
  const fs = require('fs');
  const p = '$stage/archify/package.json';
  const pkg = JSON.parse(fs.readFileSync(p, 'utf8'));
  delete pkg.scripts;
  fs.writeFileSync(p, JSON.stringify(pkg, null, 2) + '\n');
"

rm -f "$out"
(cd "$stage" && zip -r -X -q "$out" archify)

unzip -l "$out" | tail -1
echo "built $out"
