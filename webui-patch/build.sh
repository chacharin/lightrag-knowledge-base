#!/bin/sh
# Rebuild ../webui from the LightRAG source of $LIGHTRAG_VERSION plus lightrag-webui-$LIGHTRAG_VERSION.patch.
# Needs only git and Docker (the build runs in the oven/bun image). Run from anywhere:
#   sh webui-patch/build.sh
set -eu

LIGHTRAG_VERSION="${LIGHTRAG_VERSION:-v1.5.7}"
BUN_IMAGE="${BUN_IMAGE:-oven/bun:1.3.14}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "1/4 LightRAG $LIGHTRAG_VERSION source"
git clone -q --depth 1 --branch "$LIGHTRAG_VERSION" https://github.com/HKUDS/LightRAG.git "$WORK/src"

echo "2/4 apply the knowledge-base patch"
git -C "$WORK/src" apply "$HERE/lightrag-webui-$LIGHTRAG_VERSION.patch"

echo "3/4 build (bun install + vite build in $BUN_IMAGE)"
docker run --rm -v "$WORK/src:/src" -w /src/lightrag_webui "$BUN_IMAGE" \
  sh -c "bun install --frozen-lockfile && bun run build"

echo "4/4 copy into $ROOT/webui (kb-config.js is kept)"
[ -f "$ROOT/webui/kb-config.js" ] && cp "$ROOT/webui/kb-config.js" "$WORK/kb-config.js"
rm -rf "$ROOT/webui"
cp -r "$WORK/src/lightrag/api/webui" "$ROOT/webui"
[ -f "$WORK/kb-config.js" ] && cp "$WORK/kb-config.js" "$ROOT/webui/kb-config.js"
echo "done - restart LightRAG: docker compose restart lightrag"
