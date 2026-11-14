# ZoomArchy

ZoomArchy is an Omarchy/Quickshell overlay plugin that provides a screen magnifier lens with a spotlight effect. It captures the current screen on activation and displays a fullscreen overlay with a movable magnified area that follows the cursor.

- **GitHub:** <https://github.com/vlaktaks/ZoomArchy>
- **Plugin ID:** `jp.zoomarchy`
- **Version:** `0.1.1`
- **Kind:** `overlay` (Quickshell/Omarchy plugin)
- **Entry point:** `Overlay.qml`

## Repository structure

This repository is a standalone Omarchy plugin repository: the **repository root is directly the installable plugin**. The following files are at the root level:

- `manifest.json` — plugin manifest
- `Overlay.qml` — overlay entrypoint (active implementation)

Other files at the root include documentation and repository metadata (e.g. `README.md`, `AGENTS.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`, `.gitattributes`), and project infrastructure in `.github/` (CI workflow and Dependabot configuration).

The canonical plugin ID is `jp.zoomarchy`. When installed, the plugin belongs in:

`~/.config/omarchy/plugins/jp.zoomarchy/`

## Current functionality

Based on the current implementation (`Overlay.qml`):

- **Activation:** summoned as the `jp.zoomarchy` overlay panel (for example via a manually configured shortcut such as `Super+Z`, or by direct summon command).
- **Screenshot capture:** runs `grim /tmp/zoomarchy-screenshot.png` when opened and shows the captured image in the overlay.
- **Magnifier lens:** a 200 × 200 px clipped, scaled view of the captured screenshot follows the cursor position.
- **Zoom behavior:**
  - Initial zoom level: `2.0`
  - Minimum zoom: `1.0`
  - Maximum zoom: `5.0`
  - **Left mouse click:** increase zoom level by `1.0` (up to maximum)
  - **Right mouse click:** decrease zoom level by `1.0` (down to minimum)
  - **Mouse wheel:** adjust zoom level in steps of `0.5` (clamped to minimum/maximum)
  - **Reopen while overlay is active:** zoom level is reset to `2.0`
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

### Recommended: Omarchy plugin manager

Install directly from the GitHub repository:

```bash
omarchy plugin add https://github.com/vlaktaks/ZoomArchy.git --enable
```

This installs the plugin into `~/.config/omarchy/plugins/jp.zoomarchy/` (canonical plugin ID: `jp.zoomarchy`), validates it, and (with `--enable`) enables it. The repository root is the installable plugin root (`manifest.json` and `Overlay.qml` are at root level).

If you install without `--enable`, you can use the same repository URL and then enable the plugin explicitly:

```bash
omarchy plugin add https://github.com/vlaktaks/ZoomArchy.git
omarchy plugin enable jp.zoomarchy
```

After installation/enabling or after making changes, the Omarchy shell may need to rescan plugins. A locally tested way to rescan plugins is:

```bash
omarchy-shell shell rescanPlugins
```

### Local development / manual install

To test a local checkout as the installed plugin, install from the repository/plugin root (where `manifest.json` and `Overlay.qml` are located):

```bash
mkdir -p ~/.config/omarchy/plugins/jp.zoomarchy
install -m644 manifest.json ~/.config/omarchy/plugins/jp.zoomarchy/
install -m644 Overlay.qml ~/.config/omarchy/plugins/jp.zoomarchy/
omarchy plugin validate ~/.config/omarchy/plugins/jp.zoomarchy
omarchy plugin enable jp.zoomarchy
omarchy-shell shell rescanPlugins
```

Exclude local build artifacts, editor files, and other non-plugin files as appropriate for your checkout.

## Keyboard shortcut (Super+Z) — manual example

`Super+Z` can be used as a manual Hyprland keybinding to summon/toggle the `jp.zoomarchy` panel. **The plugin itself does not configure any Hyprland shortcut.** Hyprland configuration layouts vary between setups, so this repository does not automatically modify your Hyprland configuration.

If no binding is already configured for `jp.zoomarchy`, add the following to the appropriate bindings/config file for your setup (only once, and only if not already present):

```lua
o.bind("SUPER + Z", "ZoomArchy zoom", { panel = "jp.zoomarchy" })
```

