/*
 * ============================================================================
 *                           OSD POPUP
 * ============================================================================
 * 
 * FILE: Modules/popup/OSDPopup.qml
 * PURPOSE: Minimal On-Screen Display for volume and brightness changes
 * 
 * Design: Clean pill-shaped indicator with icon and progress bar
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../misc"
import "../../Handlers"

PanelWindow {
    id: osdWindow
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    
    property bool osdVisible: false
    property bool isClosing: false
    property string osdType: "volume"  // "volume" | "brightness"
    property int osdValue: 0           // 0-100
    property bool osdMuted: false
    
    // Track previous values to detect changes
    property int lastVolume: -1
    property bool lastMuted: false
    property int lastBrightness: -1
    property bool initialized: false
    property bool brightInitialized: false
    
    // ========================================================================
    //                     ANIMATION HANDLING
    // ========================================================================
    
    onOsdVisibleChanged: {
        if (!osdVisible) {
            isClosing = true
            closeAnimTimer.start()
        }
    }
    
    Timer {
        id: closeAnimTimer
        interval: 250
        onTriggered: osdWindow.isClosing = false
    }
    
    // ========================================================================
    //                     WINDOW PROPERTIES
    // ========================================================================
    
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    
    anchors {
        bottom: true
        left: false
        right: false
        top: false
    }
    
    margins.bottom: 80
    
    implicitWidth: 200
    implicitHeight: 56
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    exclusionMode: ExclusionMode.Ignore
    
    visible: osdVisible || isClosing
    color: "transparent"
    
    // ========================================================================
    //                     POLLING FOR CHANGES
    // ========================================================================
    
    Timer {
        id: pollTimer
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            pollVolumeProc.running = true
            pollBrightnessProc.running = true
        }
    }
    
    Process {
        id: pollVolumeProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim()
                let isMuted = text.includes("[MUTED]")
                let match = text.match(/Volume:\s*([\d.]+)/)
                
                if (match) {
                    let vol = Math.round(parseFloat(match[1]) * 100)
                    
                    if (!osdWindow.initialized) {
                        osdWindow.lastVolume = vol
                        osdWindow.lastMuted = isMuted
                        osdWindow.initialized = true
                        return
                    }
                    
                    if (vol !== osdWindow.lastVolume || isMuted !== osdWindow.lastMuted) {
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
    
    Process {
        id: pollBrightnessProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                let brightness = parseInt(data.trim())
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
    //                     SHOW/HIDE LOGIC
    // ========================================================================
    
    function showOSD() {
        osdVisible = true
        hideTimer.restart()
    }
    
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osdWindow.osdVisible = false
    }
    
    // ========================================================================
    //                     VISUAL DESIGN
    // ========================================================================
    
    Rectangle {
        id: container
        anchors.centerIn: parent
        width: 180
        height: 48
        radius: 24
        
        color: Config.backgroundColor
        border.width: 1
        border.color: Config.borderColor
        
        // Entry/exit animation
        opacity: osdWindow.osdVisible ? 1 : 0
        scale: osdWindow.osdVisible ? 1 : 0.8
        
        Behavior on opacity { 
            NumberAnimation { 
                duration: 200
                easing.type: Easing.OutCubic 
            } 
        }
        Behavior on scale { 
            NumberAnimation { 
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            } 
        }
        
        // Shadow
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.8
            shadowVerticalOffset: 4
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12
            
            // Icon
            Text {
                id: osdIcon
                text: {
                    if (osdWindow.osdMuted) return "volume_off"
                    if (osdWindow.osdType === "brightness") return "brightness_6"
                    if (osdWindow.osdValue > 66) return "volume_up"
                    if (osdWindow.osdValue > 33) return "volume_down"
                    if (osdWindow.osdValue > 0) return "volume_mute"
                    return "volume_off"
                }
                font.family: "Material Symbols Rounded"
                font.pixelSize: 22
                color: osdWindow.osdMuted ? Config.dimmedColor : 
                       (osdWindow.osdType === "brightness" ? "#FFB74D" : Config.accentColor)
                
                // Subtle bounce on icon change
                scale: 1.0
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: osdIcon; property: "scale"; to: 0.8; duration: 60 }
                        NumberAnimation { target: osdIcon; property: "scale"; to: 1.1; duration: 120; easing.type: Easing.OutBack }
                        NumberAnimation { target: osdIcon; property: "scale"; to: 1.0; duration: 80 }
                    }
                }
            }
            
            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Config.surfaceColor
                
                Rectangle {
                    width: parent.width * (osdWindow.osdMuted ? 0 : Math.min(osdWindow.osdValue, 100) / 100)
                    height: parent.height
                    radius: 3
                    color: osdWindow.osdMuted ? Config.dimmedColor :
                           (osdWindow.osdType === "brightness" ? "#FFB74D" : Config.accentColor)
                    
                    Behavior on width { 
                        NumberAnimation { 
                            duration: 120
                            easing.type: Easing.OutQuad
                        } 
                    }
                }
            }
            
            // Percentage
            Text {
                text: osdWindow.osdMuted ? "0" : osdWindow.osdValue
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: Config.foregroundColor
                
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
