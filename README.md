# ZoomArchy

ZoomArchy is an Omarchy/Quickshell overlay plugin that provides a screen magnifier lens with a spotlight effect. It captures the current screen on activation and displays a fullscreen overlay with a movable magnified area that follows the cursor.

- **Plugin ID:** `jp.zoomarchy`
- **Version:** `0.1.0`
- **Kind:** `overlay` (Quickshell/Omarchy plugin)
- **Entry point:** `Overlay.qml`

## Current functionality

Based on the current implementation (`.config/omarchy/plugins/zoomarchy/Overlay.qml`):

- **Activation:** summoned as the `jp.zoomarchy` overlay (intended shortcut: `Super+Z`, depending on your Omarchy shortcut configuration).
- **Screenshot capture:** runs `grim /tmp/zoomarchy-screenshot.png` when opened and shows the captured image in the overlay.
- **Magnifier lens:** a 200×200 px clipped, scaled view of the captured screenshot follows the cursor position.
- **Zoom behavior:**
  - Initial zoom level: `2.0`
  - Minimum zoom: `1.0`
  - Maximum zoom: `5.0`
  - **Left click:** increases zoom by `1.0` (up to max)
  - **Mouse wheel:** adjusts zoom by `±0.5` (clamped to min/max)
  - **Reopen while already shown:** resets zoom to `2.0`
- **Spotlight effect:** a radial spotlight/dimming overlay centered on the cursor is drawn over the screen.
- **Close:** `Escape` closes the overlay and clears the current screenshot path/state.

## How it works

1. When activated, ZoomArchy captures the current screen using `grim`.
2. The overlay displays the captured screenshot fullscreen.
3. A magnified lens and spotlight follow the cursor over that captured image.
4. Interactions (click/wheel/Escape) update zoom or close the overlay.

> **Note:** The magnifier operates on a screenshot taken at activation time (a static snapshot), not a continuously live-updating view of the desktop.

## Requirements

- An Omarchy environment with Quickshell shell/plugin support
- `omarchy` CLI available in `PATH`
- `grim` (Wayland screenshot tool) available in `PATH`
- A Wayland/Hyprland-based Omarchy session (the plugin uses `Quickshell`, `Quickshell.Hyprland`, and `Quickshell.Wayland` imports)

## Installation

### From this repository (local install script)

```bash
git clone <repository-url>
cd ZoomArchy
bash install.sh
```

The root `install.sh` script:
- checks for `grim` and `omarchy`
- copies plugin files from `.config/omarchy/plugins/zoomarchy/` to `~/.config/omarchy/plugins/jp.zoomarchy/`
- runs `omarchy plugin validate ~/.config/omarchy/plugins/jp.zoomarchy`
- enables the plugin with `omarchy plugin enable jp.zoomarchy`
- appends `panel jp.zoomarchy` to `~/.config/omarchy/default/omarchy/shortcuts` if that file exists and the entry is missing (idempotent)
- checks common Hyprland config locations for an existing binding referencing `jp.zoomarchy` **without modifying Hyprland configuration**; if none is found, it prints a manual `Super+Z` binding instruction

### Manual copy

```bash
mkdir -p ~/.config/omarchy/plugins/jp.zoomarchy
cp -r .config/omarchy/plugins/zoomarchy/* ~/.config/omarchy/plugins/jp.zoomarchy/
omarchy plugin validate ~/.config/omarchy/plugins/jp.zoomarchy
omarchy plugin enable jp.zoomarchy
```

After installation/enabling, reload or restart the shell as needed for your Omarchy setup (for example: `omarchy restart shell`).

#### Super+Z shortcut binding

`Super+Z` activation depends on a Hyprland/Omarchy keybinding that summons/toggles the `jp.zoomarchy` panel. Because Hyprland configuration layouts vary between setups, the root installer **does not automatically edit your Hyprland configuration**.

- If a binding referencing `jp.zoomarchy` is already present, the installer leaves it unchanged.
- If no binding is detected, add the following to the appropriate bindings/config file for your setup (only once, and only if not already present):

```lua
o.bind("SUPER + Z", "ZoomArchy zoom", { panel = "jp.zoomarchy" })
```

You can also activate the overlay without a keybinding by running:

