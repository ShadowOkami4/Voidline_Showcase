/*
 * ============================================================================
 *                          BLUETOOTH SETTINGS
 * ============================================================================
 *
 * FILE: settings/BluetoothPage.qml
 * PURPOSE: UI for managing Bluetooth devices and pairing
 *
 * OVERVIEW:
 *   - Shows paired and available devices, allows pairing/unpairing.
 *   - Integrates with the Bluetooth agent and system Bluetooth service.
 *   - Exposes actions for connecting, disconnecting and trusting devices.
 *
 * NOTE: Actual pairing operations are performed by the system Bluetooth
 *       backend; this page provides a user-facing control surface.
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../misc"

Item {
    id: root
    
    // ========================================================================
    //                          MD3 COMPONENTS
    // ========================================================================
    
    // MD3 Card Component
    component MD3Card: Rectangle {
        default property alias content: cardContent.data
        property string title: ""
        property string icon: ""
        property color accentColor: Config.accentColor
        property bool showHeader: true
        
        Layout.fillWidth: true
        implicitHeight: cardContent.implicitHeight + (showHeader && title ? 88 : 32)
        radius: 16
        color: Config.surfaceColor
        border.width: 1
        border.color: Config.borderColor
        
        ColumnLayout {
            id: cardContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: showHeader && title ? 72 : 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8
        }
        
        RowLayout {
            visible: showHeader && title !== ""
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            height: 36
            spacing: 12
            
            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                
                Text {
                    anchors.centerIn: parent
                    text: icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: accentColor
                }
            }
            
            Text {
                text: title
                font.family: Config.fontFamily
                font.pixelSize: 16
                font.weight: Font.Medium
                color: Config.foregroundColor
            }
            
            Item { Layout.fillWidth: true }
        }
    }
    
    // MD3 Toggle
    component MD3Toggle: Rectangle {
        property bool checked: false
        signal toggled(bool value)
        
        width: 52
        height: 32
        radius: 16
        color: checked ? Config.accentColor : Qt.rgba(1,1,1,0.15)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: parent.checked ? Config.onAccent : "#FFFFFF"
            x: parent.checked ? parent.width - width - 4 : 4
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled(!parent.checked)
        }
    }
    
    // MD3 Device Card
    component DeviceCard: Rectangle {
        property string name: ""
        property string address: ""
        property string icon: "bluetooth"
        property bool isConnected: false
        property bool isPaired: true
        property int battery: -1
        property bool isBusy: false
        property int deviceState: 1
        
        signal connectClicked()
        signal disconnectClicked()
        signal removeClicked()
        signal pairClicked()
        
        Layout.fillWidth: true
        height: 72
        radius: 12
        color: isConnected ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1) :
               (cardMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        border.width: isConnected ? 1 : 0
        border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.3)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16
            
            // Device icon
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 12
                color: isConnected ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (icon.includes("audio-headset") || icon.includes("headphone")) return "headphones"
                        if (icon.includes("phone")) return "smartphone"
                        if (icon.includes("computer")) return "computer"
                        if (icon.includes("keyboard")) return "keyboard"
                        if (icon.includes("mouse")) return "mouse"
                        if (icon.includes("input-gaming")) return "sports_esports"
                        return "bluetooth"
                    }
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: isConnected ? Config.onAccent : Config.dimmedColor
                }
            }
            
            // Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: name
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: isConnected ? Font.Medium : Font.Normal
                    color: Config.foregroundColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    spacing: 8
                    
                    Text {
                        text: {
                            if (deviceState === 3 || isBusy) return "Connecting..."
                            if (deviceState === 2) return "Disconnecting..."
                            if (isConnected) return "Connected"
                            if (isPaired) return "Paired"
                            return "Available"
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: {
                            if (isBusy) return Config.warningColor
                            if (isConnected) return Config.accentColor
                            return Config.dimmedColor
                        }
                    }
                    
                    // Battery indicator
                    Rectangle {
                        visible: battery >= 0
                        width: batteryRow.width + 12
                        height: 20
                        radius: 6
                        color: battery <= 20 ? Qt.rgba(1,0.3,0.3,0.15) : Qt.rgba(0.3,0.8,0.4,0.15)
                        
                        RowLayout {
                            id: batteryRow
                            anchors.centerIn: parent
                            spacing: 4
                            
                            Text {
                                text: battery <= 20 ? "battery_1_bar" : (battery <= 50 ? "battery_3_bar" : "battery_full")
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: battery <= 20 ? Config.errorColor : Config.successColor
                            }
                            
                            Text {
                                text: battery + "%"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: battery <= 20 ? Config.errorColor : Config.successColor
                            }
                        }
                    }
                }
            }
            
            // Action buttons
            RowLayout {
                spacing: 8
                
                // Connect/Disconnect button
                Rectangle {
                    visible: isPaired
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 36
                    radius: 18
                    color: {
                        if (isConnected) return actionMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : Qt.rgba(1,1,1,0.06)
                        return actionMouse.containsMouse ? Config.accentColor : Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                    }
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: isConnected ? "Disconnect" : "Connect"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: isConnected ? (actionMouse.containsMouse ? Config.errorColor : Config.dimmedColor) :
                               (actionMouse.containsMouse ? Config.onAccent : Config.accentColor)
                    }
                    
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: isConnected ? disconnectClicked() : connectClicked()
                    }
                }
                
                // Pair button
                Rectangle {
                    visible: !isPaired
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 36
                    radius: 18
                    color: pairMouse.containsMouse ? Config.accentColor : Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Pair"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: pairMouse.containsMouse ? Config.onAccent : Config.accentColor
                    }
                    
                    MouseArea {
                        id: pairMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pairClicked()
                    }
                }
                
                // Remove button
                Rectangle {
                    visible: isPaired && !isConnected
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: removeMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : Qt.rgba(1,1,1,0.06)
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "delete"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: removeMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: removeClicked()
                    }
                }
            }
        }
        
        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
    
    // ========================================================================
    //                          MAIN LAYOUT
    // ========================================================================
    
    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.height + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Qt.rgba(1,1,1,0.3)
            }
        }
        
        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 24
            spacing: 20
            
            // Power & Settings Card
            MD3Card {
                title: "Settings"
                icon: "settings"
                accentColor: Config.accentColor
                
                // Power toggle row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 10
                        color: BluetoothHandler.powered ? Qt.rgba(0.27, 0.54, 1, 0.15) : Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "bluetooth"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: BluetoothHandler.powered ? Config.accentColor : Config.dimmedColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            text: "Bluetooth"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: BluetoothHandler.powered ? "Enabled" : "Disabled"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.dimmedColor
                        }
                    }
                    
                    MD3Toggle {
                        checked: BluetoothHandler.powered
                        onToggled: (val) => BluetoothHandler.setPower(val)
                    }
                }
                
                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Config.outlineVariant
                    visible: BluetoothHandler.powered
                }
                
                // Discoverable toggle row
                RowLayout {
                    visible: BluetoothHandler.powered
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 10
                        color: BluetoothHandler.discoverable ? Qt.rgba(0.27, 0.54, 1, 0.15) : Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "visibility"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: BluetoothHandler.discoverable ? Config.accentColor : Config.dimmedColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            text: "Discoverable"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: "Allow other devices to find this computer"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.dimmedColor
                        }
                    }
                    
                    MD3Toggle {
                        checked: BluetoothHandler.discoverable
                        onToggled: (val) => BluetoothHandler.setDiscoverable(val)
                    }
                }
            }
            
            // Paired Devices Card
            MD3Card {
                visible: BluetoothHandler.powered
                title: "Paired Devices"
                icon: "devices"
                accentColor: Config.accentColor
                
                Repeater {
                    model: BluetoothHandler.pairedDevices
                    
                    DeviceCard {
                        name: modelData.name
                        address: modelData.address
                        icon: modelData.icon
                        isConnected: modelData.connected
                        battery: modelData.battery
                        isBusy: BluetoothHandler.connectingDevice === modelData.address && !modelData.connected
                        deviceState: modelData.state !== undefined ? modelData.state : 1
                        isPaired: true
                        
                        onConnectClicked: BluetoothHandler.connect(modelData.address)
                        onDisconnectClicked: BluetoothHandler.disconnect(modelData.address)
                        onRemoveClicked: BluetoothHandler.remove(modelData.address)
                    }
                }
                
                Text {
                    visible: BluetoothHandler.pairedDevices.length === 0
                    text: "No paired devices"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                }
            }
            
            // Available Devices Card
            MD3Card {
                visible: BluetoothHandler.powered
                title: "Available Devices"
                icon: "bluetooth_searching"
                accentColor: Config.accentColor
                
                // Scan button
                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    radius: 12
                    color: BluetoothHandler.discovering ? Qt.rgba(0.27, 0.54, 1, 0.15) :
                           (scanMouse.containsMouse ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.04))
                    border.width: BluetoothHandler.discovering ? 1 : 0
                    border.color: Config.accentColor
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: BluetoothHandler.discovering ? "search" : "bluetooth_searching"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
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
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: BluetoothHandler.discovering ? Config.accentColor : Config.dimmedColor
                        }
                    }
                    
                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BluetoothHandler.discovering ? BluetoothHandler.stopScan() : BluetoothHandler.startScan()
                    }
                }
                
                // Available devices list
                Repeater {
                    model: BluetoothHandler.availableDevices
                    
                    DeviceCard {
                        name: modelData.name
                        address: modelData.address
                        icon: modelData.icon
                        isConnected: false
                        isPaired: false
                        isBusy: BluetoothHandler.connectingDevice === modelData.address
                        deviceState: modelData.state !== undefined ? modelData.state : 1
                        
                        onPairClicked: BluetoothHandler.pair(modelData.address)
                    }
                }
                
                Text {
                    visible: BluetoothHandler.availableDevices.length === 0 && !BluetoothHandler.discovering
                    text: "No devices found. Click scan to search."
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }
            
            Item { height: 8 }
        }
    }
}
