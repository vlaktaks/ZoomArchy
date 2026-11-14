# AGENTS.md — ZoomArchy

Project instructions for coding agents working in this repository. Base changes and claims on the **current repository state** and the **actual Omarchy plugin implementation**, not assumptions.

## A. Project identity

- **Project name:** ZoomArchy
- **Plugin ID:** `jp.zoomarchy` (canonical; do not introduce alternatives such as `zoomarchy` or `jp_zoomarchy`)
- **Purpose:** screen magnifier / spotlight overlay plugin for the Omarchy shell (Quickshell/QML), showing a magnified lens over a captured screenshot with a radial spotlight.
- **Repository layout:** the **repository root is the plugin root** (installable plugin files live at root).
- **Version / release administration (current files):** `manifest.json` declares `version: "0.1.1"`; README and CHANGELOG document `0.1.1`. Existing git tag `v0.1.0` points to commit `4d5c92f12db9eab55f6498b113a8af6628104bed` (not the current `main` HEAD) — **do not move/overwrite/delete existing tags**. Any release/version/tag decision beyond this requires explicit user approval (see Git and release policy).

## B. Architecture (factual, current implementation)

**Primary files:**
- `manifest.json` — plugin manifest.
- `Overlay.qml` — overlay entrypoint and implementation.

**Manifest (`manifest.json`):**
- `schemaVersion: 1`
- `id: "jp.zoomarchy"`
- `kinds: ["overlay"]`
- `keepLoaded: true`
- `entryPoints.overlay: "Overlay.qml"`

**`Overlay.qml` (root `PanelWindow`):**
- **Imports:** `QtQuick`, `Quickshell`, `Quickshell.Hyprland`, `Quickshell.Wayland`, `Quickshell.Io`, `qs.Commons as Commons`.
- **Role/behavior:** fullscreen Wayland layer-shell overlay (`WlrLayershell.layer` overlay, `WlrKeyboardFocus.Exclusive`, `namespace: "zoomarchy"`, `exclusionMode: ExclusionMode.Ignore`, transparent color), shown on the focused/target screen when activated.
- **State/readiness:** `shown` drives visibility; `targetScreen`/`targetMonitor` selected from focused Hyprland monitor; `contentReady` gates rendering/input until backing window, screen, geometry, and scale/DPR match (`Math.round(devicePixelRatio * 120) === Math.round(targetMonitor.scale * 120)`); `contentRevealed` fades content in after readiness.
- **Capture:** on open (when not already shown), runs `grim /tmp/zoomarchy-screenshot.png` via `Process`; on successful exit sets `screenshotPath` and `shown`. The magnifier operates on this captured snapshot (not live-updating desktop contents).
- **Display/lens:** fullscreen `Image` of the screenshot plus a magnified lens `Item` (200×200, clipped) containing a scaled screenshot image positioned from cursor/zoom.
- **Spotlight:** `Canvas` with a radial gradient centered on the cursor, repainted on cursor/size/shown changes.
- **Zoom/interaction:** `MouseArea` (enabled when `shown && contentReady`) tracks cursor, handles left/right click and wheel to adjust `zoomLevel` (clamped). `Shortcut` Escape closes overlay. `open(payload)` resets zoom to 2.0 if already shown, otherwise triggers capture; `close()` clears shown/screenshot state and resets zoom.
- **Zoom indicator:** on-screen `Rectangle`/`Text` shows current zoom level when `shown && contentReady` (UI feedback; not part of zoom calculation logic).

Describe and modify only behavior that is demonstrably present in the current code.

## C. Functional behavior (verify in code before documenting changes)

Current implementation values:
- **Left mouse click:** zoom in `+1.0`
- **Right mouse click:** zoom out `-1.0`
- **Mouse wheel up:** zoom in `+0.5`
- **Mouse wheel down:** zoom out `-0.5`
- **Initial zoom / reset:** `2.0` (including reopen while active)
- **Minimum zoom:** `1.0`
- **Maximum zoom:** `5.0`
- **Escape:** close overlay
- **Lens size:** `200 × 200` px

If code differs, document and preserve the actual implementation unless a fix is explicitly requested and verified.

## D. File structure and placement rules

