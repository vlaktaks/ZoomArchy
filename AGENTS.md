# AGENTS.md — ZoomArchy

Project instructions for coding agents working in this repository. Base changes and claims on the **current repository state** and the **actual Omarchy plugin implementation**, not assumptions.

## A. Project identity

- **Project name:** ZoomArchy
- **Plugin ID:** `jp.zoomarchy` (canonical; do not introduce alternatives such as `zoomarchy` or `jp_zoomarchy`)
- **Purpose:** screen magnifier / spotlight overlay plugin for the Omarchy shell (Quickshell/QML), showing a magnified lens over a captured screenshot with a radial spotlight.
- **Repository layout:** the **repository root is the plugin root** (installable plugin files live at root).
- **Version / release administration (current files):** `manifest.json` declares `version: "0.1.3"`; README and CHANGELOG document `0.1.3` as the current prepared version. Existing git tags `v0.1.0` (`4d5c92f`), `v0.1.1` (`deb5f11`), and `v0.1.2` (`eb6aa70`) must not be moved/overwritten/deleted. Any release/version/tag decision or publication action beyond documented preparation requires explicit user approval (see Git and release policy).

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
- **Capture:** on open (when not already shown), validates `$XDG_RUNTIME_DIR` (absolute path, existing directory at the inspected path, owned by current UID, mode `0700`), creates a private unique temporary capture directory inside it (`mktemp -d "$XDG_RUNTIME_DIR/zoomarchy.XXXXXXXX"`), hardens directory permissions, and runs `grim` to save `capture.png` via `Process`; after capture it hardens and validates the screenshot (owner, regular file at the inspected path, restrictive permissions) before setting `screenshotPath` and `shown`. Type/permission checks must not follow symlinks. If validation/capture fails, no unsafe `/tmp` fallback is used and the overlay is not shown as a successful capture. The magnifier operates on this captured snapshot (not live-updating desktop contents).
- **Display/lens:** fullscreen `Image` of the screenshot plus a magnified lens `Item` (200×200, clipped) containing a scaled screenshot image positioned from cursor/zoom.
- **Spotlight:** `Canvas` with a radial gradient centered on the cursor, repainted on cursor/size/shown changes.
- **Zoom/interaction:** `MouseArea` (enabled when `shown && contentReady`) tracks cursor, handles left/right click and wheel to adjust `zoomLevel` (clamped). `Shortcut` Escape closes overlay. `open(payload)` resets zoom to 2.0 if already shown, otherwise triggers secure capture; `close()` clears shown/screenshot state, resets zoom, and attempts best-effort cleanup of its own tracked temporary capture files/directories (not guaranteed on crashes or forced termination).
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
- Canonical runtime/distributable plugin files are `manifest.json` and `Overlay.qml`. The historical Qt/C++ implementation archived under `archive/legacy-qt-app/` is non-distributable reference material and must not be reintroduced into plugin runtime, entrypoints, installation, packaging, or CI behavior.
- Do not move plugin code into a nested `.config/omarchy/plugins/` structure or create a second/alternative implementation or plugin ID.
- Do not add custom install scripts that duplicate or conflict with the Omarchy plugin-manager workflow unless explicitly required and verified.
- Local build artifacts and non-canonical historical/local files may exist outside the distributable plugin set; do not add them to plugin installation/distribution, and do not delete them automatically without explicit approval.

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

## G.1 Pull request, review, and CI governance

**Verified remote enforcement (repository rulesets, read back from GitHub; repository public):**
- **`main` is protected by active rulesets targeting `~DEFAULT_BRANCH`** (no bypass actors configured): deletion of `main` is blocked and force pushes/non-fast-forward updates are blocked (`ruleset "Protect main branch"`, active). Legacy branch protection is not configured; protection is enforced via repository rulesets.
- **Pull-request-only changes:** changes to `main` must go through pull requests.
- **Required CI:** status check `Validate plugin files` (workflow `CI`, job `validate`) is required, with `strict_required_status_checks_policy` enabled; merges are blocked while required checks are pending or failing and the PR branch must satisfy the up-to-date requirement as enforced by GitHub.
- **Required review conditions:** at least **1** approving review is required; stale approvals are dismissed on push; approval of the most recent reviewable push is required (`require_last_push_approval`); all review conversations must be resolved before merging. Allowed merge methods (per ruleset): merge, squash, rebase.
- **Copilot automatic code review (active ruleset "Copilot review for default branch"):** automatic Copilot review is enabled for PRs to the default branch, including draft PRs, with `review_on_push` enabled. This provides automatic/re-fresh review behavior as configured by GitHub; it must **not** be interpreted as a separately verified, natively enforced mandatory Copilot *formal-approving-review* merge gate unless GitHub explicitly reports/supports and enforces that condition. Copilot review effort/formal-approval-counting options not exposed via the verified ruleset state must not be assumed.
- **Additional advisory automated review (e.g. CodeRabbit):** repository configuration (such as `.coderabbit.yaml`) may prepare additional AI code review, but external GitHub App installation/authorization is required for it to run on PRs. Any such automated review is **advisory only** unless a specific check/approval requirement is separately configured, verified, and enforced; it must not replace independent security review, human approval, or existing required checks, and it must not weaken repository governance or rulesets.

