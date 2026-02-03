/*
 * ============================================================================
 *                       LOCK CONTEXT
 * ============================================================================
 * 
 * FILE: panels/LockContext.qml
 * PURPOSE: Shared state and authentication for lock screen
 * 
 * Uses Quickshell.Services.Pam for proper PAM authentication.
 * Supports Howdy facial recognition - PAM handles it automatically.
 * ============================================================================
 */

import QtQuick
import Quickshell
import Quickshell.Services.Pam

import "../../misc"

Scope {
    id: root
    signal unlocked()
    
    // Shared state between all lock surfaces
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property string authStatus: "idle" // idle, scanning, success, failure
    property bool isExiting: false
    
    // Reset state when locking
    function reset() {
        currentText = ""
        unlockInProgress = false
        showFailure = false
        authStatus = "scanning"
        isExiting = false
    }
    
    // Clear the failure text once the user starts typing
    onCurrentTextChanged: showFailure = false
    
    function tryUnlock() {
        if (unlockInProgress || isExiting) return
        
        console.log("[LockContext] Starting authentication...")
        unlockInProgress = true
        pam.start()
    }
    
    // Auto-start authentication (for Face ID)
    function startAuth() {
        if (!unlockInProgress && !isExiting) {
            console.log("[LockContext] Auto-starting authentication...")
            unlockInProgress = true
            pam.start()
        }
    }
    
    PamContext {
        id: pam
        
        // PAM config with Howdy + password fallback
        configDirectory: Qt.resolvedUrl("pam").toString().replace("file://", "")
        config: "password.conf"
        
        onPamMessage: {
            console.log("[LockContext] PAM message:", this.message)
            
            // Detect Howdy messages (heuristic)
            if (this.message.includes("Identified face")) {
                root.authStatus = "success"
            } else if (this.message.includes("No face detected") || this.message.includes("Time out")) {
                root.authStatus = "failure"
            }
            
            if (this.responseRequired) {
                console.log("[LockContext] Responding with password")
                this.respond(root.currentText)
            }
        }
        
        onCompleted: result => {
            console.log("[LockContext] PAM completed with result:", result)
            
            if (result == PamResult.Success) {
                console.log("[LockContext] Authentication successful!")
                root.authStatus = "success"
                root.isExiting = true
                root.unlocked() // Fire immediately
            } else {
                console.log("[LockContext] Authentication failed")
                root.currentText = ""
                root.showFailure = true
                root.unlockInProgress = false
                root.authStatus = "failure"
            }
        }
    }
}
