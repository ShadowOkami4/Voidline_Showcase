/*
 * ============================================================================
 *                          NETWORK HANDLER
 * ============================================================================
 * 
 * FILE: misc/NetworkHandler.qml
 * PURPOSE: Singleton for NetworkManager-based network management
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This handler manages all network functionality:
 *   - WiFi scanning and connection
 *   - Ethernet connection management
 *   - Saved connection profiles
 *   - IP address configuration (DHCP and static)
 *   - Connection creation and deletion
 * 
 * Uses NetworkManager CLI (nmcli) for all operations.
 * 
 * ============================================================================
 *                         DEPENDENCIES
 * ============================================================================
 * 
 * Requires NetworkManager to be installed and running:
 *   sudo pacman -S networkmanager
 *   sudo systemctl enable --now NetworkManager
 * 
 * ============================================================================
 *                         NMCLI COMMANDS REFERENCE
 * ============================================================================
 * 
 * STATUS & INFO:
 *   nmcli general status           <- Overall network status
 *   nmcli device wifi list         <- List available WiFi networks
 *   nmcli connection show          <- List saved connections
 *   nmcli connection show "name"   <- Details of specific connection
 * 
 * CONNECT/DISCONNECT:
 *   nmcli device wifi connect "SSID"                     <- Connect (saved)
 *   nmcli device wifi connect "SSID" password "pass"    <- Connect (new)
 *   nmcli connection up "name"      <- Activate saved connection
 *   nmcli connection down "name"    <- Deactivate connection
 * 
 * WIFI CONTROL:
 *   nmcli radio wifi on             <- Enable WiFi
 *   nmcli radio wifi off            <- Disable WiFi
 * 
 * CREATE CONNECTIONS:
 *   nmcli connection add type wifi con-name "MyWifi" ssid "SSID"
 *   nmcli connection modify "name" wifi-sec.psk "password"
 *   nmcli connection add type ethernet con-name "MyEth"
 * 
 * IP CONFIGURATION:
 *   nmcli connection modify "name" ipv4.method auto     <- DHCP
 *   nmcli connection modify "name" ipv4.method manual ipv4.addresses "192.168.1.100/24"
 *   nmcli connection modify "name" ipv4.gateway "192.168.1.1"
 *   nmcli connection modify "name" ipv4.dns "8.8.8.8,8.8.4.4"
 * 
 * DELETE:
 *   nmcli connection delete "name"
 * 
 * ============================================================================
 *                         QML PATTERNS USED
 * ============================================================================
 * 
 * DIALOG STATE PATTERN:
 *   property bool showPasswordDialog: false
 *   property string selectedSSID: ""
 *   
 *   UI binds to these: visible: NetworkHandler.showPasswordDialog
 *   Handler sets them: showPasswordDialog = true; selectedSSID = ssid
 * 
 * FORM FIELD PATTERN:
 *   property string editConnName: ""
 *   
 *   TextInput binds: text: NetworkHandler.editConnName
 *   On change: NetworkHandler.editConnName = text
 *   On submit: createConnection(editConnName, ...)
 * 
 * ============================================================================
 */

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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
    // Current network state - updated by refresh()
    
    // Currently connected WiFi network name (empty if not connected)
    property string currentSSID: ""
    
    // Connection status: "connected", "connecting", "disconnected"
    property string connectionStatus: "disconnected"
    
    // Connection type: "wifi", "ethernet", "none"
    property string connectionType: "none"
    
    // List of available WiFi networks from last scan
    // Each: { ssid: string, signal: number, security: string, connected: bool }
    property var networkList: []
    
    // Is WiFi radio enabled?
    property bool wifiEnabled: true
    
    // Current IP address
    property string ipAddress: ""
    
    // List of saved connection profiles
    // Each: { name: string, type: string, autoConnect: bool }
    property var savedConnections: []
    
    // ========================================================================
    //                     DIALOG STATE
    // ========================================================================
    // These control UI dialogs for password entry and connection editing
    
    property bool showPasswordDialog: false
    property string selectedSSID: ""
    property string selectedSecurity: ""
    property bool showConnectionEditor: false
    property bool showAddConnection: false
    property string editingConnection: ""
    property string editConnectionType: "wifi"
    
    // ========================================================================
    //                     CONNECTION EDITOR FIELDS
    // ========================================================================
    // Bound to form inputs in the connection editor UI
    
    property string editConnName: ""
    property string editConnSSID: ""
    property string editConnPassword: ""
    property bool editConnAutoConnect: true
    property string editConnIpMode: "auto"      // "auto" (DHCP) or "manual" (static)
    property string editConnIpAddress: ""
    property string editConnNetmask: "24"
    property string editConnGateway: ""
    property string editConnDns1: ""
    property string editConnDns2: ""
    
    // ========================================================================
    //                     REFRESH FUNCTION
    // ========================================================================
    function refresh() {
        getCurrentConnectionProc.running = true
        getSavedConnectionsProc.running = true
    }
    
    // ========================================================================
    //                     CONNECTION FUNCTIONS
    // ========================================================================
    
    // Enable or disable WiFi radio
    function toggleWifi(enable) {
        toggleWifiProc.enable = enable
        toggleWifiProc.running = true
    }
    
    // Connect to a saved network by SSID
    function connectNetwork(ssid) {
        connectNetworkProc.ssid = ssid
        connectNetworkProc.running = true
    }
    
    // Connect to a new network with password
    function connectWithPassword(ssid, password) {
        connectWithPasswordProc.ssid = ssid
        connectWithPasswordProc.password = password
        connectWithPasswordProc.running = true
    }
    
    // Disconnect current connection
    function disconnect() {
        disconnectNetworkProc.running = true
    }
    
    // Delete a saved connection profile
    function deleteConnection(name) {
        deleteConnectionProc.connName = name
        deleteConnectionProc.running = true
    }
    
    // Load details of a connection for editing
    function getConnectionDetails(name) {
        getConnectionDetailsProc.connName = name
        getConnectionDetailsProc.running = true
    }
    
    // Create a new WiFi connection profile
    function createWifiConnection(name, ssid, password, autoConnect) {
        createWifiConnectionProc.connName = name
        createWifiConnectionProc.ssid = ssid
        createWifiConnectionProc.password = password
        createWifiConnectionProc.autoConnect = autoConnect
        createWifiConnectionProc.running = true
    }
    
    // Create a new Ethernet connection profile
    function createEthernetConnection(name, autoConnect) {
        createEthernetConnectionProc.connName = name
        createEthernetConnectionProc.autoConnect = autoConnect
        createEthernetConnectionProc.running = true
    }
    
    // Modify IP settings of an existing connection
    function modifyConnectionIp(name, mode, ip, mask, gw, dns1, dns2) {
        modifyConnectionIpProc.connName = name
        modifyConnectionIpProc.ipMode = mode
        modifyConnectionIpProc.ipAddress = ip
        modifyConnectionIpProc.netmask = mask
        modifyConnectionIpProc.gateway = gw
        modifyConnectionIpProc.dns1 = dns1
        modifyConnectionIpProc.dns2 = dns2
        modifyConnectionIpProc.running = true
    }
    
    // ========== PROCESSES ==========
    
    property var getCurrentConnectionProc: Process {
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "con", "show", "--active"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                root.currentSSID = ""
                root.connectionStatus = "disconnected"
                root.connectionType = "none"
                
                for (let line of lines) {
                    let parts = line.split(":")
                    if (parts.length >= 2) {
                        if (parts[1] === "802-11-wireless") {
                            root.currentSSID = parts[0]
                            root.connectionStatus = "connected"
                            root.connectionType = "wifi"
                            break
                        } else if (parts[1] === "802-3-ethernet") {
                            root.currentSSID = parts[0]
                            root.connectionStatus = "connected"
                            root.connectionType = "ethernet"
                            break
                        }
                    }
                }
                getWifiStatusProc.running = true
            }
        }
    }
    
    property var getWifiStatusProc: Process {
        command: ["nmcli", "radio", "wifi"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = this.text.trim() === "enabled"
                getIpAddressProc.running = true
            }
        }
    }
    
    property var getIpAddressProc: Process {
        command: ["sh", "-c", "ip -4 addr show | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | grep -v '127.0.0.1' | head -1"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.ipAddress = this.text.trim() || "Not connected"
                scanNetworksProc.running = true
            }
        }
    }
    
    property var scanNetworksProc: Process {
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "dev", "wifi", "list"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let networks = []
                let seen = new Set()
                
                for (let line of lines) {
                    if (!line.trim()) continue
                    let parts = line.split(":")
                    if (parts.length >= 4) {
                        let ssid = parts[0]
                        if (!ssid || seen.has(ssid)) continue
                        seen.add(ssid)
                        
                        networks.push({
                            ssid: ssid,
                            signal: parseInt(parts[1]) || 0,
                            security: parts[2] || "",
                            active: parts[3] === "*"
                        })
                    }
                }
                
                networks.sort((a, b) => {
                    if (a.active !== b.active) return a.active ? -1 : 1
                    return b.signal - a.signal
                })
                
                root.networkList = networks
            }
        }
    }
    
    property var toggleWifiProc: Process {
        property bool enable: true
        command: ["nmcli", "radio", "wifi", enable ? "on" : "off"]
        onExited: getCurrentConnectionProc.running = true
    }
    
    property var connectNetworkProc: Process {
        property string ssid: ""
        command: ["nmcli", "con", "up", ssid]
        
        onExited: (code) => {
            if (code !== 0 && root.selectedSecurity) {
                root.showPasswordDialog = true
            } else {
                getCurrentConnectionProc.running = true
            }
        }
    }
    
    property var connectWithPasswordProc: Process {
        property string ssid: ""
        property string password: ""
        command: ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
        
        onExited: {
            root.showPasswordDialog = false
            getCurrentConnectionProc.running = true
        }
    }
    
    property var disconnectNetworkProc: Process {
        command: ["nmcli", "con", "down", root.currentSSID]
        onExited: getCurrentConnectionProc.running = true
    }
    
    property var getSavedConnectionsProc: Process {
        command: ["nmcli", "-t", "-f", "NAME,TYPE,AUTOCONNECT,DEVICE", "con", "show"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                let connections = []
                
                for (let line of lines) {
                    if (!line.trim()) continue
                    let parts = line.split(":")
                    if (parts.length >= 3) {
                        let connType = parts[1]
                        if (connType === "802-11-wireless" || connType === "802-3-ethernet") {
                            connections.push({
                                name: parts[0],
                                type: connType === "802-11-wireless" ? "wifi" : "ethernet",
                                autoconnect: parts[2] === "yes",
                                device: parts[3] || "",
                                active: parts[3] && parts[3] !== "--" && parts[3] !== ""
                            })
                        }
                    }
                }
                
                root.savedConnections = connections
            }
        }
    }
    
    property var deleteConnectionProc: Process {
        property string connName: ""
        command: ["nmcli", "con", "delete", connName]
        onExited: {
            getSavedConnectionsProc.running = true
            getCurrentConnectionProc.running = true
        }
    }
    
    property var getConnectionDetailsProc: Process {
        property string connName: ""
        command: ["nmcli", "-t", "-f", "connection.id,connection.autoconnect,802-11-wireless.ssid,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns", "con", "show", connName]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n")
                
                for (let line of lines) {
                    let [key, value] = line.split(":", 2)
                    value = value || ""
                    
                    if (key === "connection.id") root.editConnName = value
                    else if (key === "connection.autoconnect") root.editConnAutoConnect = value === "yes"
                    else if (key === "802-11-wireless.ssid") root.editConnSSID = value
                    else if (key === "ipv4.method") root.editConnIpMode = value === "manual" ? "manual" : "auto"
                    else if (key === "ipv4.addresses") {
                        if (value && value !== "--") {
                            let addrParts = value.split("/")
                            root.editConnIpAddress = addrParts[0] || ""
                            root.editConnNetmask = addrParts[1] || "24"
                        }
                    }
                    else if (key === "ipv4.gateway") root.editConnGateway = value !== "--" ? value : ""
                    else if (key === "ipv4.dns") {
                        if (value && value !== "--") {
                            let dnsList = value.split(",")
                            root.editConnDns1 = dnsList[0] || ""
                            root.editConnDns2 = dnsList[1] || ""
                        }
                    }
                }
                
                root.showConnectionEditor = true
            }
        }
    }
    
    property var createWifiConnectionProc: Process {
        property string connName: ""
        property string ssid: ""
        property string password: ""
        property bool autoConnect: true
        command: ["nmcli", "con", "add", 
                  "type", "wifi",
                  "con-name", connName,
                  "ssid", ssid,
                  "wifi-sec.key-mgmt", "wpa-psk",
                  "wifi-sec.psk", password,
                  "connection.autoconnect", autoConnect ? "yes" : "no"]
        onExited: {
            root.showAddConnection = false
            getSavedConnectionsProc.running = true
        }
    }
    
    property var createEthernetConnectionProc: Process {
        property string connName: ""
        property bool autoConnect: true
        command: ["nmcli", "con", "add",
                  "type", "ethernet",
                  "con-name", connName,
                  "connection.autoconnect", autoConnect ? "yes" : "no"]
        onExited: {
            root.showAddConnection = false
            getSavedConnectionsProc.running = true
        }
    }
    
    property var modifyConnectionIpProc: Process {
        property string connName: ""
        property string ipMode: "auto"
        property string ipAddress: ""
        property string netmask: "24"
        property string gateway: ""
        property string dns1: ""
        property string dns2: ""
        
        command: {
            if (ipMode === "auto") {
                return ["nmcli", "con", "mod", connName, "ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", "", "ipv4.dns", ""]
            } else {
                let cmd = ["nmcli", "con", "mod", connName, 
                           "ipv4.method", "manual",
                           "ipv4.addresses", ipAddress + "/" + netmask]
                if (gateway) cmd = cmd.concat(["ipv4.gateway", gateway])
                let dnsStr = [dns1, dns2].filter(d => d).join(",")
                if (dnsStr) cmd = cmd.concat(["ipv4.dns", dnsStr])
                return cmd
            }
        }
        
        onExited: {
            root.showConnectionEditor = false
            getSavedConnectionsProc.running = true
            if (root.currentSSID === connName) {
                reconnectProc.connName = connName
                reconnectProc.running = true
            }
        }
    }
    
    property var reconnectProc: Process {
        property string connName: ""
        command: ["sh", "-c", "nmcli con down '" + connName + "' && nmcli con up '" + connName + "'"]
        onExited: getCurrentConnectionProc.running = true
    }
}
