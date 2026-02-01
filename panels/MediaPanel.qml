/*
 * ============================================================================
 *                          MEDIA PANEL (REWORKED)
 * ============================================================================
 * 
 * FILE: panels/MediaPanel.qml
 * PURPOSE: Expressive media controls with glass aesthetics
 * 
 * ============================================================================
 */

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../misc"
import "../components"
import "media" as Media

PanelWindow {
    id: root
    
    // ========================================================================
    //                         CONFIGURATION
    // ========================================================================
    
    readonly property real barBottom: Config.barHeight + Config.topMargin + 8
    readonly property real panelWidth: 360
    
    // ========================================================================
    //                         WINDOW SETUP
    // ========================================================================
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-media"
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    
    // Total height needed for content + spacing
    implicitHeight: ShellState.mediaPanelVisible ? (barBottom + wrapper.implicitHeight + 40) : 0
    Behavior on implicitHeight { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
    
    // ========================================================================
    //                         VISIBILITY & FOCUS
    // ========================================================================
    
    readonly property bool shouldBeActive: ShellState.mediaPanelVisible
    
    HyprlandFocusGrab {
        active: root.shouldBeActive
        windows: [root]
        onCleared: ShellState.mediaPanelVisible = false
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.mediaPanelVisible = false
    }
    
    // ========================================================================
    //                         MAIN PANEL CARD
    // ========================================================================
    
    Rectangle {
        id: container
        width: root.panelWidth
        height: wrapper.implicitHeight + 20
        anchors.top: parent.top
        anchors.topMargin: root.barBottom
        anchors.horizontalCenter: parent.horizontalCenter
        
        radius: Config.panelRadius
        color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
        border.width: 1
        border.color: Config.borderColor
        
        // EXIT/ENTRY ANIMATION
        opacity: root.shouldBeActive ? 1 : 0
        scale: root.shouldBeActive ? 1 : 0.9
        transformOrigin: Item.Top
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { 
            NumberAnimation { 
                duration: 400
                easing { type: Easing.OutBack; overshoot: 1.5 } 
            } 
        }
        
        // Content Wrapper
        Media.Wrapper {
            id: wrapper
            anchors.centerIn: parent
            width: parent.width - 20
            shouldBeActive: root.shouldBeActive
        }
    }
}