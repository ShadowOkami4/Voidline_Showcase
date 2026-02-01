/*
 * ============================================================================
 *                       MEDIA CONTROL BAR WIDGET
 * ============================================================================
 * 
 * FILE: indicators/MediaControl.qml
 * PURPOSE: Mini cava visualization in bar, click to open media panel
 * 
 * ============================================================================
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

import "../misc"

Item {
    id: mediaControl
    
    // Always visible - shows "No media" or visualization
    visible: true
    implicitWidth: content.width
    implicitHeight: Config.barHeight
    
    // Get players list - this is reactive
    property var playersList: Mpris.players.values
    property int playerCount: playersList ? playersList.length : 0
    
    // Find active player
    function findActivePlayer() {
        if (!playersList || playersList.length === 0) return null
        
        // Find a playing player first
        for (let i = 0; i < playersList.length; i++) {
            let player = playersList[i]
            if (player && player.playbackState === MprisPlaybackState.Playing) {
                return player
            }
        }
        // Otherwise return first player
        return playersList[0]
    }
    
    property var activePlayer: findActivePlayer()
    property bool hasPlayer: activePlayer !== null
    property alias hasActivePlayer: mediaControl.hasPlayer
    property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
    
    // Refresh player when list changes
    onPlayersListChanged: activePlayer = findActivePlayer()
    
    // Also poll periodically for state changes
    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: mediaControl.activePlayer = mediaControl.findActivePlayer()
    }
    
    // Animated bars for visualization
    property int barCount: 8
    property var animatedBars: []
    
    Component.onCompleted: {
        let bars = []
        for (let i = 0; i < barCount; i++) bars.push(0.2)
        animatedBars = bars
    }
    
    Timer {
        running: mediaControl.isPlaying
        interval: 80
        repeat: true
        onTriggered: {
            let newBars = []
            for (let i = 0; i < mediaControl.barCount; i++) {
                let current = mediaControl.animatedBars[i] || 0.2
                let target = Math.random() * 0.9 + 0.1
                newBars.push(current + (target - current) * 0.5)
            }
            mediaControl.animatedBars = newBars
        }
    }
    
    // ========================================================================
    //                BAR CONTENT (M3 Expressive)
    // ========================================================================
    
    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        // Container with rounded clipping
        Item {
            id: mediaButtonContainer
            width: mediaButton.width
            height: mediaButton.height
            
            // Playful scale animation
            scale: mouseArea.pressed ? 0.94 : (mouseArea.containsMouse ? 1.03 : 1.0)
            
            Behavior on scale { 
                NumberAnimation { 
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }
            
            Rectangle {
                id: mediaButton
                width: mediaButtonContent.width + 24
                height: 38
                radius: 19
                color: Config.surfaceColor
                
                // Blurred album art background
                Item {
                    id: albumArtBg
                    anchors.fill: parent
                    visible: bgAlbumArt.status === Image.Ready
                    
                    Image {
                        id: bgAlbumArt
                        anchors.fill: parent
                        anchors.margins: -20
                        source: mediaControl.activePlayer ? (mediaControl.activePlayer.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 100
                        sourceSize.height: 100
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: 32
                            blur: 0.8
                            saturation: 0.6
                            brightness: -0.05
                        }
                    }
                    
                    // Dark overlay
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0, 0, 0, 0.4)
                    }
                    
                    // Gradient overlay
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.25) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }
                
                // Fallback gradient when no album art
                Rectangle {
                    anchors.fill: parent
                    visible: bgAlbumArt.status !== Image.Ready
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { 
                            position: 0.0
                            color: mouseArea.containsMouse ? 
                                   Config.surfaceColorActive : 
                                   (mediaControl.isPlaying ? 
                                    Qt.rgba(Config.accentColor.r, Config.accentColor.g, Config.accentColor.b, 0.15) : 
                                    Config.surfaceColor)
                        }
                        GradientStop { 
                            position: 1.0
                            color: mouseArea.containsMouse ? Config.surfaceColorHover : Config.surfaceColor
                        }
                    }
                }
                
                // Hover highlight
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "white"
                    opacity: mouseArea.containsMouse ? 0.1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                
                // Clip to rounded corners
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: mediaButton.width
                            height: mediaButton.height
                            radius: mediaButton.radius
                        }
                    }
                }
                
                Row {
                    id: mediaButtonContent
                    anchors.centerIn: parent
                    spacing: 8
                
                // Icon / visualization area
                Item {
                    width: 20
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter
                    
                    // Static icon when no media or paused
                    Text {
                        anchors.centerIn: parent
                        text: mediaControl.hasPlayer ? (mediaControl.isPlaying ? "" : "pause") : "music_off"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: bgAlbumArt.visible ? "white" : (mediaControl.hasPlayer ? Config.accentColor : Config.dimmedColor)
                        visible: !mediaControl.isPlaying
                    }
                    
                    // Mini cava bars when playing
                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        visible: mediaControl.isPlaying
                        
                        Repeater {
                            model: 5
                            Rectangle {
                                width: 3
                                height: Math.max(4, 18 * (mediaControl.animatedBars[index] || 0.3))
                                radius: 1.5
                                color: bgAlbumArt.visible ? "white" : Config.accentColor
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Behavior on height {
                                    NumberAnimation { duration: 60; easing.type: Easing.OutQuad }
                                }
                            }
                        }
                    }
                }
                
                // Scrolling text label for long titles
                Item {
                    id: textContainer
                    width: 110
                    height: 18
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter
                    
                    property string displayText: {
                        if (!mediaControl.hasPlayer) return "No media"
                        if (mediaControl.isPlaying) {
                            return mediaControl.activePlayer.trackTitle || "Unknown"
                        }
                        return "Paused"
                    }
                    
                    property bool needsScroll: scrollingText.implicitWidth > textContainer.width && mediaControl.isPlaying
                    property bool shouldCenter: !mediaControl.isPlaying || !needsScroll
                    
                    Text {
                        id: scrollingText
                        text: textContainer.displayText
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: bgAlbumArt.visible ? "white" : (mediaControl.hasPlayer ? Config.foregroundColor : Config.dimmedColor)
                        
                        x: textContainer.shouldCenter 
                            ? (textContainer.width - implicitWidth) / 2 
                            : (textContainer.needsScroll ? scrollAnim.x : 0)
                        
                        property real scrollX: 0
                    }
                    
                    // Duplicate text for seamless loop
                    Text {
                        visible: textContainer.needsScroll
                        text: textContainer.displayText
                        font: scrollingText.font
                        color: scrollingText.color
                        x: scrollingText.x + scrollingText.implicitWidth + 30
                    }
                    
                    // Scroll animation
                    NumberAnimation {
                        id: scrollAnim
                        property real x: 0
                        target: scrollAnim
                        property: "x"
                        from: 0
                        to: -(scrollingText.implicitWidth + 30)
                        duration: (scrollingText.implicitWidth + 30) * 40
                        loops: Animation.Infinite
                        running: textContainer.needsScroll && mediaControl.isPlaying
                    }
                    
                    onDisplayTextChanged: {
                        scrollAnim.restart()
                    }
                }
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (mediaControl.hasPlayer) {
                        ShellState.toggleMediaPanel()
                    }
                }
            }
        }  // End Rectangle mediaButton
    }  // End Item mediaButtonContainer
    }  // End Row content
}  // End Item mediaControl