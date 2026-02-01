/*
 * ============================================================================
 *                            NETWORK SETTINGS
 * ============================================================================
 *
 * FILE: settings/NetworkPage.qml
 * PURPOSE: UI for managing network connections and interfaces
 *
 * OVERVIEW:
 *   - Scan for WiFi networks, manage saved connections, and configure
 *     Ethernet settings.
 *   - Provides UI for DHCP/static IP configuration and connection details.
 *   - Uses NetworkManager or nmcli under the hood for operations.
 *
 * NOTE: This page is a UI layer—actual network changes are applied by the
 *       underlying system network manager.
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
    
    component MD3Card: Rectangle {
        default property alias content: cardContent.data
        property string title: ""
        property string icon: ""
        property color accentColor: Config.accentColor
        
        Layout.fillWidth: true
        implicitHeight: cardContent.implicitHeight + (title ? 88 : 32)
        radius: 16
        color: Config.surfaceColor
        border.width: 1
        border.color: Config.borderColor
        
        ColumnLayout {
            id: cardContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: title ? 72 : 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8
        }
        
        RowLayout {
            visible: title !== ""
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
    
    component MD3Input: Rectangle {
        property string placeholder: ""
        property alias text: input.text
        property bool isPassword: false
        
        Layout.fillWidth: true
        height: 48
        radius: 12
        color: Qt.rgba(1,1,1,0.04)
        border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? Config.accentColor : Config.borderColor
        
        Behavior on border.color { ColorAnimation { duration: 150 } }
        
        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 16
            color: Config.foregroundColor
            font.family: Config.fontFamily
            font.pixelSize: 14
            echoMode: parent.isPassword ? TextInput.Password : TextInput.Normal
            clip: true
            verticalAlignment: TextInput.AlignVCenter
            
            Text {
                visible: !parent.text
                text: parent.parent.placeholder
                color: Config.dimmedColor
                font.family: Config.fontFamily
                font.pixelSize: 14
            }
        }
    }
    
    component NetworkCard: Rectangle {
        property string ssid: ""
        property int signal: 0
        property string security: ""
        property bool isActive: false
        
        signal connectClicked()
        
        Layout.fillWidth: true
        height: 64
        radius: 12
        color: isActive ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1) :
               (netMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        border.width: isActive ? 1 : 0
        border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.3)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16
            
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 12
                color: isActive ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (signal >= 75) return "signal_wifi_4_bar"
                        if (signal >= 50) return "network_wifi_3_bar"
                        if (signal >= 25) return "network_wifi_2_bar"
                        return "network_wifi_1_bar"
                    }
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                    color: isActive ? Config.onAccent : Config.dimmedColor
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                RowLayout {
                    spacing: 8
                    
                    Text {
                        text: ssid
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        font.weight: isActive ? Font.Medium : Font.Normal
                        color: Config.foregroundColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        visible: security && security !== "--"
                        text: "lock"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: Config.dimmedColor
                    }
                }
                
                Text {
                    text: isActive ? "Connected" : signal + "% signal"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: isActive ? Config.accentColor : Config.dimmedColor
                }
            }
            
            Rectangle {
                visible: !isActive
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                radius: 18
                color: connMouse.containsMouse ? Config.accentColor : Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: connMouse.containsMouse ? Config.onAccent : Config.accentColor
                }
                
                MouseArea {
                    id: connMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: connectClicked()
                }
            }
        }
        
        MouseArea {
            id: netMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
    
    component SavedConnectionCard: Rectangle {
        property string name: ""
        property string connectionType: "wifi"
        property bool isActive: false
        
        signal deleteClicked()
        signal connectClicked()
        
        Layout.fillWidth: true
        height: 64
        radius: 12
        color: isActive ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1) :
               (savedMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        border.width: isActive ? 1 : 0
        border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.3)
        
        Behavior on color { ColorAnimation { duration: 150 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 16
            
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 12
                color: isActive ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: connectionType === "ethernet" ? "lan" : "wifi"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 22
                    color: isActive ? Config.onAccent : Config.dimmedColor
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                Text {
                    text: name
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: isActive ? Font.Medium : Font.Normal
                    color: Config.foregroundColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    spacing: 8
                    
                    Rectangle {
                        width: typeLabel.width + 12
                        height: 20
                        radius: 6
                        color: connectionType === "ethernet" ? Qt.rgba(0.3,0.8,0.4,0.15) : Qt.rgba(0.27,0.54,1,0.15)
                        
                        Text {
                            id: typeLabel
                            anchors.centerIn: parent
                            text: connectionType === "ethernet" ? "Ethernet" : "WiFi"
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: connectionType === "ethernet" ? Config.successColor : Config.accentColor
                        }
                    }
                    
                    Text {
                        visible: isActive
                        text: "● Connected"
                        font.family: Config.fontFamily
                        font.pixelSize: 11
                        color: Config.successColor
                    }
                }
            }
            
            Rectangle {
                visible: !isActive
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: delMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : Qt.rgba(1,1,1,0.06)
                
                Behavior on color { ColorAnimation { duration: 150 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "delete"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: delMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                }
                
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deleteClicked()
                }
            }
        }
        
        MouseArea {
            id: savedMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (!isActive) connectClicked()
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
            
            // Connection Status Card
            MD3Card {
                title: "Status"
                icon: NetworkHandler.connectionType === "ethernet" ? "lan" : "wifi"
                accentColor: Config.accentColor
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 72
                    radius: 12
                    color: NetworkHandler.connectionStatus === "connected" ? 
                           Qt.rgba(0, 0.75, 0.65, 0.1) : Qt.rgba(1,1,1,0.04)
                    border.width: NetworkHandler.connectionStatus === "connected" ? 1 : 0
                    border.color: Config.accentColor
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16
                        
                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 12
                            color: NetworkHandler.connectionStatus === "connected" ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                            
                            Text {
                                anchors.centerIn: parent
                                text: NetworkHandler.connectionType === "ethernet" ? "lan" : 
                                      (NetworkHandler.connectionStatus === "connected" ? "wifi" : "wifi_off")
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 24
                                color: NetworkHandler.connectionStatus === "connected" ? Config.onAccent : Config.dimmedColor
                            }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            Text {
                                text: NetworkHandler.connectionStatus === "connected" ? 
                                      NetworkHandler.currentSSID : "Not Connected"
                                font.family: Config.fontFamily
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                color: Config.foregroundColor
                            }
                            
                            Text {
                                text: NetworkHandler.connectionStatus === "connected" ? 
                                      "IP: " + NetworkHandler.ipAddress : "Connect to a network"
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                color: Config.dimmedColor
                            }
                        }
                        
                        Rectangle {
                            visible: NetworkHandler.connectionStatus === "connected"
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 40
                            radius: 20
                            color: discMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.2) : Qt.rgba(1,1,1,0.06)
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Disconnect"
                                font.family: Config.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: discMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                            }
                            
                            MouseArea {
                                id: discMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkHandler.disconnect()
                            }
                        }
                    }
                }
            }
            
            // WiFi Settings Card
            MD3Card {
                title: "Wireless"
                icon: "wifi"
                accentColor: Config.accentColor
                
                // WiFi toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 10
                        color: NetworkHandler.wifiEnabled ? Qt.rgba(0, 0.75, 0.65, 0.15) : Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "wifi"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: NetworkHandler.wifiEnabled ? Config.accentColor : Config.dimmedColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Text {
                            text: "WiFi"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: NetworkHandler.wifiEnabled ? "Enabled" : "Disabled"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.dimmedColor
                        }
                    }
                    
                    MD3Toggle {
                        checked: NetworkHandler.wifiEnabled
                        onToggled: (val) => NetworkHandler.toggleWifi(val)
                    }
                }
            }
            
            // Available Networks Card
            MD3Card {
                visible: NetworkHandler.wifiEnabled && !NetworkHandler.showPasswordDialog
                title: "Available Networks"
                icon: "cell_tower"
                accentColor: Config.accentColor
                
                Repeater {
                    model: NetworkHandler.networkList
                    
                    NetworkCard {
                        ssid: modelData.ssid
                        signal: modelData.signal
                        security: modelData.security
                        isActive: modelData.active
                        
                        onConnectClicked: {
                            NetworkHandler.selectedSSID = modelData.ssid
                            NetworkHandler.selectedSecurity = modelData.security
                            NetworkHandler.connectNetwork(modelData.ssid)
                        }
                    }
                }
                
                Text {
                    visible: NetworkHandler.networkList.length === 0
                    text: "No networks found"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                }
            }
            
            // Password Dialog Card
            MD3Card {
                visible: NetworkHandler.showPasswordDialog
                title: "Connect to " + NetworkHandler.selectedSSID
                icon: "lock"
                accentColor: Config.accentColor
                
                MD3Input {
                    id: passwordInput
                    placeholder: "Enter password..."
                    isPassword: true
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 40
                        radius: 20
                        color: cancelMouse.containsMouse ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.06)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkHandler.showPasswordDialog = false
                                passwordInput.text = ""
                            }
                        }
                    }
                    
                    Rectangle {
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 40
                        radius: 20
                        color: connPwdMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Config.onAccent
                        }
                        
                        MouseArea {
                            id: connPwdMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkHandler.connectWithPassword(NetworkHandler.selectedSSID, passwordInput.text)
                        }
                    }
                }
            }
            
            // Saved Connections Card
            MD3Card {
                title: "Saved Connections"
                icon: "folder_managed"
                accentColor: Config.accentColor
                
                Repeater {
                    model: NetworkHandler.savedConnections
                    
                    SavedConnectionCard {
                        name: modelData.name
                        connectionType: modelData.type
                        isActive: modelData.active
                        
                        onDeleteClicked: NetworkHandler.deleteConnection(modelData.name)
                        onConnectClicked: NetworkHandler.connectNetwork(modelData.name)
                    }
                }
                
                Text {
                    visible: NetworkHandler.savedConnections.length === 0
                    text: "No saved connections"
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                }
            }
            
            Item { height: 8 }
        }
    }
}
