/*
* ============================================================================
* TOP BAR
* ============================================================================
*
* FILE: Modules/Bar/Bar.qml
* PURPOSE: Full-width top bar with reverse rounded corners
*
* ============================================================================
*/

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

import "../../misc"
import "../../Handlers"
import "../../indicators"
import "../media"
import "../settings"
import "../.."

PanelWindow {
    id: bar

    // ========================================================================
    //                     EXPORTED PROPERTIES
    // ========================================================================

    // Height of the bar (exposed for panels to use)
    readonly property int barTotalHeight: Config.barHeight

        // Height including reverse corners
        readonly property int curveSize: Config.panelRadius

            // ========================================================================
            //                     AUTO-HIDE STATE
            // ========================================================================

            property bool barVisible: !Config.barAutoHide || triggerZone.containsMouse || barContentHover.hovered || anyPanelOpen
                property bool anyPanelOpen: ShellState.launcherVisible || ShellState.actionCenterVisible || ShellState.powerMenuVisible || ShellState.cheatsheetVisible

                    // ========================================================================
                    //                     POSITIONING & SIZING
                    // ========================================================================

                    anchors {
                        top: true
                        left: true
                        right: true
                    }

                    // Height for bar plus the curved corner extensions below
                    property int triggerZoneHeight: 4
                        implicitHeight: Config.barAutoHide
                        ? (barVisible ? (Config.barHeight + curveSize) : triggerZoneHeight)
                        : (Config.barHeight + curveSize)

                        color: "transparent"

                        // Exclusive zone reserves space for the bar so windows don't overlap
                        exclusionMode: ExclusionMode.Normal
                        exclusiveZone: Config.barAutoHide ? 0 : Config.barHeight

                        // ========================================================================
                        //                     HOVER DETECTION
                        // ========================================================================

                        MouseArea {
                            id: triggerZone
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            height: bar.barVisible ? bar.implicitHeight : bar.triggerZoneHeight
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                            z: -1
                        }

                        HoverHandler {
                            id: barContentHover
                        }

                        property alias barHover: barContentHover

                            // ========================================================================
                            //                     BAR CONTAINER
                            // ========================================================================

                            Item {
                                id: barContainer
                                anchors.fill: parent

                                opacity: bar.barVisible ? 1 : 0
                                y: bar.barVisible ? 0 : -height

                                Behavior on y {
                                NumberAnimation {
                                    duration: Config.animSlow
                                    easing.type: Easing.OutQuart
                                }
                            }

                            Behavior on opacity {
                            NumberAnimation {
                                duration: Config.animNormal
                                easing.type: Easing.OutQuart
                            }
                        }

                        // Main bar background
                        Rectangle {
                            id: barBackground
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }
                            height: Config.barHeight
                            color: Config.backgroundColor
                        }

                        // ====================================================================
                        //         REVERSE ROUNDED CORNERS (using Canvas)
                        // ====================================================================

                        Canvas {
                            id: leftCorner
                            width: bar.curveSize
                            height: bar.curveSize
                            anchors {
                                top: barBackground.bottom
                                left: parent.left
                            }
                            antialiasing: true

                            property color bgColor: Config.backgroundColor
                                onBgColorChanged: requestPaint()

                                Component.onCompleted: requestPaint()
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.reset()

                                    var r = width

                                    ctx.fillStyle = bgColor
                                    ctx.fillRect(0, 0, r, r)

                                    ctx.globalCompositeOperation = "destination-out"
                                    ctx.beginPath()
                                    ctx.arc(r, r, r, Math.PI, 1.5 * Math.PI, false)
                                    ctx.lineTo(r, r)
                                    ctx.closePath()
                                    ctx.fill()
                                }
                            }

                            Canvas {
                                id: rightCorner
                                width: bar.curveSize
                                height: bar.curveSize
                                anchors {
                                    top: barBackground.bottom
                                    right: parent.right
                                }
                                antialiasing: true

                                property color bgColor: Config.backgroundColor
                                    onBgColorChanged: requestPaint()

                                    Component.onCompleted: requestPaint()
                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.reset()

                                        var r = width

                                        ctx.fillStyle = bgColor
                                        ctx.fillRect(0, 0, r, r)

                                        ctx.globalCompositeOperation = "destination-out"
                                        ctx.beginPath()
                                        ctx.arc(0, r, r, 1.5 * Math.PI, 2 * Math.PI, false)
                                        ctx.lineTo(0, r)
                                        ctx.closePath()
                                        ctx.fill()
                                    }
                                }

                                // ====================================================================
                                //                     BAR CONTENT LAYOUT
                                // ====================================================================

                                RowLayout {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        leftMargin: 20 + bar.curveSize
                                        rightMargin: 20 + bar.curveSize
                                    }
                                    height: Config.barHeight
                                    spacing: 0

                                    // ----------------------------------------------------------------
                                    //                     LEFT SECTION - Clock + System Tray
                                    // ----------------------------------------------------------------
                                    Item {
                                        Layout.preferredWidth: parent.width / 3
                                        Layout.fillHeight: true

                                        RowLayout {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            ClockWidget {}

                                            Rectangle {
                                                width: 1
                                                height: 18
                                                color: Config.borderColor
                                                visible: SystemTray.items.length > 0
                                            }

                                            Row {
                                                id: trayRow
                                                spacing: 2

                                                Repeater {
                                                    model: SystemTray.items

                                                    TrayItem {
                                                        parentBar: bar
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ----------------------------------------------------------------
                                    //                     CENTER SECTION - Media + Launcher + Workspaces
                                    // ----------------------------------------------------------------
                                    Item {
                                        Layout.preferredWidth: parent.width / 3
                                        Layout.fillHeight: true

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: Config.spacing

                                            MediaControl {
                                                id: mediaControl
                                            }

                                            Rectangle {
                                                width: 1
                                                height: 18
                                                color: Config.borderColor
                                            }

                                            Rectangle {
                                                width: 36
                                                height: 36
                                                radius: Config.xsRadius
                                                color: launcherMouseArea.containsMouse ? Config.surfaceColorHover : "transparent"
                                                scale: launcherMouseArea.pressed ? 0.92 : 1.0

                                                Behavior on scale { NumberAnimation { duration: Config.animFast; easing.type: Easing.OutQuart } }
                                                Behavior on color { ColorAnimation { duration: Config.animFast } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "apps"
                                                    color: Config.foregroundColor
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: Config.iconSizeLarge
                                                }

                                                MouseArea {
                                                    id: launcherMouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ShellState.toggleLauncher()
                                                }
                                            }

                                            Rectangle {
                                                width: 1
                                                height: 18
                                                color: Config.borderColor
                                            }

                                            WorkspaceIndicator {}
                                        }
                                    }

                                    // ----------------------------------------------------------------
                                    //                     RIGHT SECTION - System Indicators + Power
                                    // ----------------------------------------------------------------
                                    Item {
                                        Layout.preferredWidth: parent.width / 3
                                        Layout.fillHeight: true

                                        RowLayout {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Config.spacing

                                            SystemIndicators {}

                                            Rectangle {
                                                width: 1
                                                height: 18
                                                color: Config.borderColor
                                            }

                                            Rectangle {
                                                width: 36
                                                height: 36
                                                radius: Config.xsRadius
                                                color: powerMouseArea.containsMouse ? Qt.rgba(1, 0.3, 0.3, 0.15) : "transparent"
                                                scale: powerMouseArea.pressed ? 0.92 : 1.0

                                                Behavior on scale { NumberAnimation { duration: Config.animFast; easing.type: Easing.OutQuart } }
                                                Behavior on color { ColorAnimation { duration: Config.animFast } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "power_settings_new"
                                                    color: powerMouseArea.containsMouse ? Config.errorColor : Config.foregroundColor
                                                    font.family: "Material Symbols Rounded"
                                                    font.pixelSize: Config.iconSizeLarge
                                                }

                                                MouseArea {
                                                    id: powerMouseArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ShellState.togglePowerMenu()
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ========================================================================
                            //                     POPUP PANELS
                            // ========================================================================

                            AppLauncher {
                                parentBar: bar
                            }

                            ActionCenter {
                                parentBar: bar
                            }

                            PowerMenu {
                                parentBar: bar
                            }

                            TabMenu {
                                parentBar: bar
                            }

                            KeybindsCheatsheet {
                                parentBar: bar
                            }

                            MediaPanel {
                                parentBar: bar
                            }
                        }
