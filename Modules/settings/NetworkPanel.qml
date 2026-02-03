/*
* ============================================================================
* NETWORK PANEL
* ============================================================================
*
* FILE: panels/NetworkPanel.qml
* PURPOSE: WiFi network selection and connection panel
*
* ============================================================================
* OVERVIEW
* ============================================================================
*
* This panel provides network controls:
* - Current connection status display
* - WiFi on/off toggle
* - Available network list
* - Password entry for secured networks
* - Quick access to full Network settings
*
* Uses NetworkHandler singleton for all network operations via nmcli.
*
* ============================================================================
* UI STATES
* ============================================================================
*
* 1. NORMAL VIEW:
* - Shows current connection status
* - Lists available WiFi networks
* - WiFi toggle switch
*
* 2. PASSWORD DIALOG:
* - Triggered when connecting to secured network
* - Password input field
* - Connect/Cancel buttons
*
* State is managed via NetworkHandler.showPasswordDialog
*
* ============================================================================
* NETWORK ICONS
* ============================================================================
*
* Common network icons (Material Symbols):
* wifi <- WiFi connected
* wifi_off <- WiFi disabled
* signal_wifi_0_bar <- Very weak signal
* signal_wifi_4_bar <- Full signal
* wifi_password <- Secured network
* ethernet <- Wired connection
* language <- Internet/connected
* signal_cellular_* <- Mobile data icons
*
* ============================================================================
*/

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../misc"
import "../../Handlers"

