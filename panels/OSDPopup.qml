/*
 * ============================================================================
 *                           OSD POPUP
 * ============================================================================
 * 
 * FILE: panels/OSDPopup.qml
 * PURPOSE: On-Screen Display for volume and brightness changes
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PanelWindow {
    id: osdWindow
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    
    property bool osdVisible: false
    property bool isClosing: false  // Track closing state for exit animation
    property string osdType: "volume"  // "volume", "brightness"
    property int osdValue: 0           // 0-100 percentage
    property bool osdMuted: false
    
    // Track previous values to detect changes
    property int lastVolume: -1
    property bool lastMuted: false
    property int lastBrightness: -1
    property bool initialized: false
    property bool brightInitialized: false
    
    // Handle delayed hide for exit animation
    onOsdVisibleChanged: {
        if (!osdVisible) {
            isClosing = true
            closeAnimTimer.start()
        }
    }
    
    Timer {
        id: closeAnimTimer
        interval: Config.animSpring
        onTriggered: osdWindow.isClosing = false
    }
    
    // ========================================================================
    //                     WINDOW PROPERTIES
    // ========================================================================
    
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    
    // Position at bottom center
    anchors {
        bottom: true
        left: false
        right: false
        top: false
    }
    
    margins {
        bottom: 100
    }
    
    implicitWidth: 280
    implicitHeight: 80
    
    // Overlay layer so it appears above everything
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    
    // Don't reserve space - let windows stay in place
    exclusionMode: ExclusionMode.Ignore
    
    // Stay visible during close animation
    visible: osdVisible || isClosing
    color: "transparent"
    
    // ========================================================================
    //                     CHANGE LISTENERS
    // ========================================================================
    
    // Poll for external changes (media keys, other apps)
    Timer {
        id: pollTimer
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            pollVolumeProc.running = true
            pollBrightnessProc.running = true
        }
    }
    
    // Poll volume
    Process {
        id: pollVolumeProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = this.text.trim()
                var isMuted = text.includes("[MUTED]")
                var match = text.match(/Volume:\s*([\d.]+)/)
                if (match) {
                    var vol = Math.round(parseFloat(match[1]) * 100)
                    
                    if (!osdWindow.initialized) {
                        osdWindow.lastVolume = vol
                        osdWindow.lastMuted = isMuted
                        osdWindow.initialized = true
                        return
                    }
                    
                    var volumeChanged = vol !== osdWindow.lastVolume
                    var muteChanged = isMuted !== osdWindow.lastMuted
                    
                    if (volumeChanged || muteChanged) {
                        osdWindow.osdType = "volume"
                        osdWindow.osdValue = vol
                        osdWindow.osdMuted = isMuted
                        osdWindow.lastVolume = vol
                        osdWindow.lastMuted = isMuted
                        osdWindow.showOSD()
                    }
                }
            }
        }
    }
    
    // Poll brightness
    Process {
        id: pollBrightnessProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var brightness = parseInt(this.text.trim())
                if (isNaN(brightness)) return
                
                if (!osdWindow.brightInitialized) {
                    osdWindow.lastBrightness = brightness
                    osdWindow.brightInitialized = true
                    return
                }
                
                if (brightness !== osdWindow.lastBrightness) {
                    osdWindow.osdType = "brightness"
                    osdWindow.osdValue = brightness
                    osdWindow.osdMuted = false
                    osdWindow.lastBrightness = brightness
                    osdWindow.showOSD()
                }
            }
        }
    }
    
    // ========================================================================
    //              SHOW FUNCTION & TIMER (M3 Expressive)
    // ========================================================================
    
    function showOSD() {
        osdVisible = true
        hideTimer.restart()
    }
    
    Timer {
        id: hideTimer
        interval: 1800  // Slightly longer for M3 Expressive
        onTriggered: osdWindow.osdVisible = false
    }
    
    // ========================================================================
    //              VISUAL CONTENT (M3 Expressive)
    // ========================================================================
    
    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 320
        height: 100
        radius: Config.panelRadius
        color: Config.backgroundColor
        border.width: 1
        border.color: Config.borderColor
        
        // M3 Expressive: spring entry animation
        opacity: osdWindow.osdVisible ? 1 : 0
        scale: osdWindow.osdVisible ? 1 : 0.85
        
        Behavior on opacity { 
            NumberAnimation { 
                duration: Config.animNormal
                easing.type: Easing.OutCubic 
            } 
        }
        Behavior on scale { 
            NumberAnimation { 
                duration: Config.animSpring
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            } 
        }
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.5)
            shadowBlur: 1.0
            shadowVerticalOffset: 8
            shadowHorizontalOffset: 0
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: Config.padding
            spacing: Config.spacingLarge
            
            // Expressive colored icon container
            Rectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 18
                
                // Gradient background matching type
                gradient: Gradient {
                    GradientStop { 
                        position: 0.0
                        color: osdWindow.osdType === "brightness" ? 
                               Qt.rgba(1.0, 0.8, 0.2, 0.25) :
                               Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.25)
                    }
                    GradientStop { 
                        position: 1.0
                        color: osdWindow.osdType === "brightness" ? 
                               Qt.rgba(1.0, 0.6, 0.1, 0.15) :
                               Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1)
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (osdWindow.osdMuted) return "volume_off"
                        if (osdWindow.osdType === "brightness") return "brightness_6"
                        if (osdWindow.osdValue > 66) return "volume_up"
                        if (osdWindow.osdValue > 33) return "volume_down"
                        if (osdWindow.osdValue > 0) return "volume_mute"
                        return "volume_off"
                    }
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 28
                    color: osdWindow.osdType === "brightness" ? "#FFB800" : Config.accentColor
                    
                    // Subtle bounce on change
                    scale: 1.0
                    
                    Behavior on text {
                        SequentialAnimation {
                            NumberAnimation { target: parent; property: "scale"; to: 0.85; duration: 80 }
                            NumberAnimation { target: parent; property: "scale"; to: 1.05; duration: 150; easing.type: Easing.OutBack }
                            NumberAnimation { target: parent; property: "scale"; to: 1.0; duration: 100 }
                        }
                    }
                }
            }
            
            // Progress bar and value
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                
                // Label and percentage row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: osdWindow.osdType === "brightness" ? "Brightness" : (osdWindow.osdMuted ? "Muted" : "Volume")
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeTitle
                        font.weight: Font.DemiBold
                        color: Config.foregroundColor
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Percentage in expressive pill
                    Rectangle {
                        width: pctText.width + 16
                        height: 28
                        radius: 14
                        color: osdWindow.osdType === "brightness" ? 
                               Qt.rgba(1.0, 0.8, 0.2, 0.15) :
                               Config.accentColorSurface
                        
                        Text {
                            id: pctText
                            anchors.centerIn: parent
                            text: osdWindow.osdMuted ? "0%" : osdWindow.osdValue + "%"
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeLabel
                            font.weight: Font.Bold
                            color: osdWindow.osdType === "brightness" ? "#FFB800" : Config.accentColor
                        }
                    }
                }
                
                // Progress bar - M3 Expressive rounded pill
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    radius: 5
                    color: Config.surfaceColor
                    
                    // Progress fill with gradient
                    Rectangle {
                        width: parent.width * (osdWindow.osdMuted ? 0 : Math.min(osdWindow.osdValue, 100) / 100)
                        height: parent.height
                        radius: 5
                        
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { 
                                position: 0.0
                                color: osdWindow.osdMuted ? Config.dimmedColor :
                                       (osdWindow.osdType === "brightness" ? "#FFA500" : Config.accentColor)
                            }
                            GradientStop { 
                                position: 1.0
                                color: osdWindow.osdMuted ? Config.dimmedColor :
                                       (osdWindow.osdType === "brightness" ? "#FFD700" : Qt.lighter(Config.accentColor, 1.2))
                            }
                        }
                        
                        Behavior on width { 
                            NumberAnimation { 
                                duration: 150
                                easing.type: Easing.OutQuart
                            } 
                        }
                    }
                }
            }
        }
    }
}