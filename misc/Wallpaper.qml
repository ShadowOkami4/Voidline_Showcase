/*
 * ============================================================================
 *                          WALLPAPER COMPONENT
 * ============================================================================
 * 
 * FILE: misc/Wallpaper.qml
 * PURPOSE: Render desktop wallpaper with smooth crossfade transition
 * 
 * ============================================================================
 */

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

WlrLayershell {
    id: root
    
    required property var screen
    
    layer: WlrLayer.Background
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    keyboardFocus: WlrKeyboardFocus.None
    color: Config.backgroundColor
    
    Item {
        id: container
        anchors.fill: parent
        
        property bool showingFirst: true
        
        function getFillMode() {
            switch (Config.wallpaperFillMode) {
                case "contain": return Image.PreserveAspectFit
                case "stretch": return Image.Stretch
                case "tile": return Image.Tile
                default: return Image.PreserveAspectCrop
            }
        }
        
        // First wallpaper image
        Image {
            id: wallpaper1
            anchors.fill: parent
            fillMode: container.getFillMode()
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            opacity: container.showingFirst ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.wallpaperTransitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
        
        // Second wallpaper image (for crossfade)
        Image {
            id: wallpaper2
            anchors.fill: parent
            fillMode: container.getFillMode()
            asynchronous: true
            cache: false
            smooth: true
            mipmap: true
            opacity: container.showingFirst ? 0 : 1
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Config.wallpaperTransitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
        
        // Handle wallpaper changes
        Connections {
            target: Config
            
            function onWallpaperPathChanged() {
                let newPath = Config.wallpaperPath ? "file://" + Config.wallpaperPath : ""
                if (newPath === "") return
                
                let currentSource = container.showingFirst ? wallpaper1.source : wallpaper2.source
                if (newPath === currentSource) return
                
                if (Config.wallpaperTransition) {
                    // Crossfade: load into hidden image, then swap
                    if (container.showingFirst) {
                        wallpaper2.source = newPath
                    } else {
                        wallpaper1.source = newPath
                    }
                    container.showingFirst = !container.showingFirst
                } else {
                    // No transition: direct swap
                    if (container.showingFirst) {
                        wallpaper1.source = newPath
                    } else {
                        wallpaper2.source = newPath
                    }
                }
            }
        }
        
        // Initialize
        Component.onCompleted: {
            if (Config.wallpaperPath) {
                wallpaper1.source = "file://" + Config.wallpaperPath
            }
        }
        
        // Loading indicator
        Rectangle {
            anchors.centerIn: parent
            width: 80
            height: 80
            radius: 40
            color: Qt.rgba(0, 0, 0, 0.5)
            visible: wallpaper1.status === Image.Loading || wallpaper2.status === Image.Loading
            
            Text {
                anchors.centerIn: parent
                text: "hourglass_empty"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 32
                color: "#fff"
                
                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1500
                    loops: Animation.Infinite
                    running: parent.parent.visible
                }
            }
        }
        
        // Color generation
        Timer {
            id: colorGenTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (Config.wallpaperPath && Config.dynamicColors) {
                    generateColors()
                }
            }
        }
        
        Connections {
            target: wallpaper1
            function onStatusChanged() {
                if (wallpaper1.status === Image.Ready && container.showingFirst && Config.dynamicColors) {
                    colorGenTimer.restart()
                }
            }
        }
        
        Connections {
            target: wallpaper2
            function onStatusChanged() {
                if (wallpaper2.status === Image.Ready && !container.showingFirst && Config.dynamicColors) {
                    colorGenTimer.restart()
                }
            }
        }
    }
    
    function generateColors() {
        let scriptPath = Qt.resolvedUrl("../scripts/apply-colors.sh").toString().replace("file://", "")
        let command = scriptPath + " \"" + Config.wallpaperPath + "\""
        console.log("[Wallpaper] Generating colors from:", Config.wallpaperPath)
        colorGenProcess.command = ["bash", "-c", command]
        colorGenProcess.running = true
    }
    
    Process {
        id: colorGenProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                console.log("[Wallpaper] Colors generated successfully")
            } else {
                console.log("[Wallpaper] Color generation failed with code:", exitCode)
            }
        }
    }
}