After adding or changing bindings, reload your Hyprland/Omarchy configuration as required by your setup.

You can also activate the overlay without a keybinding:

```bash
omarchy-shell shell summon jp.zoomarchy '{}'
```

## Usage

- **Activate:** use your configured shortcut (e.g. manual `Super+Z` binding) or `omarchy-shell shell summon jp.zoomarchy '{}'`
- **Move mouse:** move the magnifier lens (200 × 200 px) and spotlight
- **Left mouse click:** increase zoom level by `1.0` (up to `5.0`)
- **Right mouse click:** decrease zoom level by `1.0` (down to `1.0`)
- **Mouse wheel:** adjust zoom level in steps of `0.5` (range `1.0`–`5.0`)
- **Escape:** close the overlay
- **Activate again while overlay is active:** zoom level is reset to `2.0`

## Enabling, disabling, updating, and uninstalling

Using the Omarchy plugin manager:

```bash
# Enable / disable
omarchy plugin enable jp.zoomarchy
omarchy plugin disable jp.zoomarchy

# Update (for git-managed installs)
omarchy plugin update jp.zoomarchy

# Remove/uninstall
omarchy plugin remove jp.zoomarchy
```

If you added a manual `Super+Z` Hyprland binding for `jp.zoomarchy`, remove it manually from your Hyprland configuration if you no longer want it.

## Configuration

The current `Overlay.qml` implementation does not read external runtime configuration files. Zoom levels, lens size, and visual behavior are defined in code (`Overlay.qml`).

## Troubleshooting

- **Plugin not found / cannot enable:** ensure the plugin is installed in `~/.config/omarchy/plugins/jp.zoomarchy/` and validate it:
  ```bash
  omarchy plugin validate ~/.config/omarchy/plugins/jp.zoomarchy
  omarchy plugin list
  ```
- **Super+Z does nothing:** `Super+Z` is only an example of a manual Hyprland binding; the plugin does not configure shortcuts automatically. Verify a binding for `jp.zoomarchy` exists in your active configuration, or test with `omarchy-shell shell summon jp.zoomarchy '{}'`.
- **No screenshot / overlay appears:** ensure `grim` is installed and available in `PATH` (the overlay captures to `/tmp/zoomarchy-screenshot.png`).
- **After changes:** rescan plugins if needed. A locally tested command is:
  ```bash
  omarchy-shell shell rescanPlugins
  ```

## Development and testing

- **Project/agent instructions:** see [`AGENTS.md`](AGENTS.md) for architecture, conventions, validation, and contribution workflow details.
- **Plugin validation:**
  ```bash
  omarchy plugin validate .
  ```
- **Primary files:** `manifest.json`, `Overlay.qml`
- **Runtime verification:** activation, magnifier movement, zoom controls, Escape close, reopen/reset, and visual correctness on the target Omarchy/Hyprland desktop. Static validation does not replace runtime/visual verification.
- **CI:** GitHub Actions runs repository/plugin checks on `main` pushes and pull requests (`.github/workflows/ci.yml`). Omarchy-specific runtime validation remains a local requirement.
- **Dependency updates:** Dependabot is configured for GitHub Actions updates (`.github/dependabot.yml`).

## Known limitations

- Uses a screenshot captured at activation time (`grim` to `/tmp/zoomarchy-screenshot.png`); the overlay does not update live as underlying windows change.
- Depends on `grim` and a compatible Omarchy/Quickshell Wayland environment.
- Behavior and appearance have been developed and adjusted primarily for the author's setup; results may vary across hardware, displays, scaling, themes, and compositor configurations.
- No text selection, OCR, or text extraction is implemented.
- Runtime zoom/appearance settings are currently hardcoded in `Overlay.qml`.

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE) for details.

## Project Status & Contributions

ZoomArchy currently works and has been optimized for my own Omarchy machine and setup. Your mileage may vary on other hardware or configurations.

**Contributions are welcome!** Feel free to open issues, suggest improvements, or submit pull requests.

Please note that this project is not currently intended to be validated or submitted through the official Omarchy Marketplace. Quite simply: **we don't care about Marketplace validation right now.**

The project is structured in a way that could make Marketplace submission possible in the future. However, pursuing that is not a current goal, and it has **zero priority**. The focus is on making ZoomArchy work well and keeping it useful.
