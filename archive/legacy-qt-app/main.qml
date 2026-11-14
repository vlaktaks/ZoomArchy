import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    id: rootWindow
    visible: true
    width: 800
    height: 600
    title: "ZoomArchy - Inzoom op tekst"
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.Tool
    
    // Zoom state properties - bound to app.zoomActive
    property bool zoomMode: app ? app.zoomActive : false
    
    // Listen to app zoomActive changes
    Connections {
        target: app
        onZoomActiveChanged: {
            zoomMode = active
        }
    }
    
    // Overlay met dimming en zaklamp effect
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: zoomMode ? 0.7 : 0.0
        clip: true
        
        // Zaklamp radial glow effect using transparent overlay
        Item {
            anchors.fill: parent
            visible: zoomMode
            
            Rectangle {
                anchors.fill: parent
                color: "#38a169"
                opacity: 0.25
            }
        }
    }
    
    Text {
        anchors.centerIn: parent
        text: zoomMode ? 
            "Zaklamp Mode - Sleep om tekst te selecteren" :
            "ZoomArchy App\nDruk Super+Z voor zoom mode"
        
        font.pixelSize: 24
        color: "#cccccc"
        wrapMode: Text.WordWrap
    }
}