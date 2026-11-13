# Rotary Phone Home Assistant Package

A self-contained Home Assistant package that turns a rotary phone into a
voice-driven command console. Dialing a number triggers `script.rotary_phone_handler`,
which renders a Kokoro TTS response and optionally runs actions (e.g. controlling a
`splitflap_os` text display).

## Layout

```
packages/rotary_phone/      # drop into /config/packages/
  package.yaml              # script + (future) automations/sensors
  content/                  # reserved for extra package files
www/phone/                  # served at /local/phone/
  dyn.mp3                   # generated at runtime by Kokoro TTS (gitignored)
```

## Installation

### Home Assistant OS (HAOS)

1. Copy the `packages/rotary_phone/` folder into `/config/packages/`.
2. Ensure `configuration.yaml` contains:
   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```
3. Restart Home Assistant.

### Docker / Core (symlink)

```bash
git clone https://github.com/H0u0uinKy0um4/RotaryPhonePackage.git
cd RotaryPhonePackage
./install.sh /path/to/homeassistant/config
```

Or manually:

```bash
ln -sfn /path/to/RotaryPhonePackage/packages/rotary_phone /path/to/homeassistant/config/packages/rotary_phone
mkdir -p /path/to/homeassistant/config/www/phone
```

## Updating

```bash
cd /path/to/RotaryPhonePackage
git pull
```

HAOS users: re-copy `packages/rotary_phone/` (or pull in place if cloned) and restart.
Docker users: `git pull` is enough; reload scripts or restart Home Assistant.

## Requirements

- `shell_command.kokoro_render` must be defined (renders TTS to `www/phone/dyn.mp3`).
- `media_player.rotary_phone_speaker` entity.
- `sensor.outside_temperature` (optional, used by dial code 12).
- `splitflap_os` integration (optional, used by codes 331 and 300).

## Notes

- `www/phone/dyn.mp3` is generated at runtime and is intentionally gitignored.
- All automations, scripts and sensors live inside `packages/rotary_phone/` to keep
  the package portable. Avoid hardcoded absolute paths.