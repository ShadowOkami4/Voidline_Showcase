/*
 * ============================================================================
 *                               ABOUT PAGE
 * ============================================================================
 *
 * FILE: settings/AboutPage.qml
 * PURPOSE: Display information about Quickshell (version, credits)
 *
 * OVERVIEW:
 *   - Shows version, author, license, and relevant system information.
 *   - May include links to documentation and project resources.
 *
 * NOTE: This is informational only and does not change configuration.
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import "../misc"

Item {
    id: root
    
    FileDialog {
        id: profilePictureDialog
        title: "Select Profile Picture"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: Config.profilePicturePath = selectedFile.toString().replace("file://", "")
    }
    
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
    
    component InfoRow: RowLayout {
        property string label: ""
        property string value: ""
        property string icon: ""
        
        Layout.fillWidth: true
        height: 48
        spacing: 12
        
        Rectangle {
            width: 36
            height: 36
            radius: 10
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
            font.weight: Font.Medium
            color: value ? Config.foregroundColor : Config.dimmedColor
            Layout.fillWidth: true
            elide: Text.ElideRight
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
    
    // ========================================================================
    //                          MAIN LAYOUT
    // ========================================================================
    
    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.height + 48
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
            
            // ================================================================
            //                     USER PROFILE CARD
            // ================================================================
            
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 120
                radius: 16
                color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.1)
                border.width: 1
                border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.25)
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    // Avatar
                    Rectangle {
                        id: aboutAvatarContainer
                        width: 80
                        height: 80
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
                            id: aboutAvatarImage
                            anchors.fill: parent
                            source: Config.hasProfilePicture ? "file://" + Config.profilePicturePath : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: Config.hasProfilePicture
                            cache: false
                            asynchronous: true
                            sourceSize.width: 160
                            sourceSize.height: 160
                            
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                                maskSource: ShaderEffectSource {
                                    sourceItem: Rectangle {
                                        width: aboutAvatarImage.width
                                        height: aboutAvatarImage.height
                                        radius: width / 2
                                        color: "white"
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 40
                            color: "transparent"
                            border.width: 3
                            border.color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.4)
                        }
                        
                        // Hover overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: 40
                            color: Qt.rgba(0,0,0,0.6)
                            opacity: avatarMouse.containsMouse ? 1 : 0
                            
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "photo_camera"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 26
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
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Text {
                            text: SystemInfoHandler.username || "User"
                            font.family: Config.fontFamily
                            font.pixelSize: 22
                            font.weight: Font.Bold
                            color: Config.foregroundColor
                        }
                        
                        RowLayout {
                            spacing: 8
                            
                            Rectangle {
                                width: hostTag.width + 16
                                height: 26
                                radius: 13
                                color: Qt.rgba(1,1,1,0.08)
                                
                                Text {
                                    id: hostTag
                                    anchors.centerIn: parent
                                    text: SystemInfoHandler.hostname || "unknown"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                }
                            }
                            
                            Rectangle {
                                width: sessionTag.width + 16
                                height: 26
                                radius: 13
                                color: Qt.rgba(1,1,1,0.08)
                                
                                Text {
                                    id: sessionTag
                                    anchors.centerIn: parent
                                    text: SystemInfoHandler.sessionType || "unknown"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                }
                            }
                        }
                    }
                    
                    // Change Photo Button
                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: changeRow.width + 20
                        height: 40
                        radius: 20
                        color: changeMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        RowLayout {
                            id: changeRow
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                text: "photo_camera"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                color: Config.dimmedColor
                            }
                            
                            Text {
                                text: Config.hasProfilePicture ? "Change" : "Add Photo"
                                font.family: Config.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: Config.dimmedColor
                            }
                        }
                        
                        MouseArea {
                            id: changeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: profilePictureDialog.open()
                        }
                    }
                    
                    // Refresh Button
                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        width: 40
                        height: 40
                        radius: 20
                        color: refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text {
                            anchors.centerIn: parent
                            text: "refresh"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Config.dimmedColor
                        }
                        
                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemInfoHandler.refresh()
                        }
                    }
                }
            }
            
            // ================================================================
            //                     SYSTEM CARD
            // ================================================================
            
            MD3Card {
                title: "System"
                icon: "computer"
                accentColor: Config.accentColor
                
                InfoRow {
                    label: "OS"
                    value: SystemInfoHandler.distro + " " + SystemInfoHandler.architecture
                    icon: "deployed_code"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "Kernel"
                    value: SystemInfoHandler.kernel
                    icon: "memory"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "Uptime"
                    value: SystemInfoHandler.uptime
                    icon: "schedule"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "Shell"
                    value: SystemInfoHandler.shell
                    icon: "terminal"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "Desktop"
                    value: SystemInfoHandler.sessionType + (SystemInfoHandler.hyprVersion ? " (Hyprland " + SystemInfoHandler.hyprVersion + ")" : "")
                    icon: "desktop_windows"
                }
            }
            
            // ================================================================
            //                     HARDWARE CARD
            // ================================================================
            
            MD3Card {
                title: "Hardware"
                icon: "developer_board"
                accentColor: Config.accentColor
                
                InfoRow {
                    label: "CPU"
                    value: SystemInfoHandler.cpu
                    icon: "memory"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "GPU"
                    value: SystemInfoHandler.gpu
                    icon: "monitor"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "Memory"
                    value: SystemInfoHandler.memoryUsed + " / " + SystemInfoHandler.memoryTotal
                    icon: "memory_alt"
                }
                
                Rectangle { Layout.fillWidth: true; height: 1; color: Config.outlineVariant; Layout.leftMargin: 48 }
                
                InfoRow {
                    label: "Disk"
                    value: SystemInfoHandler.storageUsed + " / " + SystemInfoHandler.storageTotal
                    icon: "hard_drive"
                }
            }
            
            // ================================================================
            //                     QUICKSHELL CARD
            // ================================================================
            
            MD3Card {
                title: "Quickshell"
                icon: "code"
                accentColor: Config.accentColor
                
                InfoRow {
                    label: "Version"
                    value: SystemInfoHandler.quickshellVersion
                    icon: "tag"
                }
            }
            
            Item { height: 24 }
        }
    }
}
