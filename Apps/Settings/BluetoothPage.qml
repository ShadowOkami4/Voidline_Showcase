/*
 * ============================================================================
 *                       BLUETOOTH SETTINGS - NEW DESIGN
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../misc"
import "../../Handlers"

Item {
    id: root
    
    // ========================================================================
    //                          REUSABLE COMPONENTS
    // ========================================================================
    
    component Section: Rectangle {
        default property alias content: sectionContent.data
        property string title: ""
        
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + 56
        radius: 12
        color: Config.surfaceColor
        
        ColumnLayout {
            id: sectionContent
            anchors.fill: parent
            anchors.topMargin: 48
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 12
            spacing: 8
        }
        
        Text {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 16
            anchors.leftMargin: 16
            text: title
            font.family: Config.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: Config.dimmedColor
            opacity: 0.8
        }
    }
    
    component Toggle: Rectangle {
        property bool checked: false
        signal toggled(bool value)
        
        width: 44
        height: 24
        radius: 12
        color: checked ? Config.accentColor : Qt.rgba(1,1,1,0.12)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        Rectangle {
            width: 18
            height: 18
            radius: 9
            color: "#fff"
            x: parent.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled(!parent.checked)
        }
    }
    
    component DeviceItem: Rectangle {
        id: deviceRoot
        property string name: ""
        property string address: ""
        property string icon: "bluetooth"
        property bool connected: false
        property bool paired: true
        property int battery: -1
        property bool busy: false
        
        signal connectClicked()
        signal disconnectClicked()
        signal removeClicked()
        signal pairClicked()
        
        Layout.fillWidth: true
        height: 56
        radius: 10
        color: connected ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.12)
                         : (deviceMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        
        Behavior on color { ColorAnimation { duration: 120 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            
            // Device icon
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 8
                color: connected ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        let ic = (icon || "").toLowerCase()
                        if (ic.includes("headset") || ic.includes("headphone")) return "headphones"
                        if (ic.includes("phone")) return "smartphone"
                        if (ic.includes("computer")) return "computer"
                        if (ic.includes("keyboard")) return "keyboard"
                        if (ic.includes("mouse")) return "mouse"
                        if (ic.includes("gaming")) return "sports_esports"
                        return "bluetooth"
                    }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    color: connected ? Config.onAccent : Config.dimmedColor
                }
            }
            
            // Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                Text {
                    text: name || "Unknown"
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.weight: connected ? Font.Medium : Font.Normal
                    color: Config.foregroundColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    spacing: 8
                    
                    Text {
                        text: {
                            if (busy) return "Connecting..."
                            if (connected) return "Connected"
                            if (paired) return "Paired"
                            return "Available"
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: {
                            if (busy) return Config.warningColor
                            if (connected) return Config.accentColor
                            return Config.dimmedColor
                        }
                    }
                    
                    // Battery
                    Rectangle {
                        visible: battery >= 0
                        width: battRow.width + 10
                        height: 18
                        radius: 9
                        color: battery <= 20 ? Qt.rgba(1,0.3,0.3,0.15) : Qt.rgba(0.3,0.8,0.4,0.15)
                        
                        RowLayout {
                            id: battRow
                            anchors.centerIn: parent
                            spacing: 3
                            
                            Text {
                                text: battery <= 20 ? "battery_1_bar" : "battery_full"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 12
                                color: battery <= 20 ? Config.errorColor : Config.successColor
                            }
                            
                            Text {
                                text: battery + "%"
                                font.family: Config.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: battery <= 20 ? Config.errorColor : Config.successColor
                            }
                        }
                    }
                }
            }
            
            // Actions
            RowLayout {
                spacing: 6
                
                // Connect/Disconnect
                Rectangle {
                    visible: paired
                    width: 80
                    height: 28
                    radius: 14
                    color: {
                        if (connected) return actionMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.15) : Qt.rgba(1,1,1,0.06)
                        return actionMouse.containsMouse ? Config.accentColor : Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                    }
                    
                    Behavior on color { ColorAnimation { duration: 100 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: connected ? "Disconnect" : "Connect"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: connected 
                               ? (actionMouse.containsMouse ? Config.errorColor : Config.dimmedColor)
                               : (actionMouse.containsMouse ? Config.onAccent : Config.accentColor)
                    }
                    
                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: connected ? deviceRoot.disconnectClicked() : deviceRoot.connectClicked()
                    }
                }
                
                // Pair
                Rectangle {
                    visible: !paired
                    width: 60
                    height: 28
                    radius: 14
                    color: pairMouse.containsMouse ? Config.accentColor : Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Pair"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: pairMouse.containsMouse ? Config.onAccent : Config.accentColor
                    }
                    
                    MouseArea {
                        id: pairMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deviceRoot.pairClicked()
                    }
                }
                
                // Remove
                Rectangle {
                    visible: paired && !connected
                    width: 28
                    height: 28
                    radius: 6
                    color: removeMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.15) : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "delete"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: removeMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                    }
                    
                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: deviceRoot.removeClicked()
                    }
                }
            }
        }
        
        MouseArea {
            id: deviceMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
    
    // ========================================================================
    //                              MAIN LAYOUT
    // ========================================================================
    
    Flickable {
        anchors.fill: parent
        contentHeight: mainCol.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 3
                radius: 1.5
                color: Qt.rgba(1,1,1,0.2)
            }
        }
        
        ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            spacing: 16
            
            // Settings Section
            Section {
                title: "SETTINGS"
                
                // Bluetooth toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        text: "bluetooth"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: BluetoothHandler.powered ? Config.accentColor : Config.dimmedColor
                    }
                    
                    Text {
                        text: "Bluetooth"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Toggle {
                        checked: BluetoothHandler.powered
                        onToggled: (val) => BluetoothHandler.setPower(val)
                    }
                }
                
                // Discoverable toggle
                RowLayout {
                    visible: BluetoothHandler.powered
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        text: "visibility"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: BluetoothHandler.discoverable ? Config.accentColor : Config.dimmedColor
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        
                        Text {
                            text: "Discoverable"
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: "Allow other devices to find this computer"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            color: Config.dimmedColor
                        }
                    }
                    
                    Toggle {
                        checked: BluetoothHandler.discoverable
                        onToggled: (val) => BluetoothHandler.setDiscoverable(val)
                    }
                }
            }
            
            // Paired Devices
            Section {
                visible: BluetoothHandler.powered
                title: "PAIRED DEVICES"
                
                Repeater {
                    model: BluetoothHandler.pairedDevices
                    
                    DeviceItem {
                        name: modelData.name
                        address: modelData.address
                        icon: modelData.icon
                        connected: modelData.connected
                        battery: modelData.battery
                        busy: BluetoothHandler.connectingDevice === modelData.address && !modelData.connected
                        paired: true
                        
                        onConnectClicked: BluetoothHandler.connect(modelData.address)
                        onDisconnectClicked: BluetoothHandler.disconnect(modelData.address)
                        onRemoveClicked: BluetoothHandler.remove(modelData.address)
                    }
                }
                
                Text {
                    visible: BluetoothHandler.pairedDevices.length === 0
                    text: "No paired devices"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }
            
            // Available Devices
            Section {
                visible: BluetoothHandler.powered
                title: "AVAILABLE DEVICES"
                
                // Scan button
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 10
                    color: BluetoothHandler.discovering 
                           ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.12)
                           : (scanMouse.containsMouse ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.04))
                    border.width: BluetoothHandler.discovering ? 1 : 0
                    border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.3)
                    
                    Behavior on color { ColorAnimation { duration: 100 } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "bluetooth_searching"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
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
                            font.pixelSize: 12
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
                
                Repeater {
                    model: BluetoothHandler.availableDevices
                    
                    DeviceItem {
                        name: modelData.name
                        address: modelData.address
                        icon: modelData.icon
                        connected: false
                        paired: false
                        busy: BluetoothHandler.connectingDevice === modelData.address
                        
                        onPairClicked: BluetoothHandler.pair(modelData.address)
                    }
                }
                
                Text {
                    visible: BluetoothHandler.availableDevices.length === 0 && !BluetoothHandler.discovering
                    text: "No devices found"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }
        }
    }
}
