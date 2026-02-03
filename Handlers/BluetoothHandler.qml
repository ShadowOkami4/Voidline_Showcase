/*
 * ============================================================================
 *                         BLUETOOTH HANDLER
 * ============================================================================
 * 
 * FILE: misc/BluetoothHandler.qml
 * PURPOSE: Singleton wrapper for Quickshell.Bluetooth API
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This handler wraps the native Quickshell.Bluetooth API:
 *   - Discovering nearby devices
 *   - Pairing with new devices
 *   - Connecting to paired devices
 *   - Power and visibility control
 *   - Device trust management
 * 
 * Uses the native BlueZ DBus interface via Quickshell.Bluetooth.
 * 
 * ============================================================================
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

/*
 * ============================================================================
 *                          QTOBJECT SINGLETON
 * ============================================================================
 */
QtObject {
    id: root
    
    // ========================================================================
    //                     ADAPTER REFERENCE
    // ========================================================================
    
    // The default Bluetooth adapter
    readonly property var adapter: Bluetooth.defaultAdapter
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    
    // Is Bluetooth powered on?
    readonly property bool powered: adapter ? adapter.enabled : false
    
    // Is device scanning active?
    readonly property bool discovering: adapter ? adapter.discovering : false
    
    // Is this device visible to others?
    readonly property bool discoverable: adapter ? adapter.discoverable : false
    
    // Controller (adapter) name
    readonly property string controllerName: adapter ? adapter.name : ""
    
    // Controller ID (e.g., "hci0")
    readonly property string controllerId: adapter ? adapter.adapterId : ""
    
    // Is there an adapter available?
    readonly property bool available: adapter !== null
    
    // ========================================================================
    //                     DEVICE LISTS
    // ========================================================================
    
    // All devices from the adapter (use .values for reactivity)
    readonly property var allDevices: adapter ? adapter.devices : null
    readonly property var deviceValues: allDevices ? allDevices.values : []
    
    // Paired devices list (computed from adapter.devices)
    property var pairedDevices: []
    
    // Available (unpaired but discovered) devices
    property var availableDevices: []
    
    // Address of device currently connecting (for loading indicator)
    property string connectingDevice: ""
    
    // ========================================================================
    //                     DEVICE LIST UPDATER
    // ========================================================================
    
    // Watch for device changes and update our arrays
    property var deviceWatcher: Connections {
        target: root.allDevices
        enabled: root.allDevices !== null
        
        function onObjectInsertedPost(object, index) { 
            root.updateDeviceLists()
        }
        function onObjectRemovedPost(object, index) { root.updateDeviceLists() }
    }
    
    // Timer to periodically refresh device states (while scanning or powered on)
    property var refreshTimer: Timer {
        interval: 1500
        running: root.powered
        repeat: true
        onTriggered: root.updateDeviceLists()
    }
    
    function updateDeviceLists() {
        let devices = deviceValues
        if (!devices || devices.length === 0) {
            pairedDevices = []
            availableDevices = []
            return
        }
        
        let paired = []
        let available = []
        
        for (let i = 0; i < devices.length; i++) {
            let device = devices[i]
            if (!device) continue
            
            let deviceInfo = {
                address: device.address || "",
                name: device.name || device.deviceName || device.address || "Unknown Device",
                connected: device.connected || false,
                trusted: device.trusted || false,
                paired: device.paired || false,
                icon: device.icon || "",
                battery: device.batteryAvailable ? Math.round(device.battery * 100) : -1,
                state: device.state,
                deviceRef: device  // Keep reference for actions
            }
            
            if (device.paired) {
                paired.push(deviceInfo)
            } else {
                available.push(deviceInfo)
            }
        }
        
        pairedDevices = paired
        availableDevices = available
    }
    
    // ========================================================================
    //                     POWER FUNCTIONS
    // ========================================================================
    
    // Process for unblocking rfkill and enabling bluetooth
    property var rfkillUnblockProc: Process {
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: (exitCode, exitStatus) => {
            console.log("[BT] rfkill unblock completed, code:", exitCode)
            // Now enable the adapter via bluetoothctl (more reliable)
            bluetoothPowerOnProc.running = true
        }
    }
    
    // Process for enabling bluetooth via bluetoothctl
    property var bluetoothPowerOnProc: Process {
        command: ["bluetoothctl", "power", "on"]
        onExited: (exitCode, exitStatus) => {
            console.log("[BT] bluetoothctl power on completed, code:", exitCode)
            // Also try via adapter property as backup
            if (root.adapter) {
                root.adapter.enabled = true
            }
        }
    }
    
    // Process for disabling bluetooth via bluetoothctl
    property var bluetoothPowerOffProc: Process {
        command: ["bluetoothctl", "power", "off"]
        onExited: (exitCode, exitStatus) => {
            console.log("[BT] bluetoothctl power off completed, code:", exitCode)
        }
    }
    
    // Turn Bluetooth on or off
    function setPower(on) {
        console.log("[BT] setPower called:", on)
        if (on) {
            // First unblock with rfkill, then enable adapter in the callback
            rfkillUnblockProc.running = true
        } else {
            // Disable via bluetoothctl (more reliable)
            bluetoothPowerOffProc.running = true
            // Also try via adapter property
            if (adapter) {
                adapter.enabled = false
            }
        }
    }
    
    // Set whether this device is visible to others
    function setDiscoverable(on) {
        if (adapter) {
            adapter.discoverable = on
        }
    }
    
    // ========================================================================
    //                     SCAN FUNCTIONS
    // ========================================================================
    
    // Scan timeout timer
    property var scanTimer: Timer {
        interval: 30000
        onTriggered: root.stopScan()
    }
    
    // Start scanning for nearby devices
    function startScan() {
        if (adapter && !adapter.discovering) {
            adapter.discovering = true
            scanTimer.restart()
        }
    }
    
    // Stop scanning
    function stopScan() {
        if (adapter && adapter.discovering) {
            adapter.discovering = false
            scanTimer.stop()
        }
    }
    
    // ========================================================================
    //                     DEVICE FUNCTIONS (via bluetoothctl)
    // ========================================================================
    
    // Find a device by address (for reading properties only)
    function findDevice(address) {
        let devices = deviceValues
        if (!devices) return null
        for (let i = 0; i < devices.length; i++) {
            let device = devices[i]
            if (device && device.address === address) {
                return device
            }
        }
        return null
    }
    
    // Process for bluetoothctl commands
    property var btctlProc: Process {
        property string operation: ""
        property string targetAddress: ""
        command: ["bluetoothctl", operation, targetAddress]
        
        onExited: (exitCode, exitStatus) => {
            console.log("[BT]", operation, targetAddress, "exited with code:", exitCode)
            
            // If pairing succeeded, trust and connect
            if (operation === "pair" && exitCode === 0) {
                console.log("[BT] Pairing successful, trusting device...")
                trustProc.targetAddress = targetAddress
                trustProc.running = true
            }
            // If trusting succeeded after pairing, connect
            else if (operation === "trust" && exitCode === 0 && root.connectingDevice === targetAddress) {
                console.log("[BT] Trust successful, connecting...")
                // Wait a moment for profiles to register
                connectDelayTimer.targetAddress = targetAddress
                connectDelayTimer.start()
            }
            // Clear connecting state on any completion
            else if ((operation === "connect" || operation === "disconnect") && root.connectingDevice === targetAddress) {
                root.connectingDevice = ""
            }
            
            // Refresh device lists
            Qt.callLater(root.updateDeviceLists)
        }
    }
    
    // Separate process for trust (since we need to chain commands)
    property var trustProc: Process {
        property string targetAddress: ""
        command: ["bluetoothctl", "trust", targetAddress]
        
        onExited: (exitCode, exitStatus) => {
            console.log("[BT] trust", targetAddress, "exited with code:", exitCode)
            if (exitCode === 0 && root.connectingDevice === targetAddress) {
                // Wait before connecting
                connectDelayTimer.targetAddress = targetAddress
                connectDelayTimer.start()
            }
        }
    }
    
    // Separate process for connect (final step)
    property var connectProc: Process {
        property string targetAddress: ""
        command: ["bluetoothctl", "connect", targetAddress]
        
        onExited: (exitCode, exitStatus) => {
            console.log("[BT] connect", targetAddress, "exited with code:", exitCode)
            if (root.connectingDevice === targetAddress) {
                root.connectingDevice = ""
            }
            Qt.callLater(root.updateDeviceLists)
        }
    }
    
    // Delay timer before connecting (gives audio profiles time to register)
    property var connectDelayTimer: Timer {
        property string targetAddress: ""
        interval: 2000
        onTriggered: {
            console.log("[BT] Delayed connect to:", targetAddress)
            connectProc.targetAddress = targetAddress
            connectProc.running = true
        }
    }
    
    // Connect to a device (handles pairing if needed)
    function connect(address) {
        let device = findDevice(address)
        console.log("[BT] connect() called for:", address, "paired:", device?.paired)
        
        connectingDevice = address
        
        if (device && !device.paired) {
            // Need to pair first - trust, pair, then connect
            console.log("[BT] Device not paired, starting trust+pair+connect flow...")
            trustProc.targetAddress = address
            trustProc.running = true
            
            // After trust completes, it will trigger pair via the timer
            // Actually, let's just pair directly (trust is in the chain)
            btctlProc.operation = "pair"
            btctlProc.targetAddress = address
            btctlProc.running = true
        } else {
            // Already paired, just connect
            console.log("[BT] Device already paired, connecting directly...")
            connectProc.targetAddress = address
            connectProc.running = true
        }
        
        // Set timeout
        connectTimeoutTimer.deviceAddress = address
        connectTimeoutTimer.restart()
    }
    
    property var connectTimeoutTimer: Timer {
        property string deviceAddress: ""
        interval: 20000  // 20 second timeout for full pair+connect flow
        onTriggered: {
            if (root.connectingDevice === deviceAddress) {
                console.log("[BT] Connection/pairing timeout for:", deviceAddress)
                root.connectingDevice = ""
            }
        }
    }
    
    // Disconnect from a device
    function disconnect(address) {
        console.log("[BT] disconnect() called for:", address)
        btctlProc.operation = "disconnect"
        btctlProc.targetAddress = address
        btctlProc.running = true
    }
    
    // Pair with a new device
    function pair(address) {
        console.log("[BT] pair() called for:", address)
        connectingDevice = address
        // Trust first, then pair
        trustProc.targetAddress = address
        trustProc.running = true
        btctlProc.operation = "pair"
        btctlProc.targetAddress = address
        btctlProc.running = true
        connectTimeoutTimer.deviceAddress = address
        connectTimeoutTimer.restart()
    }
    
    // Remove a device from paired list
    function remove(address) {
        console.log("[BT] remove() called for:", address)
        btctlProc.operation = "remove"
        btctlProc.targetAddress = address
        btctlProc.running = true
    }
    
    // Mark device as trusted
    function trust(address) {
        console.log("[BT] trust() called for:", address)
        trustProc.targetAddress = address
        trustProc.running = true
    }
    
    // Remove trusted status
    function untrust(address) {
        console.log("[BT] untrust() called for:", address)
        btctlProc.operation = "untrust"
        btctlProc.targetAddress = address
        btctlProc.running = true
    }
    
    // ========================================================================
    //                     REFRESH FUNCTION
    // ========================================================================
    
    function refresh() {
        updateDeviceLists()
    }
    
    // ========================================================================
    //                     INITIALIZATION
    // ========================================================================
    
    Component.onCompleted: {
        Qt.callLater(updateDeviceLists)
    }
    
    // Watch adapter changes and update device lists
    onAdapterChanged: {
        Qt.callLater(updateDeviceLists)
    }
}
