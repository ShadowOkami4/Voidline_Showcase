/*
* ============================================================================
* MEDIA PANEL
* ============================================================================
*
* FILE: Modules/media/MediaPanel.qml
* PURPOSE: Media controls popup with player info and controls
*
* ============================================================================
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland

import "../../misc"
import "../../Assets"
import "." as Media

PopupWindow {
    id: mediaPanel

    property var parentBar

    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.mediaPanelVisible
        property bool isClosing: false

            anchor.window: parentBar
            anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
            anchor.rect.y: Config.barHeight + Config.topMargin + 8

            implicitWidth: 360
            implicitHeight: wrapper.implicitHeight + Config.padding * 2

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
                onTriggered: mediaPanel.isClosing = false
            }

            // Focus grab
            HyprlandFocusGrab {
                active: mediaPanel.visible
                windows: [mediaPanel]
                onCleared: ShellState.mediaPanelVisible = false
            }

            // Main container
            Rectangle {
                id: container
                anchors.fill: parent
                radius: Config.panelRadius
                color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
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

                opacity: mediaPanel.isOpen ? 1 : 0
                scale: mediaPanel.isOpen ? 1 : 0.9
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

            // Content wrapper
            Media.Wrapper {
                id: wrapper
                anchors.centerIn: parent
                width: parent.width - Config.padding * 2
                shouldBeActive: mediaPanel.isOpen
            }
        }
    }