# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Security
- Replaced fixed `/tmp/zoomarchy-screenshot.png` screenshot storage with per-capture private temporary directories under `$XDG_RUNTIME_DIR`.
- Added runtime-directory validation, unique directory creation, stricter screenshot file handling, and best-effort cleanup of ZoomArchy-owned temporary capture files.
- Tightened runtime-directory validation (M-2): require a safely usable, user-owned directory with restrictive `0700` permissions before capture proceeds.
- Removed use of an unsafe shared `/tmp` capture path; if `$XDG_RUNTIME_DIR` is missing or not safely usable, capture does not proceed.
- Corrected GNU `stat` validation to use non-dereferencing `-c` (instead of `-Lc`) so runtime-directory and capture-file checks inspect the path itself rather than following symlinks.
- Corrected close/capture cleanup ordering (H-1): cleanup receives original tracked paths and ownership base as needed so resetting UI/capture state does not invalidate cleanup ownership checks; cleanup remains best-effort.
- Documented remaining mitigated limitations: post-capture permission hardening occurs after file creation inside a private runtime directory, cleanup cannot be guaranteed on crashes or forced termination, and symlink/TOCTOU risks in unvalidated path components cannot be fully eliminated by the current external-process architecture.

### CI / Governance
- Hardened the GitHub Actions CI workflow (`.github/workflows/ci.yml`) with minimal token permissions, concurrency control, explicit job timeout, non-persisted checkout credentials, and expanded static checks for canonical plugin files, manifest/entrypoint consistency, and installation/distribution guidance (no application execution or repository mutation).
- Configured and verified repository-level GitHub governance for the public repository: active rulesets protect `main` (`~DEFAULT_BRANCH`) with PR-only changes, blocked deletion/force-push (non-fast-forward), required status check `Validate plugin files` (workflow `CI`, job `validate`) with strict/up-to-date policy, required approving review count (1), dismissal of stale approvals on push, approval of the most recent reviewable push, and required review-conversation resolution.
- Enabled and verified Copilot automatic code review for default-branch PRs (including draft PRs and `review_on_push`), while documenting that automatic Copilot review is distinct from a separately verified, natively enforced mandatory Copilot formal-approval merge gate unless explicitly supported/configured.
- Updated `AGENTS.md` and `README.md` to distinguish intended policy, local workflow implementation, remote settings, and independently verified enforcement/limitations.

## [0.1.2]

### Changed
- Bumped the current plugin version to `0.1.2` in project metadata and documentation.

### Documentation
- Documented that a historical Qt Quick/qmake implementation is retained under `archive/legacy-qt-app/` for reference and is not part of the current Omarchy/Quickshell plugin distribution.

### Maintenance
- Preserved the historical Qt/C++ implementation as a clearly separated archive under `archive/legacy-qt-app/`.
- Adjusted `.gitignore` to keep generated/local artifacts ignored while allowing the archived historical source files to be tracked.
- Removed confirmed generated local build artifacts from the repository root (qmake/moc/rcc/object outputs); historical source inputs were preserved in the archive.

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
