/*
 * ============================================================================
 *                    NOTIFICATION POPUP - M3 EXPRESSIVE
 * ============================================================================
 * 
 * FILE: panels/NotificationPopup.qml
 * PURPOSE: Desktop notification popup with Material 3 Expressive styling
 *
 * Design Features:
 *   - Large, expressive rounded corners (squircle-style)
 *   - Prominent colored app icon containers
 *   - Playful spring animations
 *   - Rich visual hierarchy
 *   - Swipe-to-dismiss gesture
 *   - Staggered entry animations
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PanelWindow {
    id: notificationPanel
    
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    
    anchors {
        top: true
        right: true
        left: false
        bottom: false
    }
    
    margins {
        top: Config.barHeight + Config.topMargin + 16
        right: 16
    }
    
    implicitWidth: 400
    implicitHeight: notificationList.height + 12
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    exclusionMode: ExclusionMode.Ignore
    
    visible: NotificationHandler.popupList.length > 0 && !NotificationHandler.doNotDisturb
    color: "transparent"
    
    // ========================================================================
    //                     HELPER FUNCTIONS
    // ========================================================================
    
    function getAppColor(appName) {
        let name = (appName || "").toLowerCase()
        if (name.includes("discord")) return "#5865F2"
        if (name.includes("spotify")) return "#1DB954"
        if (name.includes("firefox")) return "#FF7139"
        if (name.includes("chrome")) return "#4285F4"
        if (name.includes("telegram")) return "#0088cc"
        if (name.includes("signal")) return "#3A76F0"
        if (name.includes("slack")) return "#4A154B"
        if (name.includes("steam")) return "#1b2838"
        if (name.includes("code") || name.includes("vscode")) return "#007ACC"
        return Config.accentColor
    }
    
    // ========================================================================
    //                     NOTIFICATION LIST
    // ========================================================================
    
    ColumnLayout {
        id: notificationList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 6
        spacing: 14
        
        Repeater {
            model: NotificationHandler.popupList
            
            Item {
                id: notifWrapper
                required property var modelData
                required property int index
                
                Layout.fillWidth: true
                Layout.preferredHeight: notificationCard.height
                
                // Staggered entry animation
                opacity: 0
                transform: Translate { id: entryTranslate; x: 80 }
                
                Component.onCompleted: entryAnim.start()
                
                SequentialAnimation {
                    id: entryAnim
                    PauseAnimation { duration: index * 60 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: notifWrapper
                            property: "opacity"
                            to: 1
                            duration: 450
                            easing.type: Easing.OutQuart
                        }
                        NumberAnimation {
                            target: entryTranslate
                            property: "x"
                            to: 0
                            duration: 550
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.3
                        }
                    }
                }
                
                // Swipe tracking
                property real swipeX: 0
                
                Rectangle {
                    id: notificationCard
                    width: parent.width
                    height: cardContent.implicitHeight + 44
                    x: notifWrapper.swipeX
                    
                    // M3 Expressive: larger radius
                    radius: 28
                    color: Config.backgroundColor
                    
                    Behavior on x {
                        enabled: !dragArea.pressed
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 0.6
                        }
                    }
                    
                    // Tactile press feedback
                    scale: dragArea.pressed ? 0.97 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuart }
                    }
                    
                    // Rich shadow
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.45)
                        shadowBlur: 1.8
                        shadowVerticalOffset: 10
                        shadowHorizontalOffset: 0
                    }
                    
                    // Colored gradient accent from app
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        opacity: 0.1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { 
                                position: 0.0
                                color: notificationPanel.getAppColor(notifWrapper.modelData.appName)
                            }
                            GradientStop { position: 0.6; color: "transparent" }
                        }
                    }
                    
                    // Glass highlight
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                            GradientStop { position: 0.25; color: "transparent" }
                        }
                    }
                    
                    // Hover glow
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "white"
                        opacity: dragArea.containsMouse && !dragArea.pressed ? 0.03 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        property real startX: 0
                        
                        onPressed: (mouse) => { startX = mouse.x }
                        
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                let delta = mouse.x - startX
                                notifWrapper.swipeX = Math.max(0, delta * 0.85)
                            }
                        }
                        
                        onReleased: {
                            if (notifWrapper.swipeX > 100) {
                                dismissAnim.start()
                            } else {
                                notifWrapper.swipeX = 0
                            }
                        }
                        
                        onClicked: {
                            if (notifWrapper.swipeX < 10) {
                                ShellState.toggleActionCenter()
                            }
                        }
                    }
                    
                    // Dismiss animation
                    SequentialAnimation {
                        id: dismissAnim
                        ParallelAnimation {
                            NumberAnimation {
                                target: notifWrapper
                                property: "swipeX"
                                to: notifWrapper.width + 60
                                duration: 280
                                easing.type: Easing.OutQuart
                            }
                            NumberAnimation {
                                target: notifWrapper
                                property: "opacity"
                                to: 0
                                duration: 280
                            }
                        }
                        ScriptAction { script: notifWrapper.modelData.dismiss() }
                    }
                    
                    ColumnLayout {
                        id: cardContent
                        anchors {
                            fill: parent
                            margins: 20
                            leftMargin: 22
                            rightMargin: 22
                        }
                        spacing: 14
                        
                        // Header with expressive app icon
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            
                            // Large colorful app icon
                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 56
                                radius: 18
                                
                                gradient: Gradient {
                                    GradientStop { 
                                        position: 0.0
                                        color: Qt.lighter(notificationPanel.getAppColor(notifWrapper.modelData.appName), 1.15)
                                    }
                                    GradientStop { 
                                        position: 1.0
                                        color: notificationPanel.getAppColor(notifWrapper.modelData.appName)
                                    }
                                }
                                
                                property var iconInfo: NotificationHandler.getAppIcon(notifWrapper.modelData.appName, notifWrapper.modelData.appIcon)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.iconInfo.icon
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 28
                                    color: "white"
                                    visible: parent.iconInfo.type === "material"
                                    
                                    scale: dragArea.containsMouse ? 1.12 : 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                                    }
                                }
                                
                                Image {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    source: parent.iconInfo.type === "image" ? "image://icon/" + parent.iconInfo.icon : ""
                                    visible: parent.iconInfo.type === "image"
                                    sourceSize: Qt.size(30, 30)
                                }
                            }
                            
                            // App info
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                
                                Text {
                                    text: {
                                        var name = notifWrapper.modelData.appName || "System"
                                        return name.charAt(0).toUpperCase() + name.slice(1)
                                    }
                                    font.family: Config.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    font.letterSpacing: 0.3
                                    color: Config.foregroundColor
                                }
                                
                                Text {
                                    text: "Just now"
                                    font.family: Config.fontFamily
                                    font.pixelSize: 12
                                    color: Config.dimmedColor
                                }
                            }
                            
                            // Critical pulse
                            Rectangle {
                                visible: notifWrapper.modelData.urgency === NotificationUrgency.Critical
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                radius: 7
                                color: Config.errorColor
                                
                                SequentialAnimation on scale {
                                    running: notifWrapper.modelData.urgency === NotificationUrgency.Critical
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1.4; duration: 350; easing.type: Easing.OutQuad }
                                    NumberAnimation { to: 1.0; duration: 350; easing.type: Easing.InQuad }
                                }
                            }
                            
                            // Close button
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: 20
                                color: closeMouse.containsMouse ? Config.surfaceColorActive : "transparent"
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 22
                                    color: closeMouse.containsMouse ? Config.errorColor : Config.dimmedColor
                                }
                                
                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: dismissAnim.start()
                                }
                            }
                        }
                        
                        // Content with optional image
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 14
                            visible: notifWrapper.modelData.summary !== "" || notifWrapper.modelData.body !== ""
                            
                            // Album art / image
                            Rectangle {
                                visible: notifWrapper.modelData.image !== ""
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 72
                                Layout.alignment: Qt.AlignTop
                                radius: 16
                                color: Config.surfaceColor
                                clip: true
                                
                                Image {
                                    anchors.fill: parent
                                    source: notifWrapper.modelData.image || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 144
                                    sourceSize.height: 144
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                Text {
                                    visible: notifWrapper.modelData.summary !== ""
                                    text: notifWrapper.modelData.summary
                                    font.family: Config.fontFamily
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                    color: Config.foregroundColor
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    lineHeight: 1.2
                                }
                                
                                Text {
                                    visible: notifWrapper.modelData.body !== ""
                                    text: notifWrapper.modelData.body
                                    font.family: Config.fontFamily
                                    font.pixelSize: 14
                                    color: Config.dimmedColor
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    lineHeight: 1.35
                                }
                            }
                        }
                        
                        // Expressive action buttons
                        RowLayout {
                            visible: notifWrapper.modelData.actions.length > 0
                            Layout.fillWidth: true
                            spacing: 10
                            Layout.topMargin: 6
                            
                            Item { Layout.fillWidth: true }
                            
                            Repeater {
                                model: notifWrapper.modelData.actions
                                
                                Rectangle {
                                    id: actionBtn
                                    required property var modelData
                                    required property int index
                                    
                                    Layout.preferredHeight: 42
                                    Layout.preferredWidth: actionBtnText.implicitWidth + 32
                                    radius: 21
                                    
                                    // Primary (filled) vs secondary (tonal)
                                    color: index === 0 ? 
                                           (actionBtnMouse.containsMouse ? Config.accentColorHover : Config.accentColor) :
                                           (actionBtnMouse.containsMouse ? Config.surfaceColorActive : Config.surfaceColor)
                                    
                                    scale: actionBtnMouse.pressed ? 0.94 : 1.0
                                    
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { 
                                        NumberAnimation { duration: 120; easing.type: Easing.OutQuart } 
                                    }
                                    
                                    Text {
                                        id: actionBtnText
                                        anchors.centerIn: parent
                                        text: actionBtn.modelData.text
                                        font.family: Config.fontFamily
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        color: actionBtn.index === 0 ? Config.onAccent : Config.accentColor
                                    }
                                    
                                    MouseArea {
                                        id: actionBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: actionBtn.modelData.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
