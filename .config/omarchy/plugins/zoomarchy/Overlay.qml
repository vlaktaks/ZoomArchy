import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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

  // Process to capture screenshot with grim
  Process {
    id: screencapture
    command: ["grim", "/tmp/zoomarchy-screenshot.png"]
    running: false
    onStarted: {
      console.log("ZoomArchy: screencapture started")
    }
    onExited: function(exitCode, exitStatus) {
      console.log("ZoomArchy: screencapture exited, code:", exitCode, "status:", exitStatus)
      if (exitCode === 0) {
        window.screenshotPath = "/tmp/zoomarchy-screenshot.png"
        window.shown = true
        console.log("ZoomArchy: screenshot set, shown=true")
      }
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

  // Mouse tracking
  MouseArea {
    anchors.fill: parent
    enabled: window.shown && window.contentReady
    hoverEnabled: true

    onPositionChanged: (mouse) => {
      window.cursorPos = Qt.point(mouse.x, mouse.y)
    }

    onClicked: (mouse) => {
      // Increase zoom on left click
      if (window.zoomLevel < window.maxZoom) {
        window.zoomLevel += 1.0
      }
    }
  }

  // Wheel zoom
  MouseArea {
    anchors.fill: parent
    enabled: window.shown && window.contentReady
    onWheel: {
      var delta = wheel.angleDelta.y / 120
      window.zoomLevel = Math.max(window.minZoom, Math.min(window.maxZoom, window.zoomLevel + delta * 0.5))
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
    console.log("ZoomArchy open called, shown:", window.shown, "payload:", payload)
    if (window.shown) {
      // Already shown, just reset zoom
      window.zoomLevel = 2.0
    } else {
      // Capture screen before showing
      window.shown = false
      screencapture.running = true
    }
  }

  function close() {
    window.shown = false
    window.screenshotPath = ""
    window.zoomLevel = 2.0
  }
}
