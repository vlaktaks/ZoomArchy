# Changelog

All notable changes to this project are documented in this file.

## [0.1.1]

### Changed
- Removed unused QML imports from `Overlay.qml`.
- Removed temporary diagnostic logging and log-only code from `Overlay.qml` while preserving existing zoom and interaction logic.

### Added
- Repository-wide agent instructions in `AGENTS.md`.
- GitHub Actions validation workflow (`.github/workflows/ci.yml`).
- Dependabot configuration for GitHub Actions updates (`.github/dependabot.yml`).

### Documentation
- Expanded `README.md` with project structure and development information, including references to agent instructions, CI, and Dependabot.

## [0.1.0]

### Added
- Omarchy/Quickshell overlay plugin for screen magnification (plugin ID: `jp.zoomarchy`, entry point: `Overlay.qml`).
- Standalone plugin repository structure with plugin files at the repository root (`manifest.json`, `Overlay.qml`).
- Screenshot-based activation flow using `grim` to capture the current screen to `/tmp/zoomarchy-screenshot.png`.
- Fullscreen overlay displaying the captured screenshot with a 200 × 200 px magnified lens that follows the cursor.
- Zoom behavior: initial zoom `2.0`, range `1.0`–`5.0`, left mouse click `+1.0`, right mouse click `-1.0`, mouse wheel `±0.5`, and zoom reset to `2.0` when reopened while already active.
- Radial spotlight/dimming effect centered on the cursor.
- Overlay close handling via `Escape`.
- Documentation for Omarchy plugin-manager installation (`omarchy plugin add https://github.com/vlaktaks/ZoomArchy.git --enable`), manual installation from repository root, usage, manual `Super+Z` binding example, and plugin rescan (`omarchy-shell shell rescanPlugins`).
- License and repository metadata (`LICENSE`, `.gitignore`, `.gitattributes`).
