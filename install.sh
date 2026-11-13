#!/usr/bin/env bash
# Install (symlink) the rotary_phone package into a Home Assistant config directory.
# Usage: ./install.sh /path/to/homeassistant/config
set -euo pipefail

CONFIG_DIR="${1:-}"
if [[ -z "$CONFIG_DIR" ]]; then
  echo "Usage: $0 /path/to/homeassistant/config" >&2
  exit 1
fi

PKG_SRC="$(cd "$(dirname "$0")" && pwd)/packages/rotary_phone"
WWW_SRC="$(cd "$(dirname "$0")" && pwd)/www/phone"

mkdir -p "$CONFIG_DIR/packages" "$CONFIG_DIR/www/phone"

if [[ -e "$CONFIG_DIR/packages/rotary_phone" && ! -L "$CONFIG_DIR/packages/rotary_phone" ]]; then
  echo "Existing non-symlink directory at $CONFIG_DIR/packages/rotary_phone; back it up first." >&2
  exit 1
fi
ln -sfn "$PKG_SRC" "$CONFIG_DIR/packages/rotary_phone"

# Symlink media dir contents (keep generated dyn.mp3 in place)
for f in "$WWW_SRC"/*; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"
  [[ "$base" == ".gitkeep" ]] && continue
  ln -sfn "$f" "$CONFIG_DIR/www/phone/$base"
done

echo "Installed. Ensure configuration.yaml contains:"
echo "  homeassistant:"
echo "    packages: !include_dir_named packages"
echo "Then restart Home Assistant."