/*
 * ============================================================================
 *                       NOTIFICATION HANDLER
 * ============================================================================
 * 
 * FILE: misc/NotificationHandler.qml
 * PURPOSE: Singleton wrapper for desktop notification server
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This handler manages the notification daemon:
 *   - Receives notifications from applications
 *   - Tracks notification history (persistent list)
 *   - Manages popup visibility (transient list)
 *   - Provides access to notifications for both popup display and Action Center
 *   - Handles notification actions and dismissal
 * 
 * ============================================================================
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

/*
 * ============================================================================
 *                          QTOBJECT SINGLETON
 * ============================================================================
 */
QtObject {
    id: root
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    
    // Do Not Disturb mode - when enabled, notifications are not tracked
    property bool doNotDisturb: false
    
    // List of ALL tracked notifications (for Action Center history)
    // We access .values to get the array from the Map-like object
    readonly property var notificationList: server.trackedNotifications.values
    readonly property int count: server.trackedNotifications.values.length
    
    // List of currently visible POPUP notifications (transient)
    property var popupList: []
    
    // ========================================================================
    //                     NOTIFICATION SERVER
    // ========================================================================
    
    property var server: NotificationServer {
        id: notificationServer
        
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true
        
        onNotification: notification => {
            // Always track notifications so they appear in history (Action Center)
            notification.tracked = true
            
            // If not in DND mode, show in popup list
            if (!root.doNotDisturb) {
                addToPopup(notification)
                
                // Set up auto-hide timer for the popup
                // This removes it from popupList but KEEPS it in notificationList
                var timeout = notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 5000
                if (timeout > 0) {
                    popupTimer.createObject(root, {
                        notification: notification,
                        interval: timeout
                    })
                }
            }
        }
    }
    
    // Timer component for auto-hiding popups
    property Component popupTimer: Component {
        Timer {
            property var notification
            running: true
            repeat: false
            onTriggered: {
                root.removeFromPopup(notification)
                destroy()
            }
        }
    }
    
    // ========================================================================
    //                     POPUP MANAGEMENT
    // ========================================================================
    
    function addToPopup(notification) {
        // Create a copy of the array to trigger QML property update
        let list = Array.from(root.popupList)
        
        // Avoid duplicates
        if (!list.includes(notification)) {
            list.push(notification)
            root.popupList = list // Assignment triggers binding update
        }
    }
    
    function removeFromPopup(notification) {
        let list = Array.from(root.popupList)
        let index = list.indexOf(notification)
        
        if (index !== -1) {
            list.splice(index, 1)
            root.popupList = list // Assignment triggers binding update
        }
    }
    
    // ========================================================================
    //                     FUNCTIONS
    // ========================================================================
    
    // Dismiss a specific notification (Removes from BOTH history and popup)
    function dismiss(notification) {
        removeFromPopup(notification)
        if (notification && notification.tracked) {
            notification.dismiss() // This removes it from server.trackedNotifications
        }
    }
    
    // Clear all notifications
    function clearAll() {
        root.popupList = [] // Clear popups immediately
        
        let notifications = server.trackedNotifications.values
        for (let i = notifications.length - 1; i >= 0; i--) {
            notifications[i].dismiss()
        }
    }
    
    // Toggle Do Not Disturb mode
    function toggleDnd() {
        doNotDisturb = !doNotDisturb
    }
    
    // ========================================================================
    //                     HELPER FUNCTIONS
    // ========================================================================
    
    // Get appropriate icon for an app
    function getAppIcon(appName, appIcon) {
        // Known app icon mappings
        var iconMap = {
            "quickshell": "settings",
            "notify-send": "notifications",
            "discord": "chat",
            "firefox": "public",
            "chromium": "public",
            "chrome": "public",
            "spotify": "music_note",
            "vlc": "play_circle",
            "steam": "sports_esports",
            "telegram": "send",
            "signal": "message",
            "thunderbird": "mail",
            "nautilus": "folder",
            "dolphin": "folder",
            "thunar": "folder",
            "code": "code",
            "terminal": "terminal",
            "konsole": "terminal",
            "alacritty": "terminal",
            "kitty": "terminal"
        }
        
        var lowerName = (appName || "").toLowerCase()
        
        // Check if we have a material icon for this app
        for (var key in iconMap) {
            if (lowerName.includes(key)) {
                return { type: "material", icon: iconMap[key] }
            }
        }
        
        // If appIcon exists, use it
        if (appIcon && appIcon !== "") {
            return { type: "image", icon: appIcon }
        }
        
        // Default notification icon
        return { type: "material", icon: "notifications" }
    }
}