```bash
omarchy-shell shell summon jp.zoomarchy '{}'
```

## Usage

- **Activate:** trigger the overlay via your configured shortcut (e.g. `Super+Z`) or with `omarchy-shell shell summon jp.zoomarchy '{}'`
- **Move mouse:** move the magnifier lens and spotlight
- **Left click:** increase zoom (`+1.0`, up to `5.0`)
- **Scroll wheel:** fine-tune zoom (`±0.5`, range `1.0`–`5.0`)
- **Escape:** close the overlay
- **Activate again while open:** resets zoom to `2.0`

## Plugin files and behavior notes

- **Manifest:** `.config/omarchy/plugins/zoomarchy/manifest.json`
  - `id`: `jp.zoomarchy`
  - `version`: `0.1.0`
  - `kinds`: `["overlay"]`
  - `keepLoaded`: `true`
  - `entryPoints.overlay`: `Overlay.qml`
- **Overlay implementation:** `.config/omarchy/plugins/zoomarchy/Overlay.qml`
- **Plugin install/uninstall helpers (plugin directory):**
  - `.config/omarchy/plugins/zoomarchy/install.sh` creates `~/.config/omarchy/apps/zoomarchy.env` (template/default values) if missing.
  - `.config/omarchy/plugins/zoomarchy/uninstall.sh` removes `/usr/local/share/omarchy/apps/zoomarchy.env` if present.
- **Root repository helpers:** `install.sh` and `uninstall.sh` install/remove the plugin in `~/.config/omarchy/plugins/jp.zoomarchy` and manage the local shortcut/config entries described above.

> **Configuration note:** `zoomarchy.env` templates/defaults may be created by install scripts, but the current `Overlay.qml` implementation does not read or apply environment/config values (zoom level, colors, etc. are defined in code).

## Uninstallation

### Using the repository script

```bash
bash uninstall.sh
```

The root `uninstall.sh` script:
- disables the plugin (`omarchy plugin disable jp.zoomarchy`)
- removes `~/.config/omarchy/plugins/jp.zoomarchy`
- removes `~/.config/omarchy/apps/zoomarchy.env` if present
- removes a `panel jp.zoomarchy` entry from `~/.config/omarchy/default/omarchy/shortcuts` if present

If you manually added a `Super+Z` Hyprland binding for `jp.zoomarchy`, remove it manually from your Hyprland configuration if you no longer want it.

### Manual removal

```bash
omarchy plugin disable jp.zoomarchy
rm -rf ~/.config/omarchy/plugins/jp.zoomarchy
```

Remove any local shortcut/config entries you added manually if applicable.

## Repository contents

This repository contains the Omarchy plugin implementation in `.config/omarchy/plugins/zoomarchy/` as well as additional legacy/experimental Qt/C++ application files in the repository root (e.g. `main.cpp`, `main.qml`, `zoomarchy.pro`, `Makefile`, and build artifacts). The documented, current ZoomArchy functionality described above is provided by the Quickshell overlay plugin (`Overlay.qml`).

## Known limitations

- Uses a screenshot captured at activation time (`grim` to `/tmp/zoomarchy-screenshot.png`); the overlay does not update live as underlying windows change.
- Depends on `grim` and a compatible Omarchy/Quickshell Wayland environment.
- Behavior and appearance have been developed and adjusted primarily for the author's setup; results may vary across hardware, displays, scaling, themes, and compositor configurations.
- No text selection, OCR, or text extraction is implemented in the current overlay.
- Runtime zoom/appearance settings are currently hardcoded in `Overlay.qml` (install-generated config files are not consumed by the overlay).

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE) for details.

## Project Status & Contributions

ZoomArchy currently works and has been optimized for my own Omarchy machine and setup. Your mileage may vary on other hardware or configurations.

**Contributions are welcome!** Feel free to open issues, suggest improvements, or submit pull requests.

Please note that this project is not currently intended to be validated or submitted through the official Omarchy Marketplace. Quite simply: **we don't care about Marketplace validation right now.**

The project is structured in a way that could make Marketplace submission possible in the future. However, pursuing that is not a current goal, and it has **zero priority**. The focus is on making ZoomArchy work well and keeping it useful.
