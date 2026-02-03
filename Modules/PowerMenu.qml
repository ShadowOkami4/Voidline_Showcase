/*
 * ============================================================================
 *                           POWER MENU
 * ============================================================================
 * 
 * FILE: Modules/PowerMenu.qml
 * PURPOSE: Power menu with shutdown, reboot, logout options
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This panel provides power/session controls:
 *   - Lock screen
 *   - Log out (exit Hyprland)
 *   - Suspend (sleep)
 *   - Hibernate
 *   - Reboot
 *   - Shutdown
 * 
 * Uses systemctl for power operations and hyprctl for session control.
 * 
 * ============================================================================
 *                         SYSTEM COMMANDS
 * ============================================================================
 * 
 * POWER MANAGEMENT (via systemctl):
 *   systemctl poweroff      <- Shutdown
 *   systemctl reboot        <- Reboot
 *   systemctl suspend       <- Suspend to RAM (sleep)
 *   systemctl hibernate     <- Suspend to disk
 * 
 * SESSION MANAGEMENT:
 *   hyprctl dispatch exit   <- Log out of Hyprland
 *   hyprlock                <- Lock screen (Hyprland lock)
 *   swaylock                <- Lock screen (fallback)
 *   loginctl lock-session   <- Lock screen (systemd fallback)
 * 
 * ============================================================================
 *                         INLINE COMPONENT
 * ============================================================================
 * 
 * component PowerButton: Rectangle {
 *     property string icon: ""
 *     property string label: ""
 *     property bool danger: false
 *     signal clicked()
 * }
 * 
 * This creates a reusable button component only available in this file.
 * Each power option uses this component with different icon/label.
 * 
 * The 'danger: true' property makes the button red (for shutdown/reboot).
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

/*
 * ============================================================================
 *                          POPUP WINDOW
 * ============================================================================
 */
PopupWindow {
    id: powerMenu
    
    property var parentBar
    
    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.powerMenuVisible
    property bool isClosing: false
    
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    implicitWidth: 460
    implicitHeight: contentCol.implicitHeight + 32
    
    // Stay visible during close animation
    visible: isOpen || isClosing
    color: "transparent"
    
    onIsOpenChanged: {
        if (!isOpen) {
            isClosing = true
            closeTimer.start()
        }
    }
    
    // Timer to hide after close animation
    Timer {
        id: closeTimer
        interval: Config.animSpring
        onTriggered: powerMenu.isClosing = false
    }
    
    // Focus grab
    HyprlandFocusGrab {
        active: powerMenu.visible
        windows: [powerMenu]
        onCleared: ShellState.powerMenuVisible = false
    }
    
    // Power action processes
    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }
    Process { id: rebootProc; command: ["systemctl", "reboot"] }
    Process { id: suspendProc; command: ["systemctl", "suspend"] }
    Process { id: hibernateProc; command: ["systemctl", "hibernate"] }
    Process { id: logoutProc; command: ["hyprctl", "dispatch", "exit"] }

    // M3 Expressive Icon Action Button
    component PowerAction: Rectangle {
        id: actionBtn
        property string icon: ""
        property string label: ""
        property bool danger: false
        signal clicked()
        
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        radius: 24
        color: btnMouse.containsMouse ? 
               (danger ? Qt.rgba(1, 0.3, 0.3, 0.15) : Config.surfaceColorHover) : 
               Config.surfaceColor
        border.width: 1
        border.color: btnMouse.containsMouse && danger ? Config.errorColor : Config.borderColor
        
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        
        scale: btnMouse.pressed ? 0.94 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: actionBtn.icon
                font.family: "Material Symbols Rounded"
                font.pixelSize: 32
                color: actionBtn.danger ? Config.errorColor : Config.foregroundColor
                
                scale: btnMouse.containsMouse ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: actionBtn.label
                font.family: Config.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                color: Config.dimmedColor
            }
        }
        
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionBtn.clicked()
        }
    }
    
    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        // Glassy background
        color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
        border.width: 1
        border.color: Config.borderColor
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: false
        }
        
        opacity: powerMenu.isOpen ? 1 : 0
        scale: powerMenu.isOpen ? 1 : 0.9
        transformOrigin: Item.Top
        
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        
        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            
            // ================================================================
            //                     SLIDE TO LOCK
            // ================================================================
            Rectangle {
                id: sliderTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 32
                color: Config.surfaceColorActive
                border.width: 1
                border.color: Config.borderColor
                clip: true
                
                // Track Text
                Text {
                    anchors.centerIn: parent
                    text: "Slide to Lock"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.0
                    color: Config.dimmedColor
                    opacity: 1.0 - (dragHandle.x / (sliderTrack.width - dragHandle.width))
                }
                
                // Success Fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: dragHandle.x + dragHandle.width / 2
                    radius: 32
                    color: Config.accentColor
                    opacity: 0.2
                }
                
                // Draggable Handle
                Rectangle {
                    id: dragHandle
                    width: 56
                    height: 56
                    radius: 28
                    color: Config.accentColor
                    
                    anchors.verticalCenter: parent.verticalCenter
                    // Start position with margin
                    x: 4
                    
                    // Icon
                    Text {
                        anchors.centerIn: parent
                        text: "lock"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        color: Config.onAccent
                    }
                    
                    // Drag Logic
                    MouseArea {
                        anchors.fill: parent
                        drag.target: dragHandle
                        drag.axis: Drag.XAxis
                        drag.minimumX: 4
                        drag.maximumX: sliderTrack.width - dragHandle.width - 4
                        
                        onReleased: {
                            if (dragHandle.x > (drag.maximumX * 0.7)) {
                                // Trigger Lock
                                ShellState.powerMenuVisible = false
                                ShellState.lockScreenVisible = true
                                // Reset position after action
                                resetAnim.start()
                            } else {
                                // Snap back
                                resetAnim.start()
                            }
                        }
                    }
                    
                    // Reset Animation
                    NumberAnimation on x {
                        id: resetAnim
                        to: 4
                        duration: 400
                        easing.type: Easing.OutBack
                        running: false
                    }
                }
            }
            
            // ================================================================
            //                     ACTION GRID
            // ================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                
                PowerAction {
                    icon: "bedtime"
                    label: "Sleep"
                    onClicked: { ShellState.powerMenuVisible = false; suspendProc.running = true }
                }
                
                PowerAction {
                    icon: "logout"
                    label: "Logout"
                    onClicked: { ShellState.powerMenuVisible = false; logoutProc.running = true }
                }
                
                PowerAction {
                    icon: "restart_alt"
                    label: "Reboot"
                    danger: true
                    onClicked: { ShellState.powerMenuVisible = false; rebootProc.running = true }
                }
                
                PowerAction {
                    icon: "power_settings_new"
                    label: "Off"
                    danger: true
                    onClicked: { ShellState.powerMenuVisible = false; shutdownProc.running = true }
                }
            }
        }
    }
}