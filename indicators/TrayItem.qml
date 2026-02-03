/*
 * ============================================================================
 *                         SYSTEM TRAY COMPONENT
 * ============================================================================
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../misc"

Rectangle {
    id: trayItem
    
    required property SystemTrayItem modelData
    property var parentBar
    property bool menuOpen: false
    
    // Custom icon overrides for apps with broken tray icons
    readonly property var customIcons: ({
        "spotify": "image://icon/spotify",
        "spotify-client": "image://icon/spotify",
        "Spotify": "image://icon/spotify"
    })
    
    // Determine which icon source to use
    readonly property string iconSource: {
        let id = modelData.id ?? ""
        if (customIcons[id]) return customIcons[id]
        return modelData.icon ?? ""
    }
    
    width: 28
    height: 28
    radius: Config.xsRadius
    color: trayMouse.containsMouse || menuOpen ? Config.surfaceColorHover : "transparent"
    
    Behavior on color { ColorAnimation { duration: Config.animFast } }
    
    // Tray icon
    Image {
        id: trayIcon
        anchors.centerIn: parent
        width: 18
        height: 18
        sourceSize.width: 18
        sourceSize.height: 18
        source: trayItem.iconSource
        visible: source != "" && status === Image.Ready
        smooth: true
        mipmap: true
    }
    
    // Fallback icon (when tray icon fails to load or is missing)
    Text {
        anchors.centerIn: parent
        text: "apps"
        font.family: "Material Symbols Outlined"
        font.pixelSize: 16
        color: Config.foregroundColor
        visible: trayItem.iconSource === "" || trayIcon.status === Image.Error
    }
    
    // Menu data accessor
    QsMenuOpener {
        id: menuOpener
        menu: modelData.menu
    }
    
    // Popup menu
    PopupWindow {
        id: menuPopup
        
        anchor.window: trayItem.parentBar
        anchor.rect.x: trayItem.mapToItem(null, 0, 0).x + trayItem.width / 2 - 110
        anchor.rect.y: Config.barHeight + Config.topMargin + 6
        anchor.gravity: Edges.Bottom | Edges.Right
        
        implicitWidth: 220
        implicitHeight: menuBg.implicitHeight
        
        visible: trayItem.menuOpen
        color: "transparent"
        
        // Close menu when clicking outside
        onVisibleChanged: {
            if (visible) {
                closeTimer.stop()
            }
        }
        
        // Focus grab to close on outside click
        HyprlandFocusGrab {
            active: menuPopup.visible
            windows: [menuPopup, trayItem.parentBar]
            onCleared: {
                // Small delay to allow click to register
                closeTimer.start()
            }
        }
        
        Timer {
            id: closeTimer
            interval: 50
            onTriggered: trayItem.menuOpen = false
        }

        Rectangle {
            id: menuBg
            
            anchors.fill: parent
            implicitWidth: 220
            implicitHeight: Math.max(menuCol.implicitHeight + 16, 48)
            
            color: Config.backgroundColor
            border.width: 1
            border.color: Config.borderColor
            radius: Config.smallRadius
            
            // Loading state when no menu items yet
            Text {
                anchors.centerIn: parent
                text: "Loading..."
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                color: Config.dimmedColor
                visible: menuOpener.children.values.length === 0
            }
            
            Column {
                id: menuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 2
                visible: menuOpener.children.values.length > 0
                
                Repeater {
                    model: menuOpener.children
                    
                    delegate: Rectangle {
                        id: menuItemDel
                        
                        required property QsMenuEntry modelData
                        required property int index
                        
                        width: menuCol.width
                        height: modelData.isSeparator ? 9 : 36
                        radius: Config.xsRadius
                        color: !modelData.isSeparator && itemMouse.containsMouse && modelData.enabled 
                               ? Config.surfaceColorHover 
                               : "transparent"
                        
                        // Separator
                        Rectangle {
                            visible: menuItemDel.modelData.isSeparator
                            anchors.centerIn: parent
                            width: parent.width - 16
                            height: 1
                            color: Config.borderColor
                        }
                        
                        // Menu item row
                        RowLayout {
                            visible: !menuItemDel.modelData.isSeparator
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10
                            opacity: menuItemDel.modelData.enabled ? 1.0 : 0.5
                            
                            // Icon
                            Item {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                
                                IconImage {
                                    anchors.centerIn: parent
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    source: menuItemDel.modelData.icon ?? ""
                                    visible: source != "" && menuItemDel.modelData.buttonType === QsMenuButtonType.None
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: Config.foregroundColor
                                    visible: menuItemDel.modelData.buttonType === QsMenuButtonType.CheckBox
                                    text: menuItemDel.modelData.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: Config.foregroundColor
                                    visible: menuItemDel.modelData.buttonType === QsMenuButtonType.RadioButton
                                    text: menuItemDel.modelData.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
                                }
                            }
                            
                            // Label
                            Text {
                                Layout.fillWidth: true
                                text: (menuItemDel.modelData.text ?? "").replace(/_/g, "")
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize
                                color: Config.foregroundColor
                                elide: Text.ElideRight
                            }
                            
                            // Submenu arrow
                            Text {
                                visible: menuItemDel.modelData.hasChildren
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                color: Config.dimmedColor
                                text: "chevron_right"
                            }
                        }
                        
                        // Click handler
                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: false
                            cursorShape: !menuItemDel.modelData.isSeparator && menuItemDel.modelData.enabled 
                                         ? Qt.PointingHandCursor 
                                         : Qt.ArrowCursor
                            
                            onClicked: (mouse) => {
                                mouse.accepted = true
                                if (!menuItemDel.modelData.isSeparator && 
                                    menuItemDel.modelData.enabled && 
                                    !menuItemDel.modelData.hasChildren) {
                                    menuItemDel.modelData.triggered()
                                    closeTimer.stop()
                                    trayItem.menuOpen = false
                                }
                            }
                            
                            onPressed: (mouse) => {
                                mouse.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Tray icon click handler
    MouseArea {
        id: trayMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (modelData.onlyMenu && modelData.hasMenu) {
                    trayItem.menuOpen = !trayItem.menuOpen
                } else {
                    modelData.activate()
                }
            } else if (mouse.button === Qt.RightButton) {
                if (modelData.hasMenu) {
                    trayItem.menuOpen = !trayItem.menuOpen
                } else {
                    modelData.secondaryActivate()
                }
            } else if (mouse.button === Qt.MiddleButton) {
                modelData.secondaryActivate()
            }
        }
    }
    
    // Tooltip
    ToolTip {
        id: tooltip
        visible: trayMouse.containsMouse && !trayItem.menuOpen
        delay: 500
        text: (modelData.tooltipTitle ?? "") || (modelData.title ?? "") || (modelData.id ?? "Application")
        
        background: Rectangle {
            color: Config.backgroundColor
            border.width: 1
            border.color: Config.borderColor
            radius: Config.xsRadius
        }
        
        contentItem: Text {
            text: tooltip.text
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSizeSmall
            color: Config.foregroundColor
        }
    }
}