**Enduring policy:**
- **All required CI checks must pass** before merging. Required checks must have stable, descriptive names and must not be bypassed or treated as optional.
- **Review feedback must be addressed** and resolved. Security-sensitive changes (including screenshot/storage, permissions/validation, process execution, cleanup/lifecycle, workflow/security automation, and CI configuration) require explicit security review.
- **Workflow and security protections must not be casually bypassed.** Do not add bypass actors or weaken rules without explicit justification and approval.
- **Repository configuration and workflow files must remain consistent.** Agents must independently verify actual remote configuration before claiming enforcement, clearly distinguish policy/documentation, local workflow implementation, remote settings, enforcement, and execution-tested status, and document any remaining limitations. Future agents must not weaken or silently bypass these protections.

## H. Required agent workflow

1. Inspect repository/worktree state (`git status`, diffs, relevant files).
2. Understand existing architecture and read relevant files fully.
3. Keep scope limited to the requested, verified change.
4. Validate and test what is actually possible; do not claim unrun tests.
5. Review the full diff/result (`git diff --check`, staged diff when applicable).
6. Report factually: what changed, what was proven/tested, what remains unverified.
7. Stop before commit/push/tag/release and wait for explicit approval.


## I. Security invariants (normative, enduring)

These rules apply to all future changes, issue fixes, and PRs that touch capture, storage, process execution, cleanup, lifecycle, or related documentation.

### Temporary storage
- Never use a fixed or predictable screenshot path in a shared temporary directory.
- Never use an unsafe `/tmp` fallback.
- Use only a validated, private `$XDG_RUNTIME_DIR` for capture storage.
- Create a unique, exclusive capture directory for every capture (e.g. `mktemp -d "$XDG_RUNTIME_DIR/zoomarchy.XXXXXXXX"`); never reuse an existing capture directory.
- Use restrictive directory and file permissions (runtime directory must be private to the owner; capture artifacts must not be accessible to group/other users).

### File and path validation
- Validate runtime directory and capture artifacts: absolute/expected path context, existence, type, owner, and permissions. Reject symlinks where a directory/regular file is required and reject FIFOs or other non-regular capture files.
- File type/ownership/permission checks must inspect the path itself and must not follow symlinks. For GNU `stat`, do not use `-L` (or combined options that include it, such as `-Lc`) for these checks; use the intended non-dereferencing form (e.g. `stat -c ... -- <path>`). Verify the literal behavior of security-relevant command-line options; do not rely on comments or previous reports.
- Distinguish non-dereferencing validation of the final path component from trust assumptions about intermediate path components. Final-component non-dereferencing checks do not prove every intermediate component is safe. When changing path construction, validation, creation, or cleanup, consider intermediate components; if they are not independently validated, document the remaining limitation accurately.
- When screenshot, temporary-storage, filesystem, or cleanup behavior changes, evaluate the change against known Omarchy Plugin Marketplace rejection patterns as concrete review criteria (not universal prohibitions), including predictable/shared temporary paths, unsafe `/tmp` fallbacks, pre-created paths and symlink attacks, FIFO/other special-file risks, weak/private permissions, missing ownership/type validation, unsafe or unscoped cleanup, and accidental screenshot/data exposure (relevant precedents: #14652, #14886, #14660, #14198, #14206).
- Accept and display a screenshot only after successful capture and successful validation.
- Never show a stale or previous screenshot after a failed capture.
- Do not make absolute security claims when external tools/process boundaries cannot eliminate TOCTOU windows or guarantee safety of unvalidated path components; document mitigated residual risks honestly.

### Process execution
- Use Quickshell `Process` with argv arrays; do not use unsafe `sh -c` command composition.
- Do not build shell commands via uncontrolled string concatenation.
- Check exit codes and process results; preserve failure handling and capture-token/callback protection against stale operations.

### Cleanup and lifecycle
- Remove only ZoomArchy-owned, explicitly tracked capture files/directories; never use broad cleanup, globbing, recursive uncontrolled deletion, or generic fixed paths.
- Preserve ownership/path information needed for safe cleanup until it is no longer required. Closing or resetting UI/capture state must not invalidate the ownership information or tracked paths needed for pending/best-effort cleanup; when necessary, pass explicit original file paths, directory paths, and ownership bases into cleanup operations. Cleanup must not depend on mutable UI state that has already been reset.
- Old cleanup callbacks/operations must never remove or overwrite state for a newer capture.
- Attempt cleanup on close, capture failure, and capture replacement where the lifecycle permits; document that cleanup cannot be guaranteed on crashes or forced termination.

### Required practice for future issues/PRs
Before and after any relevant change, agents/contributors must:
1. Read these security invariants in `AGENTS.md`.
2. Verify the proposed change complies with them and does not remove, weaken, or bypass protections without explicit technical justification and review.
3. Check that new/modified code does not introduce security regressions (paths, permissions, validation, process execution, cleanup, stale callbacks/tokens).
4. Update `AGENTS.md` when enduring rules or architecture change.
5. Update `CHANGELOG.md` for relevant behavior/security changes (use `[Unreleased]` unless an explicit release/version decision is approved).
6. Update `README.md` when user-facing behavior/documentation changes.

This document must reflect the current, working plugin implementation and project conventions.
