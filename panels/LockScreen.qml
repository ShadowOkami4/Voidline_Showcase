/*
 * ============================================================================
 *                       LOCK SCREEN
 * ============================================================================
 * 
 * FILE: panels/LockScreen.qml
 * PURPOSE: Session lock using WlSessionLock protocol
 * ============================================================================
 * 
 * NOTE: The Wayland session lock protocol destroys the lock object when
 * unlocked, so we must use a Loader to create a fresh WlSessionLock for
 * each lock cycle.
 */

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../misc"

Scope {
    id: lockScreen
    
    // The shared context for all lock surfaces
    LockContext {
        id: lockContext
        
        onUnlocked: {
            console.log("[LockScreen] Authentication successful, releasing lock...")
            // 1. Release the compositor lock immediately to reveal desktop
            if (lockLoader.item) {
                lockLoader.item.locked = false
            }
            // 2. Wait for animations to play before destroying the surfaces
            cleanupTimer.start()
        }
    }

    Timer {
        id: cleanupTimer
        interval: 600
        onTriggered: ShellState.lockScreenVisible = false
    }
    
    // Use a Loader to create fresh WlSessionLock instances
    // The protocol requires a new lock object for each lock cycle
    Loader {
        id: lockLoader
        active: false
        
        sourceComponent: WlSessionLock {
            id: sessionLock
            
            // Lock immediately when loaded
            locked: true
            
            onLockedChanged: {
                console.log("[LockScreen] Session lock state:", locked)
                // When unlock completes, deactivate the loader
                if (!locked) {
                    Qt.callLater(function() {
                        lockLoader.active = false
                    })
                }
            }
            
            // Create lock surface on each screen
            WlSessionLockSurface {
                LockSurface {
                    anchors.fill: parent
                    context: lockContext
                }
            }
        }
    }
    
    // Watch shell state to trigger lock
    Connections {
        target: ShellState
        
        function onLockScreenVisibleChanged() {
            console.log("[LockScreen] ShellState.lockScreenVisible:", ShellState.lockScreenVisible)
            if (ShellState.lockScreenVisible && !lockLoader.active) {
                console.log("[LockScreen] Locking session...")
                lockContext.reset()
                lockLoader.active = true
            }
        }
    }
}
