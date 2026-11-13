#!/usr/bin/env bash
# Install the rotary_phone package into a Home Assistant config directory.
#
# Usage:
#   ./install.sh /path/to/homeassistant/config                 # symlink (HAOS / native)
#   ./install.sh --copy /path/to/homeassistant/config          # copy files (Docker, avoids broken symlinks)
#   ./install.sh --clean /path/to/homeassistant/config         # remove previous install, then install
#   ./install.sh --reinstall /path/to/homeassistant/config     # alias for --clean
#   ./install.sh --uninstall /path/to/homeassistant/config     # remove only
#   --force  allow deleting real (non-symlink) files/dirs
set -euo pipefail

MODE="install"
COPY=0
CONFIG_DIR=""
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --copy) COPY=1 ;;
    --clean|--reinstall) MODE="clean-install" ;;
    --uninstall) MODE="uninstall" ;;
    --force) FORCE=1 ;;
    -h|--help) sed -n '1,25p' "$0"; exit 0 ;;
    *) if [[ -z "$CONFIG_DIR" ]]; then CONFIG_DIR="$arg"; else echo "Unexpected arg: $arg" >&2; exit 1; fi ;;
  esac
done

if [[ -z "$CONFIG_DIR" ]]; then
  echo "Usage: $0 [--copy|--clean|--reinstall|--uninstall|--force] /path/to/homeassistant/config" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_SRC="$REPO_DIR/packages/rotary_phone"
WWW_SRC="$REPO_DIR/www/phone"

remove_path() {
  local target="$1"
  if [[ -L "$target" ]]; then
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    if [[ $FORCE -eq 1 ]]; then rm -rf "$target"; else echo "Refusing to delete non-symlink path: $target (use --force)" >&2; exit 1; fi
  fi
}

clean_previous() {
  echo "Cleaning previous rotary_phone installation in $CONFIG_DIR ..."
  remove_path "$CONFIG_DIR/packages/rotary_phone"
  for f in package.yaml scripts.yaml automations.yaml sensors.yaml rotary_phone.yaml dial_plans.yaml; do
    if [[ -L "$CONFIG_DIR/packages/$f" ]] || { [[ $FORCE -eq 1 ]] && [[ -e "$CONFIG_DIR/packages/$f" ]]; }; then
      remove_path "$CONFIG_DIR/packages/$f"
    fi
  done
  if [[ -d "$CONFIG_DIR/www/phone" ]]; then
    for f in "$CONFIG_DIR/www/phone"/*; do
      [[ -e "$f" || -L "$f" ]] || continue
      if [[ -L "$f" ]]; then
        link="$(readlink "$f" || true)"
        case "$link" in "$REPO_DIR"/*) rm -f "$f" ;; esac
      fi
    done
  fi
  echo "Cleaned."
}

case "$MODE" in
  uninstall) clean_previous; echo "Uninstalled."; exit 0 ;;
  clean-install) clean_previous ;;
esac

mkdir -p "$CONFIG_DIR/packages" "$CONFIG_DIR/www/phone"

if [[ $COPY -eq 1 ]]; then
  rm -rf "$CONFIG_DIR/packages/rotary_phone"
  mkdir -p "$CONFIG_DIR/packages/rotary_phone"
  cp -a "$PKG_SRC/." "$CONFIG_DIR/packages/rotary_phone/"
  echo "Copied package files (re-run after git pull to update)."
else
  ln -sfn "$PKG_SRC" "$CONFIG_DIR/packages/rotary_phone"
  echo "Symlinked package folder."
fi

# Media files
for f in "$WWW_SRC"/*; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"
  [[ "$base" == ".gitkeep" ]] && continue
  [[ "$base" == "dyn.mp3" ]] && continue
  if [[ $COPY -eq 1 ]]; then
    cp -f "$f" "$CONFIG_DIR/www/phone/$base"
  else
    ln -sfn "$f" "$CONFIG_DIR/www/phone/$base"
  fi
done

echo "Installed. Ensure configuration.yaml contains:"
echo "  homeassistant:"
echo "    packages: !include_dir_named packages"
echo "Then restart Home Assistant (or reload YAML packages)."