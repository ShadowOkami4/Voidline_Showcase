/*
 * ============================================================================
 *                        NETWORK SETTINGS - NEW DESIGN
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
    
    component WifiItem: Rectangle {
        id: wifiRoot
        property string ssid: ""
        property int signal: 0
        property string security: ""
        property bool active: false
        
        signal connectClicked()
        
        Layout.fillWidth: true
        height: 52
        radius: 10
        color: active ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.12)
                      : (wifiMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        
        Behavior on color { ColorAnimation { duration: 120 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            
            // Signal icon
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: active ? Config.accentColor : Qt.rgba(1,1,1,0.06)
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (signal >= 75) return "signal_wifi_4_bar"
                        if (signal >= 50) return "network_wifi_3_bar"
                        if (signal >= 25) return "network_wifi_2_bar"
                        return "network_wifi_1_bar"
                    }
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: active ? Config.onAccent : Config.dimmedColor
                }
            }
            
            // Name
            Text {
                text: ssid
                font.family: Config.fontFamily
                font.pixelSize: 13
                font.weight: active ? Font.Medium : Font.Normal
                color: Config.foregroundColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            // Security indicator
            Text {
                visible: security && security !== "--"
                text: "lock"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 14
                color: Config.dimmedColor
            }
            
            // Status or connect button
            Rectangle {
                visible: active
                width: statusText.implicitWidth + 16
                height: 24
                radius: 12
                color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                
                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: "Connected"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Config.accentColor
                }
            }
            
            Rectangle {
                visible: !active
                width: 70
                height: 28
                radius: 14
                color: connMouse.containsMouse ? Config.accentColor : Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                
                Behavior on color { ColorAnimation { duration: 120 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: connMouse.containsMouse ? Config.onAccent : Config.accentColor
                }
                
                MouseArea {
                    id: connMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiRoot.connectClicked()
                }
            }
        }
        
        MouseArea {
            id: wifiMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
    
    component SavedItem: Rectangle {
        id: savedRoot
        property string name: ""
        property string type: "wifi"
        property bool active: false
        
        signal deleteClicked()
        signal connectClicked()
        
        Layout.fillWidth: true
        height: 48
        radius: 8
        color: active ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1)
                      : (savedMouse.containsMouse ? Config.surfaceColorHover : "transparent")
        
        Behavior on color { ColorAnimation { duration: 100 } }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10
            
            Text {
                text: type === "ethernet" ? "lan" : "wifi"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: active ? Config.accentColor : Config.dimmedColor
            }
            
            Text {
                text: name
                font.family: Config.fontFamily
                font.pixelSize: 12
                color: Config.foregroundColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            
            Text {
                visible: active
                text: "● Connected"
                font.family: Config.fontFamily
                font.pixelSize: 10
                color: Config.successColor
            }
            
            Rectangle {
                visible: !active
                width: 28
                height: 28
                radius: 6
                color: delMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.15) : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "delete"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: delMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                }
                
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: savedRoot.deleteClicked()
                }
            }
        }
        
        MouseArea {
            id: savedMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: !active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (!active) savedRoot.connectClicked()
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
            
            // Status Card
            Rectangle {
                Layout.fillWidth: true
                height: 80
                radius: 12
                color: NetworkHandler.connectionStatus === "connected" 
                       ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1)
                       : Config.surfaceColor
                border.width: 1
                border.color: NetworkHandler.connectionStatus === "connected" 
                              ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.3)
                              : Config.borderColor
                
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
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 22
                            color: NetworkHandler.connectionStatus === "connected" ? Config.onAccent : Config.dimmedColor
                        }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: NetworkHandler.connectionStatus === "connected" 
                                  ? NetworkHandler.currentSSID : "Not Connected"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: NetworkHandler.connectionStatus === "connected"
                                  ? NetworkHandler.ipAddress : "No network"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.dimmedColor
                        }
                    }
                    
                    Rectangle {
                        visible: NetworkHandler.connectionStatus === "connected"
                        width: 90
                        height: 32
                        radius: 16
                        color: discMouse.containsMouse ? Qt.rgba(1,0.3,0.3,0.15) : Qt.rgba(1,1,1,0.06)
                        
                        Behavior on color { ColorAnimation { duration: 100 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Disconnect"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
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
            
            // WiFi Toggle Section
            Section {
                title: "WIRELESS"
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        text: "wifi"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        color: NetworkHandler.wifiEnabled ? Config.accentColor : Config.dimmedColor
                    }
                    
                    Text {
                        text: "WiFi"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.foregroundColor
                        Layout.fillWidth: true
                    }
                    
                    Toggle {
                        checked: NetworkHandler.wifiEnabled
                        onToggled: (val) => NetworkHandler.toggleWifi(val)
                    }
                }
            }
            
            // Available Networks
            Section {
                visible: NetworkHandler.wifiEnabled && !NetworkHandler.showPasswordDialog
                title: "AVAILABLE NETWORKS"
                
                Repeater {
                    model: NetworkHandler.networkList
                    
                    WifiItem {
                        ssid: modelData.ssid
                        signal: modelData.signal
                        security: modelData.security
                        active: modelData.active
                        
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
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }
            }
            
            // Password Dialog
            Section {
                visible: NetworkHandler.showPasswordDialog
                title: "CONNECT TO " + NetworkHandler.selectedSSID
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 10
                    color: Qt.rgba(1,1,1,0.04)
                    border.width: pwdInput.activeFocus ? 2 : 1
                    border.color: pwdInput.activeFocus ? Config.accentColor : Config.borderColor
                    
                    TextInput {
                        id: pwdInput
                        anchors.fill: parent
                        anchors.margins: 14
                        color: Config.foregroundColor
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        echoMode: TextInput.Password
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        
                        Text {
                            visible: !parent.text
                            text: "Enter password..."
                            color: Config.dimmedColor
                            font: parent.font
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    
                    Item { Layout.fillWidth: true }
                    
                    Rectangle {
                        width: 80
                        height: 32
                        radius: 16
                        color: cancelMouse.containsMouse ? Config.surfaceColorHover : Qt.rgba(1,1,1,0.06)
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            color: Config.foregroundColor
                        }
                        
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkHandler.showPasswordDialog = false
                                pwdInput.text = ""
                            }
                        }
                    }
                    
                    Rectangle {
                        width: 80
                        height: 32
                        radius: 16
                        color: connPwdMouse.containsMouse ? Qt.lighter(Config.accentColor, 1.1) : Config.accentColor
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: Config.onAccent
                        }
                        
                        MouseArea {
                            id: connPwdMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkHandler.connectWithPassword(NetworkHandler.selectedSSID, pwdInput.text)
                        }
                    }
                }
            }
            
            // Saved Connections
            Section {
                title: "SAVED"
                
                Repeater {
                    model: NetworkHandler.savedConnections
                    
                    SavedItem {
                        name: modelData.name
                        type: modelData.type
                        active: modelData.active
                        
                        onDeleteClicked: NetworkHandler.deleteConnection(modelData.name)
                        onConnectClicked: NetworkHandler.connectNetwork(modelData.name)
                    }
                }
                
                Text {
                    visible: NetworkHandler.savedConnections.length === 0
                    text: "No saved connections"
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