/*
* ============================================================================
* POPUP WINDOW
* ============================================================================
*/
PopupWindow {
    id: networkPanel

    property var parentBar

    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.networkPanelVisible
        property bool isClosing: false

            anchor.window: parentBar
            anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
            anchor.rect.y: Config.barHeight + Config.topMargin + 8

            implicitWidth: 360
            implicitHeight: Math.min(480, contentCol.implicitHeight + 32)

            // Stay visible during close animation
            visible: isOpen || isClosing
            color: "transparent"

            onIsOpenChanged: {
                if (!isOpen)
                {
                    isClosing = true
                    closeTimer.start()
                }
            }

            // Timer to hide after close animation
            Timer {
                id: closeTimer
                interval: Config.animSpring
                onTriggered: networkPanel.isClosing = false
            }

            // UI state - use handler properties for dialog
            property bool showPasswordDialog: NetworkHandler.showPasswordDialog

                // Focus grab
                HyprlandFocusGrab {
                    active: networkPanel.visible
                    windows: [networkPanel]
                    onCleared: ShellState.networkPanelVisible = false
                }

                // Refresh on visibility
                onVisibleChanged: {
                    if (visible)
                    {
                        NetworkHandler.refresh()
                    } else {
                    NetworkHandler.showPasswordDialog = false
                }
            }

            // Periodic refresh
            Timer {
                interval: 10000
                running: networkPanel.visible && !networkPanel.showPasswordDialog
                repeat: true
                onTriggered: NetworkHandler.refresh()
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

                opacity: networkPanel.isOpen ? 1 : 0
                scale: networkPanel.isOpen ? 1 : 0.9
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

            // Main content
            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: Config.padding
                spacing: Config.spacingLarge
                visible: !networkPanel.showPasswordDialog

                // Header (matches BluetoothPanel design)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacingLarge

                    Rectangle {
                        width: 48
                        height: 48
                        radius: Config.cardRadius
                        color: NetworkHandler.connectionStatus === "connected" ? Config.accentColorContainer : Config.surfaceColorActive

                        Behavior on color { ColorAnimation { duration: Config.animNormal } }

                        Text {
                            anchors.centerIn: parent
                            text: NetworkHandler.connectionType === "ethernet" ? "lan" :
                            (NetworkHandler.connectionStatus === "connected" ? "wifi" : "wifi_off")
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: Config.iconSizeLarge
                            color: NetworkHandler.connectionStatus === "connected" ? Config.accentColor : Config.dimmedColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Network"
                            font.pixelSize: Config.fontSizeTitle
                            font.weight: Config.fontWeightMedium
                            font.family: Config.fontFamily
                            color: Config.foregroundColor
                        }

                        Text {
                            text: NetworkHandler.connectionStatus === "connected" ? NetworkHandler.currentSSID : "Disconnected"
                            font.pixelSize: Config.fontSizeSmall
                            font.family: Config.fontFamily
                            color: Config.dimmedColor
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Connection status indicator
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: NetworkHandler.connectionStatus === "connected" ? Config.successColor : Config.errorColor

                        Behavior on color { ColorAnimation { duration: Config.animNormal } }
                    }
                }

                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Config.borderColor
                }

                // Current connection card (when connected)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: Config.cardRadius
                    color: Config.surfaceColor
                    visible: NetworkHandler.connectionStatus === "connected"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: Config.smallRadius
                            color: Config.accentColor

                            Text {
                                anchors.centerIn: parent
                                text: "check"
                                color: Config.onAccent
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSize
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: NetworkHandler.currentSSID
                                color: Config.foregroundColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeBody
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: NetworkHandler.connectionType === "ethernet" ? "Ethernet" : "WiFi - Connected"
                                color: Config.dimmedColor
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSizeSmall
                            }
                        }

                        Rectangle {
                            visible: NetworkHandler.connectionStatus === "connected"
                            width: 40
                            height: 40
                            radius: Config.smallRadius
                            color: discMouse.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.2) : Config.surfaceColor

                            Behavior on color { ColorAnimation { duration: Config.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: "link_off"
                                color: discMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSize
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

                // Networks section
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Networks"
                        color: Config.dimmedColor
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: Config.smallRadius
                        color: refreshMouse.containsMouse ? Config.surfaceColorHover : "transparent"

                        Behavior on color { ColorAnimation { duration: Config.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "refresh"
                            color: Config.dimmedColor
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: Config.iconSize
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NetworkHandler.refresh()
                        }
                    }
                }

                // Network list
                ListView {
                    id: netListView
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(220, contentHeight)
                    clip: true
                    spacing: 4
                    model: NetworkHandler.networkList

                    delegate: Rectangle {
                        width: netListView.width
                        height: 56
                        radius: Config.cardRadius
                        color: modelData.active ? Config.accentColorContainer: (itemMouse.containsMouse ? Config.surfaceColorHover : "transparent")
                        border.width: modelData.active ? 1 : 0ig.surfaceColorHover : "transparent")
                        border.color: Config.accentColorDim: 0
border.color: Config.accentColorDim
                        Behavior on color { ColorAnimation { duration: Config.animFast } }
Behavior on color { ColorAnimation { duration: Config.animFast } }
                        required property var modelData
                        required property int indexData
required property int index
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12t
                            spacing: 12gins: 12
spacing: 12
                            Text {
                                text: {
                                    let s = modelData.signal
                                    if (s >= 70) return "signal_wifi_4_bar"
                                    if (s >= 50) return "network_wifi_3_bar"
                                    if (s >= 30) return "network_wifi_2_bar"
                                    return "network_wifi_1_bar"k_wifi_2_bar"
                                }   return "network_wifi_1_bar"
                                color: modelData.active ? Config.accentColor : Config.foregroundColor
                                font.family: "Material Symbols Outlined"olor : Config.foregroundColor
                                font.pixelSize: Config.iconSizeLargened"
                            }   font.pixelSize: Config.iconSizeLarge
}
                            Text {
                                Layout.fillWidth: true
                                text: modelData.ssidue
                                color: modelData.active ? Config.accentColor : Config.foregroundColor
                                font.family: Config.fontFamilyig.accentColor : Config.foregroundColor
                                font.pixelSize: Config.fontSizeBody
                                elide: Text.ElideRight.fontSizeBody
                            }   elide: Text.ElideRight
}
                            Text {
                                visible: modelData.security && modelData.security !== "--"
                                text: "lock"elData.security && modelData.security !== "--"
                                color: Config.dimmedColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSizeOutlined"
                            }   font.pixelSize: Config.iconSize
}
                            Text {
                                visible: modelData.active
                                text: "check"lData.active
                                color: Config.accentColor
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: Config.iconSizeOutlined"
                            }   font.pixelSize: Config.iconSize
                        }   }
}
                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: truent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Qt.PointingHandCursor
                                if (!modelData.active)
                                {
                                    NetworkHandler.selectedSSID = modelData.ssid
                                    NetworkHandler.selectedSecurity = modelData.security
                                    NetworkHandler.connectNetwork(modelData.ssid)ecurity
                                }   NetworkHandler.connectNetwork(modelData.ssid)
                            }   }
                        }   }
                    }   }
                }   }
}
                // Settings
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: Config.cardRadius0
                    color: settingsMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
