/*
 * ============================================================================
 *                         BLUETOOTH PANEL
 * ============================================================================
 * 
 * FILE: panels/BluetoothPanel.qml
 * PURPOSE: Quick Bluetooth controls popup from system tray
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This panel provides quick Bluetooth controls:
 *   - Power toggle
 *   - Scanning for devices
 *   - List of paired devices with connect/disconnect
 *   - List of available devices for pairing
 *   - Quick access to full Bluetooth settings
 * 
 * Uses BluetoothHandler singleton for all Bluetooth operations.
 * 
 * ============================================================================
 */

import Quickshell
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
    id: bluetoothPanel
    
    property var parentBar
    
    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.bluetoothPanelVisible
    property bool isClosing: false
    
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    implicitWidth: 360
    implicitHeight: Math.min(contentCol.implicitHeight + 32, 480)
    
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
        onTriggered: bluetoothPanel.isClosing = false
    }
    
    // Focus grab
    HyprlandFocusGrab {
        active: bluetoothPanel.visible
        windows: [bluetoothPanel]
        onCleared: ShellState.bluetoothPanelVisible = false
    }
    
    // Refresh on visibility
    onVisibleChanged: {
        if (visible) {
            BluetoothHandler.refresh()
        }
    }
    
    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        color: Config.backgroundColor
        border.width: 1
        border.color: Config.borderColor
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 1.2
            shadowVerticalOffset: 8
            shadowHorizontalOffset: 0
        }
        
        opacity: bluetoothPanel.isOpen ? 1 : 0
        scale: bluetoothPanel.isOpen ? 1 : 0.9
        transformOrigin: Item.Top
        
        // M3 Expressive spring animation
        Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { 
            NumberAnimation { 
                duration: Config.animSpring
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            } 
        }
        
        // Scrollable content
        Flickable {
            anchors.fill: parent
            anchors.margins: Config.padding
            contentHeight: contentCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            ColumnLayout {
                id: contentCol
                width: parent.width
                spacing: Config.spacingLarge
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacingLarge
                    
                    Rectangle {
                        width: 48
                        height: 48
                        radius: Config.cardRadius
                        color: BluetoothHandler.powered ? Config.accentColorContainer : Config.surfaceColorActive
                        
                        Behavior on color { ColorAnimation { duration: Config.animNormal } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "bluetooth"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: Config.iconSizeLarge
                            color: BluetoothHandler.powered ? Config.accentColor : Config.dimmedColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: "Bluetooth"
                            font.pixelSize: Config.fontSizeTitle
                            font.weight: Config.fontWeightMedium
                            font.family: Config.fontFamily
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: BluetoothHandler.powered ? 
                                  (BluetoothHandler.controllerName || "Enabled") : "Disabled"
                            font.pixelSize: Config.fontSizeSmall
                            font.family: Config.fontFamily
                            color: Config.dimmedColor
                        }
                    }
                    
                    // Power toggle (Material Design Switch)
                    Rectangle {
                        width: 52
                        height: 32
                        radius: 16
                        color: BluetoothHandler.powered ? Config.accentColor : Config.surfaceColorActive
                        
                        Behavior on color { ColorAnimation { duration: Config.animNormal } }
                        
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 12
                            color: BluetoothHandler.powered ? Config.onAccent : Config.dimmedColor
                            x: BluetoothHandler.powered ? parent.width - width - 4 : 4
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Behavior on x { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutQuart } }
                            Behavior on color { ColorAnimation { duration: Config.animNormal } }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BluetoothHandler.setPower(!BluetoothHandler.powered)
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Config.borderColor
                    visible: BluetoothHandler.powered
                }
                
                // Paired devices section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacing
                    visible: BluetoothHandler.powered
                    
                    Text {
                        text: "Paired Devices"
                        font.pixelSize: Config.fontSizeLabel
                        font.weight: Config.fontWeightMedium
                        font.family: Config.fontFamily
                        color: Config.dimmedColor
                        font.letterSpacing: 0.5
                    }
                    
                    // No devices message
                    Text {
                        visible: BluetoothHandler.pairedDevices.length === 0
                        text: "No paired devices"
                        font.pixelSize: Config.fontSize
                        font.family: Config.fontFamily
                        color: Config.dimmedColor
                        Layout.leftMargin: 4
                    }
                    
                    // Paired device list
                    Repeater {
                        model: BluetoothHandler.pairedDevices
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 56
                            radius: Config.cardRadius
                            color: modelData.connected ? Config.accentColorContainer :
                                   (deviceMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor)
                            
                            Behavior on color { ColorAnimation { duration: Config.animFast } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                
                                // Device icon
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: Config.smallRadius
                                    color: modelData.connected ? Config.accentColor : Config.surfaceColorActive
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            let icon = modelData.icon || ""
                                            if (icon.includes("audio") || icon.includes("headphone")) return "headphones"
                                            if (icon.includes("phone")) return "smartphone"
                                            if (icon.includes("computer")) return "computer"
                                            if (icon.includes("keyboard")) return "keyboard"
                                            if (icon.includes("mouse")) return "mouse"
                                            if (icon.includes("gaming")) return "sports_esports"
                                            return "bluetooth"
                                        }
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 14
                                        color: modelData.connected ? Config.foregroundColor : Config.dimmedColor
                                    }
                                }
                                
                                // Device name and status
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    
                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 12
                                        font.weight: modelData.connected ? Font.Medium : Font.Normal
                                        color: Config.foregroundColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    
                                    RowLayout {
                                        spacing: 6
                                        
                                        Text {
                                            text: modelData.connected ? "Connected" : "Paired"
                                            font.pixelSize: 10
                                            color: modelData.connected ? Config.accentColor : Config.dimmedColor
                                        }
                                        
                                        Rectangle {
                                            visible: modelData.battery >= 0
                                            width: batteryText.width + 8
                                            height: 14
                                            radius: 3
                                            color: modelData.battery <= 20 ? Qt.rgba(1,0.3,0.3,0.2) : Qt.rgba(0.4,0.7,0.45,0.2)
                                            
                                            Text {
                                                id: batteryText
                                                anchors.centerIn: parent
                                                text: modelData.battery + "%"
                                                font.pixelSize: 9
                                                color: modelData.battery <= 20 ? Config.errorColor : Config.successColor
                                            }
                                        }
                                    }
                                }
                                
                                // Connect/Disconnect button
                                Rectangle {
                                    width: 64
                                    height: 28
                                    radius: Config.smallRadius
                                    color: {
                                        if (modelData.connected) 
                                            return actionMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : Config.surfaceColor
                                        return actionMouse.containsMouse ? Config.accentColor : Config.accentColorDim
                                    }
                                    
                                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "Disconnect" : "Connect"
                                        font.pixelSize: 9
                                        color: modelData.connected ? 
                                               (actionMouse.containsMouse ? Config.errorColor : Config.dimmedColor) :
                                               (actionMouse.containsMouse ? Config.foregroundColor : Config.accentColor)
                                    }
                                    
                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.connected) {
                                                BluetoothHandler.disconnect(modelData.address)
                                            } else {
                                                BluetoothHandler.connect(modelData.address)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: deviceMouse
                                anchors.fill: parent
                                z: -1
                                hoverEnabled: true
                            }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Config.borderColor
                    visible: BluetoothHandler.powered
                }
                
                // Scan button
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: Config.cardRadius
                    visible: BluetoothHandler.powered
                    color: BluetoothHandler.discovering ? Config.accentColorDim :
                           (scanMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor)
                    border.width: BluetoothHandler.discovering ? 1 : 0
                    border.color: Config.accentColor
                    
                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: BluetoothHandler.discovering ? "search" : "bluetooth_searching"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: BluetoothHandler.discovering ? Config.accentColor : Config.dimmedColor
                            
                            RotationAnimation on rotation {
                                running: BluetoothHandler.discovering
                                from: 0
                                to: 360
                                duration: 2000
                                loops: Animation.Infinite
                            }
                        }
                        
                        Text {
                            text: BluetoothHandler.discovering ? "Scanning..." : "Scan for devices"
                            font.pixelSize: 12
                            color: BluetoothHandler.discovering ? Config.accentColor : Config.dimmedColor
                        }
                    }
                    
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (BluetoothHandler.discovering) {
                                BluetoothHandler.stopScan()
                            } else {
                                BluetoothHandler.startScan()
                            }
                        }
                    }
                }
                
                // Available devices section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: BluetoothHandler.powered && BluetoothHandler.availableDevices.length > 0
                    
                    Text {
                        text: "Available Devices"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: Config.dimmedColor
                        font.letterSpacing: 0.5
                    }
                    
                    // Available device list
                    Repeater {
                        model: BluetoothHandler.availableDevices
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: Config.cardRadius
                            color: availMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                            
                            Behavior on color { ColorAnimation { duration: Config.animFast } }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                
                                // Device icon
                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Config.smallRadius
                                    color: Config.surfaceColorActive
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "bluetooth"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 12
                                        color: Config.dimmedColor
                                    }
                                }
                                
                                // Device name
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.pixelSize: 12
                                    color: Config.foregroundColor
                                    elide: Text.ElideRight
                                }
                                
                                // Pair button
                                Rectangle {
                                    width: 48
                                    height: 26
                                    radius: Config.smallRadius
                                    color: pairMouse.containsMouse ? Config.accentColor : Config.accentColorDim
                                    
                                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Pair"
                                        font.pixelSize: 10
                                        color: pairMouse.containsMouse ? Config.foregroundColor : Config.accentColor
                                    }
                                    
                                    MouseArea {
                                        id: pairMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: BluetoothHandler.pair(modelData.address)
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: availMouse
                                anchors.fill: parent
                                z: -1
                                hoverEnabled: true
                            }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Config.borderColor
                }
                
                // Settings button
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: Config.cardRadius
                    color: settingsMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                    
                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "settings"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: settingsMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                        }
                        
                        Text {
                            text: "Bluetooth Settings"
                            font.pixelSize: 12
                            color: settingsMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                        }
                    }
                    
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellState.bluetoothPanelVisible = false
                            ShellState.openSettings("bluetooth")
                        }
                    }
                }
            }
        }
    }
}
