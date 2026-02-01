/*
 * ============================================================================
 *                          WALLPAPER COMPONENT
 * ============================================================================
 * 
 * FILE: misc/Wallpaper.qml
 * PURPOSE: Render desktop wallpaper background using Quickshell
 * 
 * This component creates a fullscreen background layer below all other
 * windows using WlrLayershell. It displays an image that fills the entire
 * screen, similar to how swww or hyprpaper work.
 * 
 * FEATURES:
 *   - Renders wallpaper on the background layer
 *   - Supports different fill modes (cover, contain, stretch, tile)
 *   - Smooth transitions when wallpaper changes
 *   - Per-monitor wallpaper support
 *   - Triggers color generation when wallpaper changes
 * 
 * USAGE:
 *   In shell.qml:
 *   Variants {
 *       model: Quickshell.screens
 *       Wallpaper {
 *           required property var modelData
 *           screen: modelData
 *       }
 *   }
 * 
 * ============================================================================
 */

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/*
 * WlrLayershell creates a layer-shell surface on Wayland compositors.
 * We use the Background layer so the wallpaper is behind everything.
 */
WlrLayershell {
    id: root
    
    // The screen this wallpaper is displayed on
    required property var screen
    
    // Layer configuration
    layer: WlrLayer.Background
    
    // Don't reserve any screen space and ignore other exclusive zones
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    
    // Anchors to all edges to fill the entire screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    // Don't take keyboard focus
    keyboardFocus: WlrKeyboardFocus.None
    
    // Size will be determined by anchors filling the screen
    // Don't set explicit width/height when anchoring to all edges
    
    // Make the window transparent for smooth transitions
    color: "transparent"
    
    // ========================================================================
    //                          BACKGROUND CONTAINER
    // ========================================================================
    
    Rectangle {
        id: container
        anchors.fill: parent
        color: Config.backgroundColor
        
        // Previous wallpaper for crossfade transition
        Image {
            id: previousWallpaper
            anchors.fill: parent
            fillMode: getFillMode()
            asynchronous: true
            cache: false
            opacity: 0
            
            function getFillMode() {
                switch (Config.wallpaperFillMode) {
                    case "contain": return Image.PreserveAspectFit
                    case "stretch": return Image.Stretch
                    case "tile": return Image.Tile
                    default: return Image.PreserveAspectCrop // "cover"
                }
            }
        }
        
        // Current wallpaper image
        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: Config.wallpaperPath ? "file://" + Config.wallpaperPath : ""
            fillMode: getFillMode()
            asynchronous: true
            cache: false
            
            // Smooth scaling for high quality rendering
            smooth: true
            mipmap: true
            
            function getFillMode() {
                switch (Config.wallpaperFillMode) {
                    case "contain": return Image.PreserveAspectFit
                    case "stretch": return Image.Stretch
                    case "tile": return Image.Tile
                    default: return Image.PreserveAspectCrop // "cover"
                }
            }
            
            // Handle source changes for crossfade
            onSourceChanged: {
                if (previousWallpaper.source !== "" && Config.wallpaperTransition) {
                    crossfadeAnimation.start()
                }
            }
            
            // When wallpaper loads, trigger color generation if enabled
            onStatusChanged: {
                if (status === Image.Ready && Config.dynamicColors) {
                    // Delay slightly to ensure file is fully written
                    colorGenTimer.restart()
                }
            }
            
            // Show loading indicator or error state
            Rectangle {
                anchors.centerIn: parent
                width: 80
                height: 80
                radius: 40
                color: Qt.rgba(0, 0, 0, 0.5)
                visible: wallpaperImage.status === Image.Loading
                
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
                        running: wallpaperImage.status === Image.Loading
                    }
                }
            }
        }
        
        // Crossfade animation for smooth transitions
        SequentialAnimation {
            id: crossfadeAnimation
            
            PropertyAction {
                target: previousWallpaper
                property: "source"
                value: wallpaperImage.source
            }
            
            PropertyAction {
                target: previousWallpaper
                property: "opacity"
                value: 1
            }
            
            PropertyAction {
                target: wallpaperImage
                property: "opacity"
                value: 0
            }
            
            PauseAnimation {
                duration: 50
            }
            
            ParallelAnimation {
                NumberAnimation {
                    target: wallpaperImage
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Config.wallpaperTransitionDuration
                    easing.type: Easing.InOutQuad
                }
                
                NumberAnimation {
                    target: previousWallpaper
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Config.wallpaperTransitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
        
        // Timer to trigger color generation after wallpaper loads
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
    }
    
    // ========================================================================
    //                     COLOR GENERATION
    // ========================================================================
    
    /*
     * Generate Material You colors from the wallpaper.
     * This calls the apply-colors.sh script with the current wallpaper path.
     */
    function generateColors() {
        let scriptPath = Qt.resolvedUrl("../scripts/apply-colors.sh").toString().replace("file://", "")
        let command = scriptPath + " \"" + Config.wallpaperPath + "\""
        
        console.log("[Wallpaper] Generating colors from:", Config.wallpaperPath)
        
        // Use Process to run the color generation script
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
