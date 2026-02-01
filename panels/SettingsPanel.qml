/*
 * ============================================================================
 *                     SETTINGS PANEL - MATERIAL DESIGN 3
 * ============================================================================
 * 
 * A modern settings interface with:
 *   - Grid-based home screen with category cards
 *   - Smooth page transitions with back navigation
 *   - MD3 color roles and elevation system
 *   - Beautiful visual hierarchy
 * 
 * ============================================================================
 */

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"
import "../settings"

FloatingWindow {
    id: settingsWindow
    
    // Window identification for Hyprland window rules
    // Match with: windowrulev2 = ..., title:^(Settings)$
    title: "Settings"
    
    implicitWidth: 800
    implicitHeight: 600
    minimumSize: Qt.size(600, 500)
    
    visible: ShellState.settingsPanelVisible
    color: "transparent"
    
    // Navigation state
    property string currentPage: "home"
    property string pageTitle: "Settings"
    
    // Category definitions - all use dynamic accent color
    readonly property var categories: [
        { 
            id: "sound", 
            icon: "volume_up", 
            label: "Sound", 
            description: "Volume, devices & audio"
        },
        { 
            id: "bluetooth", 
            icon: "bluetooth", 
            label: "Bluetooth", 
            description: "Devices & connections"
        },
        { 
            id: "network", 
            icon: "wifi", 
            label: "Network", 
            description: "WiFi & connectivity"
        },
        { 
            id: "display", 
            icon: "desktop_windows", 
            label: "Display", 
            description: "Brightness & monitors"
        },
        { 
            id: "personalize", 
            icon: "palette", 
            label: "Personalize", 
            description: "Appearance & themes"
        },
        { 
            id: "about", 
            icon: "info", 
            label: "About", 
            description: "System information"
        }
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
                for (var i = 0; i < categories.length; i++) {
                    if (categories[i].id === ShellState.settingsInitialPage) {
                        settingsWindow.pageTitle = categories[i].label
                        break
                    }
                }
            } else {
                settingsWindow.currentPage = "home"
                settingsWindow.pageTitle = "Settings"
            }
            SoundHandler.refresh()
            NetworkHandler.refresh()
            DisplayHandler.refresh()
            BluetoothHandler.refresh()
            SystemInfoHandler.refresh()
        }
    }
    
    // Main container with background
    Rectangle {
        id: container
        anchors.fill: parent
        color: Config.backgroundColor
        radius: 0
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 0
            border.width: 0
            border.color: "transparent"
        }
        
        // Header
        Rectangle {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 72
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16
                
                // Back button
                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 22
                    color: backMouse.containsMouse ? Config.surfaceColorHover : "transparent"
                    visible: settingsWindow.currentPage !== "home"
                    opacity: visible ? 1 : 0
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        color: Config.foregroundColor
                    }
                    
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            settingsWindow.currentPage = "home"
                            settingsWindow.pageTitle = "Settings"
                        }
                    }
                }
                
                // Title
                Text {
                    text: settingsWindow.pageTitle
                    font.family: Config.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    color: Config.foregroundColor
                }
                
                Item { Layout.fillWidth: true }
                
                // Close button
                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 22
                    color: closeMouse.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : "transparent"
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
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
        
        // Separator
        Rectangle {
            id: headerSep
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            height: 1
            color: Config.outlineVariant
        }
        
        // Content area
        Item {
            id: contentArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: headerSep.bottom
            anchors.bottom: parent.bottom
            anchors.topMargin: 1
            clip: true
            
            // Home page with system info and categories
            Item {
                id: homePage
                anchors.fill: parent
                visible: opacity > 0
                opacity: settingsWindow.currentPage === "home" ? 1 : 0
                
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                
                Flickable {
                    anchors.fill: parent
                    contentHeight: homeContent.height + 48
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    
                    ColumnLayout {
                        id: homeContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 24
                        spacing: 24
                        
                        // ========================================================
                        //                   WELCOME CARD
                        // ========================================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            radius: Config.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15) }
                                GradientStop { position: 1.0; color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.05) }
                            }
                            border.width: 1
                            border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.25)
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 24
                                spacing: 20
                                
                                // User avatar
                                Rectangle {
                                    Layout.preferredWidth: 80
                                    Layout.preferredHeight: 80
                                    radius: 40
                                    color: Config.accentColor
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: SystemInfoHandler.username ? SystemInfoHandler.username.charAt(0).toUpperCase() : "?"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 32
                                        font.weight: Font.Bold
                                        color: Config.onAccent
                                        visible: !Config.hasProfilePicture
                                    }
                                    
                                    Image {
                                        id: avatarImage
                                        anchors.fill: parent
                                        anchors.margins: 0
                                        source: Config.hasProfilePicture ? "file://" + Config.profilePicturePath : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: Config.hasProfilePicture
                                        cache: false
                                        asynchronous: true
                                        sourceSize.width: 128
                                        sourceSize.height: 128
                                        
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskThresholdMin: 0.5
                                            maskSpreadAtMin: 1.0
                                            maskSource: ShaderEffectSource {
                                                sourceItem: Rectangle {
                                                    width: avatarImage.width
                                                    height: avatarImage.height
                                                    radius: width / 2
                                                    color: "white"
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Greeting and quick info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 8
                                    
                                    Text {
                                        text: {
                                            var hour = new Date().getHours()
                                            var greeting = hour < 12 ? "Good Morning" : hour < 18 ? "Good Afternoon" : "Good Evening"
                                            return greeting + ", " + (SystemInfoHandler.username || "User") + "!"
                                        }
                                        font.family: Config.fontFamily
                                        font.pixelSize: 22
                                        font.weight: Font.Medium
                                        color: Config.foregroundColor
                                    }
                                    
                                    RowLayout {
                                        spacing: 16
                                        
                                        // Hostname
                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: "computer"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 16
                                                color: Config.dimmedColor
                                            }
                                            Text {
                                                text: SystemInfoHandler.hostname || "localhost"
                                                font.family: Config.fontFamily
                                                font.pixelSize: 13
                                                color: Config.dimmedColor
                                            }
                                        }
                                        
                                        // Session type
                                        RowLayout {
                                            spacing: 6
                                            Text {
                                                text: "monitor"
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 16
                                                color: Config.dimmedColor
                                            }
                                            Text {
                                                text: SystemInfoHandler.sessionType || "wayland"
                                                font.family: Config.fontFamily
                                                font.pixelSize: 13
                                                color: Config.dimmedColor
                                            }
                                        }
                                    }
                                    
                                    Item { Layout.fillHeight: true }
                                    
                                    Text {
                                        text: "Uptime: " + (SystemInfoHandler.uptime || "Loading...")
                                        font.family: Config.fontFamily
                                        font.pixelSize: 12
                                        color: Config.dimmedColor
                                        opacity: 0.8
                                    }
                                }
                                
                                // Decorative icon
                                Text {
                                    text: "settings"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 64
                                    color: Config.accentColor
                                    opacity: 0.2
                                }
                            }
                        }
                        
                        // ========================================================
                        //                   QUICK STATS ROW
                        // ========================================================
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            
                            // CPU info
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                radius: Config.radius
                                color: Config.surfaceColor
                                border.width: 1
                                border.color: Config.borderColor
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 44
                                        radius: 12
                                        color: Qt.rgba(0.3, 0.7, 1.0, 0.15)
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "memory"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 22
                                            color: Qt.rgba(0.3, 0.7, 1.0, 1.0)
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: "CPU"
                                            font.family: Config.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: Config.dimmedColor
                                            opacity: 0.8
                                        }
                                        Text {
                                            text: SystemInfoHandler.cpu ? SystemInfoHandler.cpu.split(" ").slice(0, 3).join(" ") : "Loading..."
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Config.foregroundColor
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                            
                            // Memory info
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                radius: Config.radius
                                color: Config.surfaceColor
                                border.width: 1
                                border.color: Config.borderColor
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 44
                                        radius: 12
                                        color: Qt.rgba(0.5, 0.8, 0.4, 0.15)
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "developer_board"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 22
                                            color: Qt.rgba(0.5, 0.8, 0.4, 1.0)
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: "Memory"
                                            font.family: Config.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: Config.dimmedColor
                                            opacity: 0.8
                                        }
                                        Text {
                                            text: SystemInfoHandler.memoryUsed && SystemInfoHandler.memoryTotal ? 
                                                  SystemInfoHandler.memoryUsed + " / " + SystemInfoHandler.memoryTotal : "Loading..."
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Config.foregroundColor
                                        }
                                    }
                                }
                            }
                            
                            // Storage info
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                radius: Config.radius
                                color: Config.surfaceColor
                                border.width: 1
                                border.color: Config.borderColor
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12
                                    
                                    Rectangle {
                                        Layout.preferredWidth: 44
                                        Layout.preferredHeight: 44
                                        radius: 12
                                        color: Qt.rgba(1.0, 0.6, 0.3, 0.15)
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "hard_drive"
                                            font.family: "Material Symbols Rounded"
                                            font.pixelSize: 22
                                            color: Qt.rgba(1.0, 0.6, 0.3, 1.0)
                                        }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Text {
                                            text: "Storage"
                                            font.family: Config.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: Config.dimmedColor
                                            opacity: 0.8
                                        }
                                        Text {
                                            text: SystemInfoHandler.storageUsed && SystemInfoHandler.storageTotal ? 
                                                  SystemInfoHandler.storageUsed + " / " + SystemInfoHandler.storageTotal : "Loading..."
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Medium
                                            color: Config.foregroundColor
                                        }
                                    }
                                }
                            }
                        }
                        
                        // ========================================================
                        //                   CATEGORIES HEADER
                        // ========================================================
                        Text {
                            text: "Categories"
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Config.dimmedColor
                            Layout.topMargin: 8
                        }
                        
                        // ========================================================
                        //                   CATEGORY GRID
                        // ========================================================
                        GridLayout {
                            id: homeGrid
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 16
                            rowSpacing: 16
                            
                            Repeater {
                                model: settingsWindow.categories
                                
                                Rectangle {
                                    id: categoryCard
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 120
                                    radius: Config.radius
                                    color: cardMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                                    border.width: 1
                                    border.color: cardMouse.containsMouse ? Config.outlineVariant : Config.borderColor
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    
                                    // Left accent bar (inset to avoid corner issues)
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.leftMargin: 8
                                        anchors.topMargin: 12
                                        anchors.bottomMargin: 12
                                        width: 4
                                        radius: 2
                                        color: Config.accentColor
                                        opacity: cardMouse.containsMouse ? 1 : 0.6
                                        
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                    
                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 16
                                        anchors.leftMargin: 24
                                        spacing: 8
                                        
                                        Rectangle {
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 40
                                            radius: 12
                                            color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15)
                                            
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 22
                                                color: Config.accentColor
                                            }
                                        }
                                        
                                        Item { Layout.fillHeight: true }
                                        
                                        Text {
                                            text: modelData.label
                                            font.family: Config.fontFamily
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: Config.foregroundColor
                                        }
                                        
                                        Text {
                                            text: modelData.description
                                            font.family: Config.fontFamily
                                            font.pixelSize: 11
                                            color: Config.dimmedColor
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                    
                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: 12
                                        text: "chevron_right"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 20
                                        color: Config.dimmedColor
                                        opacity: cardMouse.containsMouse ? 1 : 0.5
                                        
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                    
                                    MouseArea {
                                        id: cardMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            settingsWindow.currentPage = modelData.id
                                            settingsWindow.pageTitle = modelData.label
                                        }
                                    }
                                }
                            }
                        }
                        
                        // ========================================================
                        //                   SYSTEM INFO FOOTER
                        // ========================================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            Layout.topMargin: 8
                            radius: Config.radius
                            color: Qt.rgba(Config.surfaceColor.r, Config.surfaceColor.g, Config.surfaceColor.b, 0.5)
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16
                                
                                Text {
                                    text: SystemInfoHandler.distro + " " + SystemInfoHandler.architecture
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                    opacity: 0.8
                                }
                                
                                Rectangle {
                                    width: 1
                                    height: 16
                                    color: Config.borderColor
                                }
                                
                                Text {
                                    text: "Kernel " + SystemInfoHandler.kernel
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                    opacity: 0.8
                                }
                                
                                Rectangle {
                                    width: 1
                                    height: 16
                                    color: Config.borderColor
                                }
                                
                                Text {
                                    text: SystemInfoHandler.hyprVersion ? "Hyprland " + SystemInfoHandler.hyprVersion : ""
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                    opacity: 0.8
                                    visible: SystemInfoHandler.hyprVersion !== ""
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Text {
                                    text: SystemInfoHandler.gpu ? SystemInfoHandler.gpu.split(" ").slice(0, 4).join(" ") : ""
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                    opacity: 0.8
                                    visible: SystemInfoHandler.gpu !== ""
                                }
                            }
                        }
                        
                        // ========================================================
                        //                   CREATOR INFO
                        // ========================================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            Layout.topMargin: 8
                            radius: Config.radius
                            color: "transparent"
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8
                                    
                                    Text {
                                        text: "favorite"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 16
                                        color: Config.accentColor
                                    }
                                    
                                    Text {
                                        text: "Made with love by Okami"
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        color: Config.dimmedColor
                                    }
                                }
                                
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "•VoidLine•"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.dimmedColor
                                    opacity: 0.6
                                }
                            }
                        }
                    }
                }
            }
            
            SoundPage {
                anchors.fill: parent
                visible: opacity > 0
                opacity: settingsWindow.currentPage === "sound" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            
            BluetoothPage {
                anchors.fill: parent
                visible: opacity > 0
                opacity: settingsWindow.currentPage === "bluetooth" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            
            NetworkPage {
                anchors.fill: parent
                visible: opacity > 0
                opacity: settingsWindow.currentPage === "network" ? 1 : 0
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
