# Changelog

All notable changes to this project are documented in this file.

## [0.1.0] - Unreleased

### Added
- Initial Omarchy/Quickshell overlay plugin for screen magnification (`jp.zoomarchy`, `Overlay.qml`).
- Screenshot-based activation flow using `grim` to capture the current screen into `/tmp/zoomarchy-screenshot.png`.
- Fullscreen overlay displaying the captured screenshot with a 200×200 magnified lens that follows the cursor.
- Zoom controls: initial zoom `2.0`, range `1.0`–`5.0`, left click `+1.0`, mouse wheel `±0.5`, and zoom reset to `2.0` when reopened while already shown.
- Radial spotlight/dimming effect centered on the cursor.
- Overlay close handling via `Escape`.
- Root install/uninstall helper scripts and plugin helper scripts for local Omarchy plugin setup.