color: settingsMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                    Behavior on color { ColorAnimation { duration: Config.animFast } }
Behavior on color { ColorAnimation { duration: Config.animFast } }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Config.spacingt
spacing: Config.spacing
                        Text {
                            text: "tune"
                            color: settingsMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                            font.family: "Material Symbols Outlined"fig.foregroundColor : Config.dimmedColor
                            font.pixelSize: Config.iconSizeOutlined"
font.pixelSize: Config.iconSize
                            Behavior on color { ColorAnimation { duration: Config.animFast } }
                        }   Behavior on color { ColorAnimation { duration: Config.animFast } }
}
                        Text {
                            text: "Network Settings"
                            color: settingsMouse.containsMouse ? Config.foregroundColor : Config.dimmedColor
                            font.family: Config.fontFamilyouse ? Config.foregroundColor : Config.dimmedColor
                            font.pixelSize: Config.fontSizeBody
                            font.weight: Font.MediumontSizeBody
font.weight: Font.Medium
                            Behavior on color { ColorAnimation { duration: Config.animFast } }
                        }   Behavior on color { ColorAnimation { duration: Config.animFast } }
                    }   }
}
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: truent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Qt.PointingHandCursor
                            ShellState.networkPanelVisible = false
                            ShellState.openSettings("network")alse
                        }   ShellState.openSettings("network")
                    }   }
                }   }
            }   }
}
            // Password dialog
            ColumnLayout {alog
                anchors.fill: parent
                anchors.margins: Config.spacingLarge
                spacing: Config.spacingLargeingLarge
                visible: networkPanel.showPasswordDialog
visible: networkPanel.showPasswordDialog
                RowLayout {
                    spacing: 12
spacing: 12
                    Rectangle {
                        width: 40
                        height: 40
                        radius: Config.xsRadius
                        color: backMouse.containsMouse ? Config.surfaceColorHover : "transparent"
color: backMouse.containsMouse ? Config.surfaceColorHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Config.animFast } }
Behavior on color { ColorAnimation { duration: Config.animFast } }
                        Text {
                            anchors.centerIn: parent
                            text: "arrow_back"parent
                            color: Config.foregroundColor
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: Config.iconSizeLargened"
                        }   font.pixelSize: Config.iconSizeLarge
}
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: truent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { Qt.PointingHandCursor
                                NetworkHandler.showPasswordDialog = false
                                passwordInput.text = ""wordDialog = false
                            }   passwordInput.text = ""
                        }   }
                    }   }
}
                    Text {
                        text: NetworkHandler.selectedSSID
                        color: Config.foregroundColorSSID
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeTitle
                        font.weight: Font.DemiBoldtSizeTitle
                    }   font.weight: Font.DemiBold
                }   }
}
                Item { Layout.fillHeight: true }
Item { Layout.fillHeight: true }
                Text {
                    text: "Enter network password"
                    color: Config.dimmedColorword"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSizeBody
                    Layout.alignment: Qt.AlignHCenterdy
                }   Layout.alignment: Qt.AlignHCenter
}
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: Config.cardRadius6
                    color: Config.surfaceColor
                    border.width: passwordInput.activeFocus ? 2 : 1
                    border.color: passwordInput.activeFocus ? Config.accentColor : Config.borderColor
border.color: passwordInput.activeFocus ? Config.accentColor : Config.borderColor
                    Behavior on border.color { ColorAnimation { duration: Config.animFast } }
Behavior on border.color { ColorAnimation { duration: Config.animFast } }
                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.margins: Config.spacingLarge
                        color: Config.foregroundColorngLarge
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeBody
                        echoMode: TextInput.PasswordizeBody
                        verticalAlignment: Text.AlignVCenter
verticalAlignment: Text.AlignVCenter
                        Text {
                            visible: !parent.text
                            text: "Password".text
                            color: Config.dimmedColor
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSizeBody
                            anchors.verticalCenter: parent.verticalCenter
                        }   anchors.verticalCenter: parent.verticalCenter
}
                        onAccepted: {
                            if (text)
                            {
                                NetworkHandler.connectWithPassword(NetworkHandler.selectedSSID, text)
                                text = ""ndler.connectWithPassword(NetworkHandler.selectedSSID, text)
                            }   text = ""
                        }   }
                    }   }
                }   }
}
                Item { Layout.fillHeight: true }
Item { Layout.fillHeight: true }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Config.cardRadius8
                    color: pwConnectMouse.containsMouse ? Config.accentColorHover : Config.accentColor
                    scale: pwConnectMouse.pressed ? 0.98 : 1nfig.accentColorHover : Config.accentColor
scale: pwConnectMouse.pressed ? 0.98 : 1
                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                    Behavior on scale { NumberAnimation { duration: Config.animFast; easing.type: Easing.OutQuart } }
Behavior on scale { NumberAnimation { duration: Config.animFast; easing.type: Easing.OutQuart } }
                    Text {
                        anchors.centerIn: parent
                        text: "Connect"n: parent
                        color: Config.onAccent
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSizeBody
                        font.weight: Font.DemiBoldtSizeBody
                    }   font.weight: Font.DemiBold
}
                    MouseArea {
                        id: pwConnectMouse
                        anchors.fill: parent
                        hoverEnabled: truent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { Qt.PointingHandCursor
                            if (passwordInput.text)
                            {
                                NetworkHandler.connectWithPassword(NetworkHandler.selectedSSID, passwordInput.text)
                                passwordInput.text = ""ithPassword(NetworkHandler.selectedSSID, passwordInput.text)
                            }   passwordInput.text = ""
                        }   }
                    }   }
                }   }
            }   }
        }   }
    }   }
}
