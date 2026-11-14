import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons as Commons

// Centered fullscreen surface on opening. Keep its first frames
// transparent until Qt receives the output's scale, so it opens sharp without
// retaining a parked surface that can be closed when a monitor disconnects.
PanelWindow {
  id: window

  // Whether the overlay is showing. Drive this instead of visible.
  property bool shown: false
  property int shownLayer: WlrLayer.Overlay
  property int shownKeyboardFocus: WlrKeyboardFocus.Exclusive

  property var targetScreen: null
  readonly property var targetMonitor: {
    var monitors = Hyprland.monitors.values
    for (var i = 0; i < monitors.length; i++) {
      if (targetScreen && monitors[i].name === targetScreen.name) return monitors[i]
    }
    return null
  }

  // Wait for fullscreen geometry as well as scale so no smaller opening frame
  // is stretched across the output. Fractional scale uses units of 1/120;
  // compare in those units to tolerate floating point rounding.
  readonly property bool contentReady: shown && backingWindowVisible && !!targetScreen
    && width === targetScreen.width && height === targetScreen.height
    && !!targetMonitor && Math.round(devicePixelRatio * 120) === Math.round(targetMonitor.scale * 120)
  property bool contentRevealed: false

  onContentReadyChanged: {
    contentRevealed = false
    if (window.shown) Qt.callLater(function() {
      if (window.contentReady) window.contentRevealed = true
    })
  }

  function focusedScreen() {
    var monitor = Hyprland.focusedMonitor
    var name = monitor ? String(monitor.name || "") : ""
    for (var i = 0; i < Quickshell.screens.length; i++) {
      if (Quickshell.screens[i].name === name) return Quickshell.screens[i]
    }
    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
  }

  onShownChanged: {
    targetScreen = shown ? focusedScreen() : null
    if (shown) Hyprland.refreshMonitors()
  }
  onDevicePixelRatioChanged: if (shown) Hyprland.refreshMonitors()

  Connections {
    target: Quickshell
    function onScreensChanged() {
      if (window.shown && Quickshell.screens.indexOf(window.targetScreen) < 0) {
        window.targetScreen = null
        Qt.callLater(function() {
          if (window.shown && !window.targetScreen) window.targetScreen = window.focusedScreen()
        })
      }
    }
  }

  visible: shown && !!targetScreen && !!targetMonitor
  screen: targetScreen
  anchors { top: true; left: true; bottom: true; right: true }
  color: "#00000000"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: shownLayer
  WlrLayershell.keyboardFocus: shownKeyboardFocus
  WlrLayershell.namespace: "zoomarchy"

  Binding {
    target: window.contentItem
    property: "opacity"
    value: window.contentRevealed ? 1 : 0
  }

  Binding {
    target: window.contentItem
    property: "LayoutMirroring.enabled"
    value: Commons.I18n.rightToLeft
  }
  Binding {
    target: window.contentItem
    property: "LayoutMirroring.childrenInherit"
    value: true
  }

  // Zoom and spotlight properties
  property real zoomLevel: 2.0
  property real maxZoom: 5.0
  property real minZoom: 1.0
  property point cursorPos: Qt.point(0, 0)
  property string screenshotPath: ""

  // Secure capture lifecycle state (private, per-capture directory in $XDG_RUNTIME_DIR)
  property int captureToken: 0
  property int activeCaptureToken: 0
  property string capturePhase: "idle" // idle, validating_runtime, validating_owner, creating_dir, capturing, cleaning
  property string runtimeDir: ""
  property string captureDir: ""
  property string currentUid: ""
  property string currentCaptureDir: ""
  property string currentCaptureFile: ""
  property bool captureIntent: false

  function isOwnedCapturePath(path, baseDir) {
    var base = baseDir !== undefined && baseDir !== null ? baseDir : window.captureDir
    return path !== "" && base !== "" && path.indexOf(base + "/") === 0
  }

  function clearCaptureRefs() {
    window.currentCaptureFile = ""
    window.currentCaptureDir = ""
  }

  function resetCaptureState() {
    window.capturePhase = "idle"
    window.runtimeDir = ""
    window.captureDir = ""
    window.currentUid = ""
    window.captureIntent = false
  }

  function runtimePermissionsArePrivate(mode) {
    // XDG_RUNTIME_DIR must be accessible only by its owner (expected mode 0700).
    if (!mode || mode.length < 3) return false
    var m = mode.length > 3 ? mode.slice(-3) : mode
    var owner = parseInt(m[0], 8)
    var group = parseInt(m[1], 8)
    var other = parseInt(m[2], 8)
    if (isNaN(owner) || isNaN(group) || isNaN(other)) return false
    return owner === 7 && group === 0 && other === 0
  }

  function cleanupCapture(token, path, dir, baseDir, afterCleanup) {
    var filePath = path || ""
    var dirPath = dir || ""
    var doAfter = afterCleanup || function() {}
    var ownershipBase = baseDir || ""

    if (filePath === "" && dirPath === "") {
      if (token === window.activeCaptureToken) window.clearCaptureRefs()
      doAfter()
      return
    }

    // Only remove paths owned/tracked by this capture instance.
    if (filePath !== "" && !window.isOwnedCapturePath(filePath, ownershipBase)) filePath = ""
    if (dirPath !== "" && !window.isOwnedCapturePath(dirPath, ownershipBase)) dirPath = ""
    if (filePath === "" && dirPath === "") {
      if (token === window.activeCaptureToken) window.clearCaptureRefs()
      doAfter()
      return
    }

    window.capturePhase = "cleaning"
    cleanupFileProc.token = token
    cleanupFileProc.filePath = filePath
    cleanupFileProc.dirPath = dirPath
    cleanupFileProc.afterCleanup = doAfter
    cleanupFileProc.command = filePath !== "" ? ["rm", "-f", "--", filePath] : ["rm", "-f", "--"]
    cleanupFileProc.running = true
  }

  function failCapture(token) {
    if (token !== window.activeCaptureToken) return
    var oldFile = window.currentCaptureFile
    var oldDir = window.currentCaptureDir
    var oldBase = window.captureDir
    window.captureIntent = false
    window.shown = false
    window.screenshotPath = ""
    cleanupCapture(token, oldFile, oldDir, oldBase, function() {
      if (token === window.activeCaptureToken) {
        window.clearCaptureRefs()
        window.resetCaptureState()
      }
    })
  }

  function startSecureCapture() {
    var oldFile = window.currentCaptureFile
    var oldDir = window.currentCaptureDir
    var oldBase = window.captureDir
    window.captureToken += 1
    window.activeCaptureToken = window.captureToken
    var token = window.activeCaptureToken

    window.captureIntent = true
    window.shown = false
    window.screenshotPath = ""

    cleanupCapture(token, oldFile, oldDir, oldBase, function() {
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      window.clearCaptureRefs()

      var envDir = Quickshell.env("XDG_RUNTIME_DIR")
      if (!envDir || envDir === "" || envDir.charAt(0) !== "/") {
        window.failCapture(token)
        return
      }
      window.runtimeDir = envDir
      window.capturePhase = "validating_owner"
      uidProc.token = token
      uidProc.command = ["id", "-u"]
      uidProc.running = true
    })
  }

  Process {
    id: uidProc
    property int token: 0
    property string uidOut: ""
    stdout: StdioCollector {
      onStreamFinished: uidProc.uidOut = (text || "").trim()
    }
    onExited: function(exitCode, exitStatus) {
      var token = uidProc.token
      var uid = uidProc.uidOut
      uidProc.uidOut = ""
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || uid === "") {
        window.failCapture(token)
        return
      }
      window.currentUid = uid
      window.capturePhase = "validating_runtime"
      runtimeStatProc.token = token
      runtimeStatProc.statOut = ""
      runtimeStatProc.command = ["stat", "-c", "%u %a %F", "--", window.runtimeDir]
      runtimeStatProc.running = true
    }
  }

  Process {
    id: runtimeStatProc
    property int token: 0
    property string statOut: ""
    stdout: StdioCollector {
      onStreamFinished: runtimeStatProc.statOut = (text || "").trim()
    }
    onExited: function(exitCode, exitStatus) {
      var token = runtimeStatProc.token
      var out = runtimeStatProc.statOut
      runtimeStatProc.statOut = ""
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || out === "") {
        window.failCapture(token)
        return
      }

      var parts = out.split(/\s+/)
      if (parts.length < 3) {
        window.failCapture(token)
        return
      }
      var owner = parts[0]
      var mode = parts[1]
      var type = parts.slice(2).join(" ")
      if (owner !== window.currentUid || type !== "directory" || !window.runtimePermissionsArePrivate(mode)) {
        window.failCapture(token)
        return
      }

      window.captureDir = window.runtimeDir
      window.capturePhase = "creating_dir"
      mktempProc.token = token
      mktempProc.dirOut = ""
      // Create a private, unique capture directory inside the validated runtime directory.
      mktempProc.command = ["mktemp", "-d", window.runtimeDir + "/zoomarchy.XXXXXXXX"]
      mktempProc.running = true
    }
  }

  Process {
    id: mktempProc
    property int token: 0
    property string dirOut: ""
    stdout: StdioCollector {
      onStreamFinished: mktempProc.dirOut = (text || "").trim()
    }
    onExited: function(exitCode, exitStatus) {
      var token = mktempProc.token
      var dir = mktempProc.dirOut
      mktempProc.dirOut = ""
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || dir === "" || dir.indexOf(window.runtimeDir + "/zoomarchy.") !== 0) {
        window.failCapture(token)
        return
      }

      window.currentCaptureDir = dir
      window.currentCaptureFile = dir + "/capture.png"
      window.capturePhase = "securing_dir"
      chmodDirProc.token = token
      chmodDirProc.command = ["chmod", "700", "--", dir]
      chmodDirProc.running = true
    }
  }

  Process {
    id: chmodDirProc
    property int token: 0
    running: false
    onExited: function(exitCode, exitStatus) {
      var token = chmodDirProc.token
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || window.currentCaptureFile === "") {
        window.failCapture(token)
        return
      }

      window.capturePhase = "capturing"
      screencapture.token = token
      screencapture.command = ["grim", window.currentCaptureFile]
      screencapture.running = true
    }
  }

  // Process to capture screenshot with grim into the private capture directory
  Process {
    id: screencapture
    property int token: 0
    running: false
    onExited: function(exitCode, exitStatus) {
      var token = screencapture.token
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || window.currentCaptureFile === "") {
        window.failCapture(token)
        return
      }

      // Best-effort hardening: grim creates the file first; chmod/stat run after
      // capture in the private 0700 runtime directory to enforce/verify 0600.
      window.capturePhase = "securing_file"
      chmodFileProc.token = token
      chmodFileProc.command = ["chmod", "600", "--", window.currentCaptureFile]
      chmodFileProc.running = true
    }
  }

  Process {
    id: chmodFileProc
    property int token: 0
    running: false
    onExited: function(exitCode, exitStatus) {
      var token = chmodFileProc.token
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || window.currentCaptureFile === "") {
        window.failCapture(token)
        return
      }

      window.capturePhase = "validating_capture"
      captureStatProc.token = token
      captureStatProc.statOut = ""
      captureStatProc.command = ["stat", "-c", "%u %a %F", "--", window.currentCaptureFile]
      captureStatProc.running = true
    }
  }

  Process {
    id: captureStatProc
    property int token: 0
    property string statOut: ""
    stdout: StdioCollector {
      onStreamFinished: captureStatProc.statOut = (text || "").trim()
    }
    onExited: function(exitCode, exitStatus) {
      var token = captureStatProc.token
      var out = captureStatProc.statOut
      captureStatProc.statOut = ""
      if (token !== window.activeCaptureToken || !window.captureIntent) return
      if (exitCode !== 0 || out === "") {
        window.failCapture(token)
        return
      }

      var parts = out.split(/\s+/)
      if (parts.length < 3) {
        window.failCapture(token)
        return
      }
      var owner = parts[0]
      var mode = parts[1]
      var type = parts.slice(2).join(" ")
      var m = mode.length > 3 ? mode.slice(-3) : mode
      var group = m.length >= 2 ? parseInt(m[1], 8) : NaN
      var other = m.length >= 3 ? parseInt(m[2], 8) : NaN
      var filePrivate = !isNaN(group) && !isNaN(other) && group === 0 && other === 0
      if (owner !== window.currentUid || type !== "regular file" || !filePrivate) {
        window.failCapture(token)
        return
      }

      window.screenshotPath = window.currentCaptureFile
      window.captureIntent = false
      window.capturePhase = "idle"
      window.shown = true
    }
  }

  Process {
    id: cleanupFileProc
    property int token: 0
    property string filePath: ""
    property string dirPath: ""
    property var afterCleanup: null
    running: false
    onExited: function(exitCode, exitStatus) {
      var token = cleanupFileProc.token
      var dirPath = cleanupFileProc.dirPath
      var cb = cleanupFileProc.afterCleanup
      cleanupFileProc.afterCleanup = null
      cleanupFileProc.filePath = ""

      if (dirPath !== "") {
        cleanupDirProc.token = token
        cleanupDirProc.dirPath = dirPath
        cleanupDirProc.afterCleanup = cb
        cleanupDirProc.command = ["rmdir", "--", dirPath]
        cleanupDirProc.running = true
      } else {
        cleanupDirProc.dirPath = ""
        if (token === window.activeCaptureToken) window.clearCaptureRefs()
        if (cb) cb()
      }
    }
  }

  Process {
    id: cleanupDirProc
    property int token: 0
    property string dirPath: ""
    property var afterCleanup: null
    running: false
    onExited: function(exitCode, exitStatus) {
      var token = cleanupDirProc.token
      var cb = cleanupDirProc.afterCleanup
      cleanupDirProc.afterCleanup = null
      cleanupDirProc.dirPath = ""
      if (token === window.activeCaptureToken) window.clearCaptureRefs()
      if (cb) cb()
    }
  }

  // Load the screenshot into an Image
  Image {
    id: screenshotImage
    source: window.screenshotPath
    anchors.fill: parent
    fillMode: Image.Stretch
    visible: window.shown && window.contentReady
    cache: false
  }

  // Magnified view using clipped Item + scaled Image
  Item {
    id: magnifyItem
    width: 200
    height: 200
    x: window.cursorPos.x - 100
    y: window.cursorPos.y - 100
    visible: window.shown && window.contentReady
    clip: true

    Image {
      source: window.screenshotPath
      width: window.width * window.zoomLevel
      height: window.height * window.zoomLevel
      x: -(window.cursorPos.x * window.zoomLevel) + 100
      y: -(window.cursorPos.y * window.zoomLevel) + 100
      cache: false
    }
  }

  // Spotlight overlay using Canvas with radial gradient
  Canvas {
    id: spotlightCanvas
    anchors.fill: parent
    visible: window.shown && window.contentReady

    onPaint: {
      var ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      var gradient = ctx.createRadialGradient(
        window.cursorPos.x, window.cursorPos.y, 0,
        window.cursorPos.x, window.cursorPos.y, 150
      );
      gradient.addColorStop(0.0, "rgba(0, 0, 0, 0)");
      gradient.addColorStop(0.8, "rgba(0, 0, 0, 0.7)");
      gradient.addColorStop(1.0, "rgba(0, 0, 0, 0.8)");
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);
    }

    Connections {
      target: window
      function onCursorPosChanged() { spotlightCanvas.requestPaint(); }
      function onWidthChanged() { spotlightCanvas.requestPaint(); }
      function onHeightChanged() { spotlightCanvas.requestPaint(); }
      function onShownChanged() { if (window.shown) spotlightCanvas.requestPaint(); }
    }
  }

  // Mouse tracking and interaction
  MouseArea {
    id: interactionArea
    anchors.fill: parent
    z: 100
    enabled: window.shown && window.contentReady
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    preventStealing: true

    function applyZoomDelta(delta) {
      var next = Math.max(window.minZoom, Math.min(window.maxZoom, window.zoomLevel + delta))
      window.zoomLevel = next
    }

    onPositionChanged: (mouse) => {
      window.cursorPos = Qt.point(mouse.x, mouse.y)
    }

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        applyZoomDelta(1.0)
      } else if (mouse.button === Qt.RightButton) {
        applyZoomDelta(-1.0)
      }
    }

    onWheel: (wheel) => {
      if (wheel.angleDelta.y > 0) {
        applyZoomDelta(0.5)
      } else if (wheel.angleDelta.y < 0) {
        applyZoomDelta(-0.5)
      }
    }
  }

  // Zoom level indicator for interaction feedback
  Rectangle {
    id: zoomIndicator
    z: 200
    visible: window.shown && window.contentReady
    radius: 6
    color: "#CC000000"
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 20
    width: zoomText.implicitWidth + 24
    height: zoomText.implicitHeight + 12

    Text {
      id: zoomText
      anchors.centerIn: parent
      text: "ZOOM " + window.zoomLevel.toFixed(1) + "x"
      color: "white"
      font.pixelSize: 18
      font.bold: true
    }
  }
  // Keyboard handling via Shortcut
  Shortcut {
    sequence: Qt.Key_Escape
    enabled: window.shown
    onActivated: {
      window.close()
    }
  }

  function open(payload) {
    if (window.shown) {
      // Already shown, just reset zoom
      window.zoomLevel = 2.0
    } else {
      // Capture screen before showing
      window.startSecureCapture()
    }
  }

  function close() {
    window.captureIntent = false
    window.captureToken += 1
    window.activeCaptureToken = window.captureToken
    var token = window.activeCaptureToken
    var oldFile = window.currentCaptureFile
    var oldDir = window.currentCaptureDir
    var oldBase = window.captureDir

    window.shown = false
    window.screenshotPath = ""
    window.zoomLevel = 2.0
    // Reset capture state (including refs/base) before async cleanup; pass explicit
    // ownership base and tracked paths so cleanup remains correct and isolated.
    window.resetCaptureState()

    cleanupCapture(token, oldFile, oldDir, oldBase, function() {
      // Cleanup completed best-effort; closing must not be blocked.
    })
  }
}
