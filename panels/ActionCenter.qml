/*
 * ============================================================================
 *                          ACTION CENTER (REWORKED)
 * ============================================================================
 * 
 * FILE: panels/ActionCenter.qml
 * PURPOSE: Unified control center for Quick Settings and Notifications
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PopupWindow {
    id: actionCenter
    
    // ========================================================================
    //                         PROPERTIES & STATE
    // ========================================================================
    
    property var parentBar
    property bool isOpen: ShellState.actionCenterVisible
    property bool isClosing: false
    
    // Tab State: "controls" or "notifications"
    property string currentTab: "controls"
    
    // Helper to safely get current audio sink
    property var currentSink: {
        if (!SoundHandler.outputDevices || SoundHandler.outputDevices.length === 0) {
            return { name: "", description: "No Output", volume: 0, muted: false }
        }
        for (let i = 0; i < SoundHandler.outputDevices.length; i++) {
            if (SoundHandler.outputDevices[i].name === SoundHandler.defaultSink) {
                return SoundHandler.outputDevices[i]
            }
        }
        return SoundHandler.outputDevices[0] || { name: "", description: "Unknown", volume: 0, muted: false }
    }
    
    // ========================================================================
    //                         WINDOW CONFIG
    // ========================================================================
    
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) - implicitWidth - 12
    anchor.rect.y: Config.barHeight + Config.topMargin + 8
    
    implicitWidth: 400
    implicitHeight: 520
    
    visible: isOpen || isClosing
    color: "transparent"
    
    onIsOpenChanged: {
        if (!isOpen) {
            isClosing = true
            closeTimer.start()
        } else {
            // Refresh data on open
            SoundHandler.refresh()
            NetworkHandler.refresh()
            BluetoothHandler.refresh()
            currentTab = "controls" // Default to controls
        }
    }
    
    Timer {
        id: closeTimer
        interval: 300
        onTriggered: actionCenter.isClosing = false
    }
    
    HyprlandFocusGrab {
        active: actionCenter.visible
        windows: [actionCenter]
        onCleared: ShellState.actionCenterVisible = false
    }

    // Periodic refresh for sliders
    Timer {
        interval: 1000; running: actionCenter.visible; repeat: true
        onTriggered: { SoundHandler.refresh(); NetworkHandler.refresh(); }
    }
    
    // ========================================================================
    //                         MAIN CONTAINER
    // ========================================================================
    
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        
        // GLASS EFFECT
        color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
        border.width: 1
        border.color: Config.borderColor
        clip: true
        
        // ANIMATIONS
        opacity: actionCenter.isOpen ? 1 : 0
        scale: actionCenter.isOpen ? 1 : 0.95
        transformOrigin: Item.TopRight
        
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.0 } }
        
        // ====================================================================
        //                         CONTENT LAYOUT
        // ====================================================================
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.padding
            spacing: 16
            
            // ----------------------------------------------------------------
            //                         TAB SWITCHER
            // ----------------------------------------------------------------
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 22
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                // Sliding Highlight
                Rectangle {
                    width: parent.width / 2 - 4
                    height: parent.height - 8
                    anchors.verticalCenter: parent.verticalCenter
                    x: actionCenter.currentTab === "controls" ? 4 : parent.width / 2
                    radius: 18
                    color: Config.accentColor
                    
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    
                    // Controls Tab
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "toggle_on"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: actionCenter.currentTab === "controls" ? Config.onAccent : Config.dimmedColor
                            }
                            Text {
                                text: "Controls"
                                font.family: Config.fontFamily
                                font.weight: Font.DemiBold
                                color: actionCenter.currentTab === "controls" ? Config.onAccent : Config.dimmedColor
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: actionCenter.currentTab = "controls" }
                    }
                    
                    // Notifications Tab
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: "notifications"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: actionCenter.currentTab === "notifications" ? Config.onAccent : Config.dimmedColor
                            }
                            Text {
                                text: "Notifs"
                                font.family: Config.fontFamily
                                font.weight: Font.DemiBold
                                color: actionCenter.currentTab === "notifications" ? Config.onAccent : Config.dimmedColor
                            }
                            // Badge
                            Rectangle {
                                visible: NotificationHandler.count > 0
                                width: 16; height: 16; radius: 8
                                color: actionCenter.currentTab === "notifications" ? Config.surfaceColor : Config.accentColor
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.min(NotificationHandler.count, 9)
                                    font.pixelSize: 10; font.weight: Font.Bold
                                    color: actionCenter.currentTab === "notifications" ? Config.accentColor : Config.onAccent
                                }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: actionCenter.currentTab = "notifications" }
                    }
                }
            }
            
            // ----------------------------------------------------------------
            //                         CONTROLS VIEW
            // ----------------------------------------------------------------
            
            ColumnLayout {
                visible: actionCenter.currentTab === "controls"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16
                
                // --- BIG TOGGLES ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // WiFi
                    Rectangle {
                        id: wifiToggle
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: NetworkHandler.wifiEnabled ? 35 : 16
                        color: NetworkHandler.wifiEnabled ? Config.accentColor : Config.surfaceColor
                        border.width: 1
                        border.color: NetworkHandler.wifiEnabled ? Config.accentColor : Config.borderColor
                        
                        Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 3.5 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                        
                        scale: wifiMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 12
                            Text {
                                text: NetworkHandler.wifiEnabled ? "wifi" : "wifi_off"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 24
                                color: NetworkHandler.wifiEnabled ? Config.onAccent : Config.foregroundColor
                                
                                rotation: NetworkHandler.wifiEnabled ? 0 : -15
                                scale: NetworkHandler.wifiEnabled ? 1.2 : 1.0
                                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 4.0 } }
                                Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 3.0 } }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text {
                                    text: "WiFi"
                                    font.family: Config.fontFamily; font.weight: Font.Bold; font.pixelSize: 13
                                    color: NetworkHandler.wifiEnabled ? Config.onAccent : Config.foregroundColor
                                }
                                Text {
                                    text: NetworkHandler.connectionStatus === "connected" ? NetworkHandler.currentSSID : (NetworkHandler.wifiEnabled ? "On" : "Off")
                                    font.family: Config.fontFamily; font.pixelSize: 11
                                    color: NetworkHandler.wifiEnabled ? Qt.rgba(Config.onAccent.r, Config.onAccent.g, Config.onAccent.b, 0.8) : Config.dimmedColor
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                        }
                        MouseArea {
                            id: wifiMouse
                            anchors.fill: parent; onClicked: NetworkHandler.toggleWifi(!NetworkHandler.wifiEnabled)
                        }
                    }
                    
                    // Bluetooth
                    Rectangle {
                        id: btToggle
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: BluetoothHandler.powered ? 35 : 16
                        color: BluetoothHandler.powered ? Config.accentColor : Config.surfaceColor
                        border.width: 1
                        border.color: BluetoothHandler.powered ? Config.accentColor : Config.borderColor
                        
                        Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 3.5 } }
                        Behavior on color { ColorAnimation { duration: 300 } }
                        
                        scale: btMouse.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 12
                            Text {
                                text: "bluetooth"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 24
                                color: BluetoothHandler.powered ? Config.onAccent : Config.foregroundColor
                                
                                rotation: BluetoothHandler.powered ? 0 : 15
                                scale: BluetoothHandler.powered ? 1.2 : 1.0
                                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 4.0 } }
                                Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 3.0 } }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text {
                                    text: "Bluetooth"
                                    font.family: Config.fontFamily; font.weight: Font.Bold; font.pixelSize: 13
                                    color: BluetoothHandler.powered ? Config.onAccent : Config.foregroundColor
                                }
                                Text {
                                    text: BluetoothHandler.powered ? "On" : "Off"
                                    font.family: Config.fontFamily; font.pixelSize: 11
                                    color: BluetoothHandler.powered ? Qt.rgba(Config.onAccent.r, Config.onAccent.g, Config.onAccent.b, 0.8) : Config.dimmedColor
                                }
                            }
                        }
                        MouseArea {
                            id: btMouse
                            anchors.fill: parent
                            onClicked: BluetoothHandler.setPower(!BluetoothHandler.powered)
                        }
                    }
                }
                
                // --- SMALL TOGGLES ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    component SmallToggle: Rectangle {
                        id: sToggle
                        property string icon: ""
                        property bool active: false
                        signal clicked()
                        
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: active ? 25 : 14
                        color: active ? Config.accentColor : Config.surfaceColor
                        border.width: 1
                        border.color: active ? Config.accentColor : Config.borderColor
                        
                        Behavior on radius { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 3.0 } }
                        Behavior on color { ColorAnimation { duration: 250 } }
                        
                        scale: sToggleMouse.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: sToggle.icon
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 22
                            color: sToggle.active ? Config.onAccent : Config.foregroundColor
                            
                            rotation: sToggle.active ? 0 : -10
                            scale: sToggle.active ? 1.2 : 1.0
                            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 4.0 } }
                            Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 3.0 } }
                        }
                        MouseArea { id: sToggleMouse; anchors.fill: parent; onClicked: sToggle.clicked() }
                    }
                    
                    SmallToggle {
                        icon: NotificationHandler.doNotDisturb ? "do_not_disturb_on" : "do_not_disturb_off"
                        active: NotificationHandler.doNotDisturb
                        onClicked: NotificationHandler.toggleDnd()
                    }
                    
                    SmallToggle {
                        icon: "dark_mode"
                        active: false // Placeholder for theme toggle
                        onClicked: {} 
                    }
                    
                    SmallToggle {
                        icon: "mic"
                        active: true // Placeholder
                        onClicked: {}
                    }
                }
                
                // --- SLIDERS ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // Volume
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 14
                        color: Config.surfaceColor
                        border.width: 1
                        border.color: Config.borderColor
                        
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12
                            spacing: 12
                            
                            Text {
                                text: actionCenter.currentSink.muted ? "volume_off" : "volume_up"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: Config.foregroundColor
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: SoundHandler.toggleSinkMute(SoundHandler.defaultSink)
                                }
                            }
                            
                            // Slider Track (Expressive)
                            Rectangle {
                                id: sliderTrack
                                Layout.fillWidth: true
                                height: sliderMouse.pressed ? 16 : 6
                                radius: height / 2
                                color: Config.surfaceColorActive
                                border.width: 1
                                border.color: Qt.rgba(1,1,1,0.05)
                                
                                Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 3.0 } }
                                
                                Rectangle {
                                    id: volFill
                                    width: parent.width * Math.min(Math.max(actionCenter.currentSink.volume, 0) / 100, 1)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Config.accentColor
                                    
                                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    
                                    // Bouncy Handle (Knob)
                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: -width / 2
                                        width: 20; height: 20
                                        radius: 10
                                        color: Config.accentColor
                                        border.width: 3
                                        border.color: "#ffffff"
                                        
                                        scale: sliderMouse.pressed ? 1.4 : 0
                                        opacity: sliderMouse.pressed ? 1 : 0
                                        
                                        Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 4.0 } }
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }
                                }
                                
                                MouseArea {
                                    id: sliderMouse
                                    anchors.fill: parent; anchors.margins: -10
                                    onPressed: updateVol(mouse); onPositionChanged: updateVol(mouse)
                                    function updateVol(mouse) {
                                        let v = Math.max(0, Math.min(100, (mouse.x / width) * 100))
                                        SoundHandler.setSinkVolume(SoundHandler.defaultSink, v)
                                    }
                                }
                            }
                            
                            Text {
                                text: actionCenter.currentSink.volume + "%"
                                font.family: Config.fontFamily; font.pixelSize: 11
                                color: Config.dimmedColor
                                Layout.preferredWidth: 30
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true } // Spacer
            }
            
            // ----------------------------------------------------------------
            //                         NOTIFICATIONS VIEW
            // ----------------------------------------------------------------
            
            Item {
                visible: actionCenter.currentTab === "notifications"
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                // Clean All Button (Top Right)
                RowLayout {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    visible: NotificationHandler.count > 0
                    
                    Text {
                        text: "Clear All"
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.accentColor
                        MouseArea {
                            anchors.fill: parent
                            onClicked: NotificationHandler.clearAll()
                        }
                    }
                }
                
                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: NotificationHandler.count === 0
                    spacing: 10
                    Text {
                        text: "notifications_paused"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 48
                        color: Config.surfaceColorActive
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "No notifications"
                        font.family: Config.fontFamily
                        color: Config.dimmedColor
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
                
                // List
                ListView {
                    anchors.fill: parent
                    anchors.topMargin: 24
                    clip: true
                    model: NotificationHandler.notificationList
                    spacing: 10
                    
                    delegate: Rectangle {
                        required property var modelData
                        
                        width: ListView.view.width
                        height: notifContent.height + 24
                        radius: 12
                        color: Config.surfaceColor
                        border.width: 1
                        border.color: Config.borderColor
                        
                        RowLayout {
                            id: notifContent
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 12
                            spacing: 12
                            
                            // App Icon Placeholder
                            Rectangle {
                                width: 32; height: 32; radius: 8
                                color: Config.accentColorContainer
                                Text {
                                    anchors.centerIn: parent
                                    text: "info"
                                    font.family: "Material Symbols Rounded"
                                    color: Config.accentColor
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                RowLayout {
                                    Text {
                                        text: modelData.appName || "System"
                                        font.family: Config.fontFamily; font.weight: Font.Bold; font.pixelSize: 11
                                        color: Config.dimmedColor
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "close"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 14
                                        color: Config.dimmedColor
                                        MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }
                                    }
                                }
                                
                                Text {
                                    text: modelData.summary
                                    font.family: Config.fontFamily; font.weight: Font.DemiBold
                                    color: Config.foregroundColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.body
                                    font.family: Config.fontFamily; font.pixelSize: 12
                                    color: Config.dimmedColor
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
            
            // ----------------------------------------------------------------
            //                         FOOTER
            // ----------------------------------------------------------------
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: Config.surfaceColor
                border.width: 1
                border.color: Config.borderColor
                
                // Settings Button (Centered)
                Rectangle {
                    anchors.centerIn: parent
                    width: 120
                    height: 36
                    radius: 18
                    color: settingsMouse.containsMouse ? Config.surfaceColorHover : "transparent"
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "settings"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            color: Config.foregroundColor
                        }
                        
                        Text {
                            text: "Settings"
                            font.family: Config.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                    }
                    
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { 
                            ShellState.actionCenterVisible = false; 
                            ShellState.toggleSettingsPanel(); 
                        }
                    }
                }
            }
        }
    }
}