**Canonical structure (plugin-relevant):**
```text
ZoomArchy/
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   └── dependabot.yml
├── AGENTS.md
├── manifest.json
├── Overlay.qml
├── README.md
├── CHANGELOG.md
├── LICENSE
├── .gitignore
└── .gitattributes
```

**Rules:**
- Repository root is the plugin root. `manifest.json` stays in the root; `Overlay.qml` stays next to it.
- Do not move plugin code into a nested `.config/omarchy/plugins/` structure or create a second/alternative implementation or plugin ID.
- Do not add custom install scripts that duplicate or conflict with the Omarchy plugin-manager workflow unless explicitly required and verified.
- Legacy Qt/C++ files and local build artifacts may exist locally; do not delete them automatically and do not add them to the release/distribution set.

## E. Installation and validation (tested/known Omarchy commands)

**Plugin-manager (canonical, from GitHub):**
```bash
omarchy plugin add https://github.com/vlaktaks/ZoomArchy.git --enable
```
(Without `--enable`: add, then `omarchy plugin enable jp.zoomarchy`.)

**Manual install from repository/plugin root** (copy only plugin files, not the whole tree):
```bash
mkdir -p ~/.config/omarchy/plugins/jp.zoomarchy
install -m644 manifest.json ~/.config/omarchy/plugins/jp.zoomarchy/
install -m644 Overlay.qml ~/.config/omarchy/plugins/jp.zoomarchy/
omarchy plugin validate ~/.config/omarchy/plugins/jp.zoomarchy
omarchy plugin enable jp.zoomarchy
omarchy-shell shell rescanPlugins
```
- Do **not** use `cp -r ./*` (can install unintended local/build/legacy files).
- Canonical install path: `~/.config/omarchy/plugins/jp.zoomarchy/`.

**Validation / runtime helpers:**
```bash
omarchy plugin validate .
omarchy plugin validate ~/.config/omarchy/plugins/jp.zoomarchy
omarchy plugin enable jp.zoomarchy
omarchy-shell shell rescanPlugins
omarchy-shell shell summon jp.zoomarchy '{}'
```
- `omarchy-shell shell rescanPlugins` reloads plugins in-process; if a changed/keep-loaded QML instance is not replaced, a full shell restart may be required (disruptive; report consequences and get user confirmation before suggesting/executing).

**Shortcuts:** the plugin does not configure Hyprland bindings. `Super+Z` is only a manual example (user-managed config, e.g. binding to panel `jp.zoomarchy` where appropriate for the setup).

## F. Development and test rules

- **Static checks:** validate manifest/plugin structure (`omarchy plugin validate .` locally where Omarchy is available). Check QML syntax with available, suitable tools if present; do not invent tool availability.
- **Runtime:** test in a real Omarchy shell/session. Distinguish **static validation** from **runtime/visual/interaction** tests.
- **Functional checks:** activation/summon, capture, overlay open/close, reopen/reset, left/right click zoom, scroll zoom, Escape, zoom indicator, spotlight and lens behavior, screen edges/corners, and scaling/DPI where relevant.
- **Reporting:** report physical/visual tests not actually performed as **not performed**. State what is proven by code inspection, by automated/runtime evidence, and by user-confirmed tests.

## G. Git and release policy

- No destructive Git commands: no `git reset`, `git checkout`/`git switch` that discards work, `git clean`, `git stash`, no force-push, no history rewrite.
- Never `git add .` or `git add -A`; stage explicitly approved files only.
- Before any commit: inspect `git status`, `git diff`, `git diff --cached`, `git diff --check`.
- No commit, push, tag, or GitHub Release without explicit user approval.
- Never move, overwrite, or delete existing tags (including `v0.1.0`). No force-push/history rewrite.
- Do not include legacy files, local config, secrets, or build artifacts in commits/releases unintentionally. Preserve existing user/unrelated worktree changes.

## H. Required agent workflow

1. Inspect repository/worktree state (`git status`, diffs, relevant files).
2. Understand existing architecture and read relevant files fully.
3. Keep scope limited to the requested, verified change.
4. Validate and test what is actually possible; do not claim unrun tests.
5. Review the full diff/result (`git diff --check`, staged diff when applicable).
6. Report factually: what changed, what was proven/tested, what remains unverified.
7. Stop before commit/push/tag/release and wait for explicit approval.

This document must reflect the current, working plugin implementation and project conventions.
