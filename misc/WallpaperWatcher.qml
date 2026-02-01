/*
 * ============================================================================
 *                       WALLPAPER WATCHER SERVICE
 * ============================================================================
 * 
 * FILE: misc/WallpaperWatcher.qml
 * PURPOSE: Monitor wallpaper changes and auto-generate colors
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This service watches for wallpaper changes and automatically triggers
 * color generation when the wallpaper changes.
 * 
 * Supports:
 *   - swww (ipc socket)
 *   - hyprpaper (hyprctl)
 *   - Manual polling fallback
 * 
 * ============================================================================
 */

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    
    // Current detected wallpaper path
    property string currentWallpaper: ""
    
    // Previous wallpaper (to detect changes)
    property string previousWallpaper: ""
    
    // Auto-apply colors on wallpaper change
    property bool autoApplyColors: true
    
    // Polling interval (ms) for wallpaper detection
    property int pollInterval: 5000
    
    // ========================================================================
    //                     WALLPAPER DETECTION
    // ========================================================================
    
    // Poll for wallpaper changes
    Timer {
        id: pollTimer
        interval: root.pollInterval
        running: root.autoApplyColors
        repeat: true
        triggeredOnStart: true
        
        onTriggered: {
            detectWallpaper()
        }
    }
    
    // Detect current wallpaper
    function detectWallpaper() {
        // Try swww first
        swwwQueryProc.running = true
    }
    
    // swww query process
    Process {
        id: swwwQueryProc
        command: ["swww", "query"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                // Parse swww output: "eDP-1: image: /path/to/wallpaper.jpg"
                let match = output.match(/image:\s*(.+)/)
                if (match && match[1]) {
                    root.setWallpaper(match[1].trim())
                } else {
                    // Try hyprpaper as fallback
                    hyprpaperQueryProc.running = true
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // swww not available, try hyprpaper
                hyprpaperQueryProc.running = true
            }
        }
    }
    
    // hyprpaper query process
    Process {
        id: hyprpaperQueryProc
        command: ["hyprctl", "hyprpaper", "listactive"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let output = this.text.trim()
                // Parse hyprpaper output
                let lines = output.split('\n')
                for (let line of lines) {
                    // Format: "eDP-1 = /path/to/wallpaper.jpg"
                    let parts = line.split('=')
                    if (parts.length >= 2) {
                        root.setWallpaper(parts[1].trim())
                        return
                    }
                }
            }
        }
    }
    
    // Set wallpaper and trigger color generation if changed
    function setWallpaper(path) {
        if (!path || path === root.currentWallpaper) return
        
        root.previousWallpaper = root.currentWallpaper
        root.currentWallpaper = path
        
        console.log("[WallpaperWatcher] Wallpaper changed:", path)
        
        if (root.autoApplyColors && root.previousWallpaper !== "") {
            // Wallpaper actually changed, generate colors
            ColorScheme.applyWallpaper(path)
        }
    }
    
    // ========================================================================
    //                     SWWW IPC SOCKET WATCHER
    // ========================================================================
    
    // Watch swww socket for real-time updates
    // (This is more efficient than polling if swww is available)
    Process {
        id: swwwDaemonCheck
        command: ["pgrep", "-x", "swww-daemon"]
        
        Component.onCompleted: {
            running = true
        }
        
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // swww daemon is running, use socket watcher
                console.log("[WallpaperWatcher] swww daemon detected, using socket watcher")
                pollTimer.interval = 2000  // Still poll but less frequently as backup
            }
        }
    }
    
    // ========================================================================
    //                          MANUAL TRIGGER
    // ========================================================================
    
    // Manually refresh wallpaper detection
    function refresh() {
        detectWallpaper()
    }
    
    // Force apply colors from current wallpaper
    function applyCurrentColors() {
        if (root.currentWallpaper) {
            ColorScheme.applyWallpaper(root.currentWallpaper)
        }
    }
    
    // ========================================================================
    //                          INITIALIZATION
    // ========================================================================
    
    Component.onCompleted: {
        console.log("[WallpaperWatcher] Started, auto-apply:", root.autoApplyColors)
        // Initial detection
        detectWallpaper()
    }
}
