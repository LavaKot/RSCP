#!/usr/bin/env bash
# RSCP @VER@ — самораспаковывающийся установщик (Linux x86-64).
#
#   ./rscp-@VER@-linux-x64-installer.sh                 установить в ~/.local
#   ./rscp-@VER@-linux-x64-installer.sh --to /opt/rscp  установить в /opt/rscp
#   ./rscp-@VER@-linux-x64-installer.sh --uninstall     удалить
#
# Бинарник rscp ставится в <prefix>/bin, примеры, плагин VS Code и INSTALL.txt
# в <prefix>/share/rscp. Префикс по умолчанию — ~/.local (обычно уже в PATH).
set -euo pipefail

VER="@VER@"
PREFIX="$HOME/.local"
MODE=install
while [[ $# -gt 0 ]]; do
  case "$1" in
    --to) PREFIX="${2:?--to needs a directory}"; shift 2 ;;
    --uninstall) MODE=uninstall; shift ;;
    -h|--help) grep '^#' "$0" | sed -n '2,9p; s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 64 ;;
  esac
done

BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/rscp"

if [[ $MODE == uninstall ]]; then
  rm -f "$BIN_DIR/rscp"
  rm -rf "$SHARE_DIR"
  # remove now-empty directories only (never touches dirs with other files)
  rmdir "$BIN_DIR" 2>/dev/null || true
  rmdir "$(dirname "$SHARE_DIR")" 2>/dev/null || true
  rmdir "$PREFIX" 2>/dev/null || true
  echo "[ok] RSCP removed from $PREFIX"
  exit 0
fi

echo "[..] RSCP @VER@: распаковка..."
PAYLOAD_LINE=$(awk '/^__RSCP_PAYLOAD__$/ { print NR + 1; exit 0 }' "$0")
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
tail -n +"$PAYLOAD_LINE" "$0" | tar xz -C "$TMP"

mkdir -p "$BIN_DIR" "$SHARE_DIR"
install -m 0755 "$TMP/rscp" "$BIN_DIR/rscp"
cp -r "$TMP/examples" "$SHARE_DIR/examples"
[[ -f "$TMP/rscp-$VER.vsix" ]] && cp "$TMP/rscp-$VER.vsix" "$SHARE_DIR/"
[[ -f "$TMP/INSTALL.txt" ]] && cp "$TMP/INSTALL.txt" "$SHARE_DIR/"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "[i] добавьте $BIN_DIR в PATH:  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

echo "[ok] $("$BIN_DIR/rscp" version)"
echo "[ok] бинарник: $BIN_DIR/rscp; примеры: $SHARE_DIR/examples"
exit 0
__RSCP_PAYLOAD__
