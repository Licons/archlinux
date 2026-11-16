#!/usr/bin/env bash
set -euo pipefail

# nemo-terminal 6.8.0 không hiện ô terminal trên nemo 6.8.x: NemoWindowSlot có thêm Revealer (3 con)
# mà extension chỉ chèn khi slot có đúng 2 con. Thay bằng bản upstream master đã sửa.
# Chạy lại được: gói đã có bản sửa (hoặc đã vá) thì bỏ qua. pacman -Syu ghi đè lại bản lỗi ⇒ chạy lại script.

FILE=/usr/share/nemo-python/extensions/nemo_terminal.py
URL=https://raw.githubusercontent.com/linuxmint/nemo-extensions/master/nemo-terminal/src/nemo_terminal.py
BROKEN='len(crowbar_pp_children) == 2'

[[ -f $FILE ]] || { echo "==> nemo-terminal not installed, skip"; exit 0; }
grep -qF "$BROKEN" "$FILE" || { echo "==> nemo-terminal already fixed, skip"; exit 0; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -sfL "$URL" -o "$TMP/nemo_terminal.py"
if grep -qF "$BROKEN" "$TMP/nemo_terminal.py"; then
    echo "==> upstream master still has the old check, not patching" >&2
    exit 1
fi
/usr/bin/python3 -m py_compile "$TMP/nemo_terminal.py"

sudo install -m644 "$TMP/nemo_terminal.py" "$FILE"
echo "==> nemo-terminal patched. Restart Nemo: nemo -q"
