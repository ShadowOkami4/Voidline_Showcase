import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import "../../misc"
import "../../Handlers"

Item {
    id: root
    
    FileDialog {
        id: profilePictureDialog
        title: "Select Profile Picture"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: Config.profilePicturePath = selectedFile.toString().replace("file://", "")
    }
    
    // ========================================================================
    //                              COMPONENTS
    // ========================================================================
    
    component Section: Rectangle {
        default property alias content: sectionContent.data
        property string title: ""
        
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + (title ? 56 : 32)
        radius: 12
        color: Config.surfaceColor
        
        Text {
            visible: title !== ""
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 16
            anchors.leftMargin: 16
            text: title
            font.family: Config.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.5
            color: Config.dimmedColor
            opacity: 0.7
        }
        
        ColumnLayout {
            id: sectionContent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: title ? 40 : 16
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            spacing: 4
        }
    }
    
    component InfoRow: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""
        property bool copyable: false
        
        Layout.fillWidth: true
        height: 44
        spacing: 12
        
        Rectangle {
            width: 32
            height: 32
            radius: 8
            color: Qt.rgba(1,1,1,0.06)
            visible: icon !== ""
            
            Text {
                anchors.centerIn: parent
                text: icon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 18
                color: Config.dimmedColor
            }
        }
        
        Text {
            text: label
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: Config.foregroundColor
            Layout.preferredWidth: 100
        }
        
        Text {
            text: value || "Loading..."
            font.family: Config.fontFamily
            font.pixelSize: 14
            color: value ? Config.dimmedColor : Qt.rgba(1,1,1,0.3)
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        
        Rectangle {
            visible: copyable && value
            width: 28
            height: 28
            radius: 6
            color: copyMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
            
            Text {
                anchors.centerIn: parent
                text: "content_copy"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: Config.dimmedColor
            }
            
            MouseArea {
                id: copyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Copy to clipboard would go here
                }
            }
        }
    }
    
    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 44
        height: 1
        color: Qt.rgba(1,1,1,0.06)
    }
    
    // ========================================================================
    //                              MAIN LAYOUT
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
            anchors.margins: 20
            spacing: 16
            
            // ================================================================
            //                        USER PROFILE
            // ================================================================
            
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 100
                radius: 16
                
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.2) }
                    GradientStop { position: 1.0; color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.05) }
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    
                    // Avatar
                    Rectangle {
                        id: avatarContainer
                        width: 68
                        height: 68
                        radius: 34
                        color: Config.accentColor
                        
                        Text {
                            anchors.centerIn: parent
                            text: SystemInfoHandler.username ? SystemInfoHandler.username.charAt(0).toUpperCase() : "?"
                            font.family: Config.fontFamily
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            color: Config.onAccent
                            visible: !Config.hasProfilePicture
                        }
                        
                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            source: Config.hasProfilePicture ? "file://" + Config.profilePicturePath : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: Config.hasProfilePicture
                            cache: false
                            asynchronous: true
                            sourceSize.width: 136
                            sourceSize.height: 136
                            
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
                                    }
                                }
                            }
                        }
                        
                        // Hover overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: 34
                            color: Qt.rgba(0,0,0,0.5)
                            opacity: avatarMouse.containsMouse ? 1 : 0
                            
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "photo_camera"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 22
                                color: "#FFFFFF"
                            }
                        }
                        
                        MouseArea {
                            id: avatarMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: profilePictureDialog.open()
                        }
                    }
                    
                    // User info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Text {
                            text: SystemInfoHandler.username || "User"
                            font.family: Config.fontFamily
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: Config.foregroundColor
                        }
                        
                        RowLayout {
                            spacing: 8
                            
                            Rectangle {
                                width: hostChip.width + 12
                                height: 22
                                radius: 11
                                color: Qt.rgba(1,1,1,0.08)
                                
                                Text {
                                    id: hostChip
                                    anchors.centerIn: parent
                                    text: SystemInfoHandler.hostname || "unknown"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.dimmedColor
                                }
                            }
                            
                            Rectangle {
                                width: sessionChip.width + 12
                                height: 22
                                radius: 11
                                color: Qt.rgba(1,1,1,0.08)
                                
                                Text {
                                    id: sessionChip
                                    anchors.centerIn: parent
                                    text: SystemInfoHandler.sessionType || "unknown"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 11
                                    color: Config.dimmedColor
                                }
                            }
                        }
                    }
                    
                    // Actions
                    RowLayout {
                        spacing: 8
                        
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: photoMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "photo_camera"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                color: Config.dimmedColor
                            }
                            
                            MouseArea {
                                id: photoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: profilePictureDialog.open()
                            }
                        }
                        
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                id: refreshIcon
                                anchors.centerIn: parent
                                text: "refresh"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                color: Config.dimmedColor
                                
                                RotationAnimation on rotation {
                                    id: refreshAnim
                                    from: 0
                                    to: 360
                                    duration: 600
                                    running: false
                                }
                            }
                            
                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    refreshAnim.start()
                                    SystemInfoHandler.refresh()
                                }
                            }
                        }
                    }
                }
            }
            
            // ================================================================
            //                           SYSTEM
            // ================================================================
            
            Section {
                title: "SYSTEM"
                
                InfoRow {
                    icon: "deployed_code"
                    label: "OS"
                    value: (SystemInfoHandler.distro || "") + " " + (SystemInfoHandler.architecture || "")
                }
                
                Divider {}
                
                InfoRow {
                    icon: "memory"
                    label: "Kernel"
                    value: SystemInfoHandler.kernel
                }
                
                Divider {}
                
                InfoRow {
                    icon: "schedule"
                    label: "Uptime"
                    value: SystemInfoHandler.uptime
                }
                
                Divider {}
                
                InfoRow {
                    icon: "terminal"
                    label: "Shell"
                    value: SystemInfoHandler.shell
                }
                
                Divider {}
                
                InfoRow {
                    icon: "desktop_windows"
                    label: "Desktop"
                    value: (SystemInfoHandler.sessionType || "") + (SystemInfoHandler.hyprVersion ? " (Hyprland " + SystemInfoHandler.hyprVersion + ")" : "")
                }
            }
            
            // ================================================================
            //                          HARDWARE
            // ================================================================
            
            Section {
                title: "HARDWARE"
                
                InfoRow {
                    icon: "memory"
                    label: "CPU"
                    value: SystemInfoHandler.cpu
                }
                
                Divider {}
                
                InfoRow {
                    icon: "monitor"
                    label: "GPU"
                    value: SystemInfoHandler.gpu
                }
                
                Divider {}
                
                InfoRow {
                    icon: "memory_alt"
                    label: "Memory"
                    value: (SystemInfoHandler.memoryUsed || "") + " / " + (SystemInfoHandler.memoryTotal || "")
                }
                
                Divider {}
                
                InfoRow {
                    icon: "hard_drive"
                    label: "Storage"
                    value: (SystemInfoHandler.storageUsed || "") + " / " + (SystemInfoHandler.storageTotal || "")
                }
            }
            
            // ================================================================
            //                         QUICKSHELL
            // ================================================================
            
            Section {
                title: "QUICKSHELL"
                
                InfoRow {
                    icon: "code"
                    label: "Version"
                    value: SystemInfoHandler.quickshellVersion
                }
                
                Divider {}
                
                InfoRow {
                    icon: "folder"
                    label: "Config"
                    value: "~/.config/quickshell/voidline"
                }
            }
            
            // ================================================================
            //                           CREDITS
            // ================================================================
            
            Section {
                title: "CREDITS"
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Text {
                        text: "Voidline"
                        font.family: Config.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Config.foregroundColor
                    }
                    
                    Text {
                        text: "Created by Okami"
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: Config.accentColor
                    }
                    
                    Text {
                        text: "A modern, customizable shell for Hyprland built with Quickshell and QML."
                        font.family: Config.fontFamily
                        font.pixelSize: 13
                        color: Config.dimmedColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 8
                        color: Qt.rgba(1, 0.8, 0, 0.1)
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Text {
                                text: "science"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                color: "#FFD54F"
                            }
                            
                            Text {
                                text: "Design Showcase • AI-Coded Prototype"
                                font.family: Config.fontFamily
                                font.pixelSize: 11
                                color: "#FFD54F"
                            }
                        }
                    }
                    
                    RowLayout {
                        spacing: 8
                        
                        Rectangle {
                            width: linkRow.width + 16
                            height: 32
                            radius: 8
                            color: linkMouse.containsMouse ? Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.2) : Qt.rgba(1,1,1,0.06)
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            RowLayout {
                                id: linkRow
                                anchors.centerIn: parent
                                spacing: 6
                                
                                Text {
                                    text: "open_in_new"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: Config.accentColor
                                }
                                
                                Text {
                                    text: "Quickshell Docs"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: Config.accentColor
                                }
                            }
                            
                            MouseArea {
                                id: linkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally("https://quickshell.outfoxxed.me/")
                            }
                        }
                    }
                }
            }
            
            Item { height: 16 }
        }
    }
}
