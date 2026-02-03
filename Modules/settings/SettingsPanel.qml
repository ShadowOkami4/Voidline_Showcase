/*
 * ============================================================================
 *                        SETTINGS PANEL - NEW DESIGN
 * ============================================================================
 * 
 * A modern, clean settings interface with:
 *   - Persistent sidebar navigation
 *   - Smooth page transitions
 *   - Minimalist aesthetic
 *   - Glassmorphism effects
 * 
 * ============================================================================
 */

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../../misc"
import "../../Handlers"
import "../../Apps/Settings"

FloatingWindow {
    id: settingsWindow
    
    title: "Settings"
    
    implicitWidth: 900
    implicitHeight: 640
    minimumSize: Qt.size(700, 500)
    
    visible: ShellState.settingsPanelVisible
    color: "transparent"
    
    // Navigation state
    property string currentPage: "sound"
    
    // Navigation items
    readonly property var navItems: [
        { id: "sound", icon: "volume_up", label: "Sound" },
        { id: "network", icon: "wifi", label: "Network" },
        { id: "bluetooth", icon: "bluetooth", label: "Bluetooth" },
        { id: "display", icon: "desktop_windows", label: "Display" },
        { id: "personalize", icon: "palette", label: "Personalize" },
        { id: "about", icon: "info", label: "About" }
    ]
    
    // Refresh timers
    Timer {
        interval: 2000
        running: settingsWindow.visible && settingsWindow.currentPage === "sound"
        repeat: true
        onTriggered: SoundHandler.refresh()
    }
    
    Timer {
        interval: 5000
        running: settingsWindow.visible && settingsWindow.currentPage === "network"
        repeat: true
        onTriggered: NetworkHandler.refresh()
    }
    
    Timer {
        interval: 3000
        running: settingsWindow.visible && (settingsWindow.currentPage === "display" || settingsWindow.currentPage === "bluetooth")
        repeat: true
        onTriggered: {
            if (currentPage === "display") DisplayHandler.refresh()
            else BluetoothHandler.refresh()
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            if (ShellState.settingsInitialPage && ShellState.settingsInitialPage !== "") {
                settingsWindow.currentPage = ShellState.settingsInitialPage
            } else {
                settingsWindow.currentPage = "sound"
            }
            SoundHandler.refresh()
            NetworkHandler.refresh()
            DisplayHandler.refresh()
            BluetoothHandler.refresh()
            SystemInfoHandler.refresh()
        }
    }
    
    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        color: Config.backgroundColor
        radius: 16
        
        // Border
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
            border.width: 1
            border.color: Config.borderColor
        }
        
        // Layout: Sidebar + Content
        RowLayout {
            anchors.fill: parent
            spacing: 0
            
            // ================================================================
            //                         SIDEBAR
            // ================================================================
            Rectangle {
                id: sidebar
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Config.surfaceColor
                opacity: 0.85
                
                // Left border radius
                Rectangle {
                    anchors.fill: parent
                    color: Config.surfaceColor
                    radius: 16
                    
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.radius
                        color: parent.color
                    }
                }
                
                // Sidebar content
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    
                    // Header with user info
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 72
                        color: "transparent"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12
                            
                            // User avatar
                            Rectangle {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                radius: 22
                                color: Config.accentColor
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: SystemInfoHandler.username ? SystemInfoHandler.username.charAt(0).toUpperCase() : "?"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: Config.onAccent
                                    visible: !Config.hasProfilePicture
                                }
                                
                                Image {
                                    id: sidebarAvatar
                                    anchors.fill: parent
                                    source: Config.hasProfilePicture ? "file://" + Config.profilePicturePath : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: Config.hasProfilePicture
                                    cache: false
                                    asynchronous: true
                                    sourceSize: Qt.size(88, 88)
                                    
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskThresholdMin: 0.5
                                        maskSpreadAtMin: 1.0
                                        maskSource: ShaderEffectSource {
                                            sourceItem: Rectangle {
                                                width: sidebarAvatar.width
                                                height: sidebarAvatar.height
                                                radius: width / 2
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // User info
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Text {
                                    text: SystemInfoHandler.username || "User"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: Config.foregroundColor
                                }
                                
                                Text {
                                    text: SystemInfoHandler.hostname || "localhost"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.dimmedColor
                                }
                            }
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        height: 1
                        color: Config.borderColor
                    }
                    
                    // Navigation items
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.topMargin: 8
                            spacing: 4
                            
                            Repeater {
                                model: settingsWindow.navItems
                                
                                Rectangle {
                                    id: navItem
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    radius: 10
                                    color: settingsWindow.currentPage === modelData.id 
                                           ? Config.accentColor 
                                           : (navMouse.containsMouse ? Config.surfaceColorHover : "transparent")
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12
                                        
                                        Text {
                                            text: modelData.icon
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 20
                                            color: settingsWindow.currentPage === modelData.id 
                                                   ? Config.onAccent 
                                                   : Config.dimmedColor
                                        }
                                        
                                        Text {
                                            text: modelData.label
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: settingsWindow.currentPage === modelData.id ? Font.Medium : Font.Normal
                                            color: settingsWindow.currentPage === modelData.id 
                                                   ? Config.onAccent 
                                                   : Config.foregroundColor
                                            Layout.fillWidth: true
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsWindow.currentPage = modelData.id
                                    }
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                            
                            // Version info at bottom
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                color: "transparent"
                                
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "VoidLine v1.0"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 10
                                    color: Config.dimmedColor
                                    opacity: 0.6
                                }
                            }
                        }
                    }
                }
                
                // Right border
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Config.borderColor
                }
            }
            
            // ================================================================
            //                         CONTENT AREA
            // ================================================================
            Item {
                id: contentArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                // Header bar
                Rectangle {
                    id: contentHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 64
                    color: "transparent"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 16
                        spacing: 16
                        
                        // Page title
                        Text {
                            text: {
                                for (var i = 0; i < settingsWindow.navItems.length; i++) {
                                    if (settingsWindow.navItems[i].id === settingsWindow.currentPage) {
                                        return settingsWindow.navItems[i].label
                                    }
                                }
                                return "Settings"
                            }
                            font.family: Config.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.Medium
                            color: Config.foregroundColor
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        // Close button
                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 18
                            color: closeMouse.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : "transparent"
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                color: closeMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                            }
                            
                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellState.settingsPanelVisible = false
                            }
                        }
                    }
                }
                
                // Page content
                Item {
                    id: pageContainer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: contentHeader.bottom
                    anchors.bottom: parent.bottom
                    clip: true
                    
                    SoundPage {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: settingsWindow.currentPage === "sound" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    
                    NetworkPage {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: settingsWindow.currentPage === "network" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    
                    BluetoothPage {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: settingsWindow.currentPage === "bluetooth" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    
                    DisplayPage {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: settingsWindow.currentPage === "display" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    
                    PersonalizePage {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: settingsWindow.currentPage === "personalize" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                    
                    AboutPage {
                        anchors.fill: parent
                        visible: opacity > 0
                        opacity: settingsWindow.currentPage === "about" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
