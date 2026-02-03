/*
* ============================================================================
* SYSTEM INDICATORS
* ============================================================================
*
* FILE: indicators/SystemIndicators.qml
* PURPOSE: Right-side icons showing volume, network, and battery status
*
* ============================================================================
* OVERVIEW
* ============================================================================
*
* This widget displays a row of system status icons:
* - Volume: Shows speaker icon, opens SoundPanel on click
* - Network: Shows WiFi icon, opens NetworkPanel on click
* - Battery: Shows battery level (only visible on laptops)
*
* ============================================================================
* HOW IT WORKS
* ============================================================================
*
* 1. VOLUME INDICATOR:
* - Uses pactl commands to get current volume/mute state
* - Process components run commands and capture output
* - Timer refreshes every 2 seconds to stay in sync
* - Icon changes based on volume level and mute state
*
* 2. NETWORK INDICATOR:
* - Currently shows static WiFi icon
* - Could be extended to show different icons based on connection
* - Clicking opens the NetworkPanel
*
* 3. BATTERY INDICATOR:
* - Uses UPower service (standard Linux power management)
* - UPower.displayDevice gives the main battery
* - Shows different icons based on charge level
* - Shows charging icon when plugged in
* - Only visible when battery is present (hides on desktops)
*
* 4. INLINE COMPONENT (IconButton):
* - Defines a reusable component inside this file
* - 'component Name: Type' syntax creates an inline component
* - Can only be used within this file
* - Avoids creating a separate file for simple helper components
*
* ============================================================================
* MATERIAL SYMBOLS ICONS
* ============================================================================
*
* We use the Material Symbols Outlined font for icons.
* Icons are specified by name (e.g., "volume_up", "wifi", "battery_full").
*
* Common icons:
* Volume: volume_up, volume_down, volume_mute, volume_off
* Network: wifi, wifi_off, signal_cellular_4_bar, ethernet
* Battery: battery_full, battery_5_bar, battery_3_bar, battery_2_bar,
* battery_1_bar, battery_charging_full
*
* Browse icons: https://fonts.google.com/icons
*
* ============================================================================
* UPOWER BATTERY STATES
* ============================================================================
*
* UPower.displayDevice.state can be:
* - UPowerDeviceState.Unknown
* - UPowerDeviceState.Charging
* - UPowerDeviceState.Discharging
* - UPowerDeviceState.Empty
* - UPowerDeviceState.FullyCharged
* - UPowerDeviceState.PendingCharge
* - UPowerDeviceState.PendingDischarge
*
* ============================================================================
*/

import Quickshell
import Quickshell.Io                // Process, StdioCollector
import Quickshell.Services.UPower   // Battery info
import QtQuick
import QtQuick.Layouts

// Import singletons from the misc folder
import "../misc"
import "../Handlers"

/*
* ============================================================================
* MAIN WIDGET
* ============================================================================
*
* Row: Simple horizontal layout. Children are placed left to right.
*/
Row {
    id: systemIndicators

    // Space between icons
    spacing: Config.spacing

    /*
    * ========================================================================
    * VOLUME STATE PROPERTIES
    * ========================================================================
    *
    * These store the current audio state.
    * Updated by Process components below.
    */
    property bool volumeMuted: false    // Is output muted?
        property int volumeLevel: 50        // Volume percentage (0-100)

        /*
        * ========================================================================
        * NETWORK STATE PROPERTIES
        * ========================================================================
        */
        property string connectionType: "none"  // "wifi", "ethernet", or "none"
            property string connectionStatus: "disconnected"  // "connected" or "disconnected"

                /*
                * ========================================================================
                * PROCESS: GET VOLUME LEVEL
                * ========================================================================
                *
                * Runs pactl to get the current sink (output) volume.
                * running: true means start immediately when component loads.
                */
                Process {
                    id: volumeProc
                    command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
                    running: true  // Start on component creation

                    stdout: StdioCollector {
                        onStreamFinished: {
                            // Parse "Volume: front-left: 65536 / 100% / 0.00 dB..."
                            // Extract the percentage with regex
                            let match = this.text.match(/(\d+)%/)
                            if (match)
                            {
                                systemIndicators.volumeLevel = parseInt(match[1])
                            }

                            // Chain to get mute status next
                            muteProc.running = true
                        }
                    }
                }

                /*
                * ========================================================================
                * PROCESS: GET MUTE STATE
                * ========================================================================
                */
                Process {
                    id: muteProc
                    command: ["pactl", "get-sink-mute", "@DEFAULT_SINK@"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            // Output is "Mute: yes" or "Mute: no"
                            systemIndicators.volumeMuted = this.text.includes("yes")
                        }
                    }
                }

                /*
                * ========================================================================
                * REFRESH TIMER
                * ========================================================================
                *
                * Periodically refresh volume state to stay in sync with
                * external changes (e.g., keyboard volume keys).
                */
                Timer {
                    interval: 2000    // Every 2 seconds
                    running: true     // Always running
                    repeat: true      // Repeat indefinitely
                    onTriggered: {
                        volumeProc.running = true
                        networkProc.running = true
                    }
                }

                /*
                * ========================================================================
                * PROCESS: GET NETWORK STATUS
                * ========================================================================
                */
                Process {
                    id: networkProc
                    command: ["nmcli", "-t", "-f", "NAME, TYPE, DEVICE", "con", "show", "--active"]
                    running: true

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n")
                            systemIndicators.connectionStatus = "disconnected"
                            systemIndicators.connectionType = "none"

                            for (let line of lines) {
                                let parts = line.split(":")
                                if (parts.length >= 2)
                                {
                                if (parts[1] === "802-11-wireless") {
                                    systemIndicators.connectionStatus = "connected"
                                    systemIndicators.connectionType = "wifi"
                                    break
                                } else if (parts[1] === "802-3-ethernet") {
                                systemIndicators.connectionStatus = "connected"
                                systemIndicators.connectionType = "ethernet"
                                break
                            }
                        }
                    }
                }
            }
        }

        /*
        * ========================================================================
        * UNIFIED STATUS PILL (Vol, Net, BT)
        * ========================================================================
        * Combines multiple status icons into one clickable button
        * that opens the Action Center.
        */
        Rectangle {
            id: statusPill
            height: 36
            width: statusRow.width + 24
            radius: 18
            color: statusMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor

            scale: statusMouse.pressed ? 0.94 : 1.0

            Behavior on color { ColorAnimation { duration: Config.animFast } }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }

            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 12

                // Volume Icon
                Text {
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: systemIndicators.volumeMuted ? Config.errorColor : Config.foregroundColor

                    text: {
                        if (systemIndicators.volumeMuted) return "volume_off"
                        if (systemIndicators.volumeLevel > 66) return "volume_up"
                        if (systemIndicators.volumeLevel > 33) return "volume_down"
                        if (systemIndicators.volumeLevel > 0) return "volume_mute"
                        return "volume_off"
                    }
                }

                // Network Icon
                Text {
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: systemIndicators.connectionStatus === "connected" ? Config.foregroundColor : Config.dimmedColor

                    text: {
                        if (systemIndicators.connectionType === "ethernet") return "lan"
                        if (systemIndicators.connectionType === "wifi") return "wifi"
                        return "wifi_off"
                    }
                }

                // Bluetooth Icon
                Text {
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: (BluetoothHandler.powered && BluetoothHandler.pairedDevices.some(d => d.connected)) ? Config.foregroundColor : Config.dimmedColor
                    visible: BluetoothHandler.powered // Only show if BT is on

                    text: {
                        if (!BluetoothHandler.powered) return "bluetooth_disabled"
                        if (BluetoothHandler.discovering) return "bluetooth_searching"
                        let hasConnected = BluetoothHandler.pairedDevices.some(d => d.connected)
                        if (hasConnected) return "bluetooth_connected"
                        return "bluetooth"
                    }
                }
            }

            MouseArea {
                id: statusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggleActionCenter()
            }
        }

        /*
        * ========================================================================
        * BATTERY INDICATOR (M3 Expressive)
        * ========================================================================
        * Expressive battery pill with percentage inside
        * Click to toggle time remaining display
        */
        Rectangle {
            id: batteryIndicator
            visible: UPower.displayDevice.isPresent
            width: batteryRow.width + 14
            height: 36
            radius: 18
            color: batteryMouse.containsMouse ? Config.surfaceColorHover : Config.surfaceColor

            scale: batteryMouse.pressed ? 0.94 : 1.0

            Behavior on color { ColorAnimation { duration: Config.animFast } }
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }

            property int batteryPercent: Math.round(UPower.displayDevice.percentage * 100)
            property bool isCharging: UPower.displayDevice.state === UPowerDeviceState.Charging
            property bool isLow: batteryPercent <= 20
            property bool showTime: false
            
            // Time formatting helper
            function formatTime(seconds) {
                if (seconds <= 0) return ""
                let hours = Math.floor(seconds / 3600)
                let mins = Math.floor((seconds % 3600) / 60)
                if (hours > 0) {
                    return hours + "h " + mins + "m"
                }
                return mins + "m"
            }
            
            property string timeRemaining: {
                if (isCharging) {
                    return formatTime(UPower.displayDevice.timeToFull)
                } else {
                    return formatTime(UPower.displayDevice.timeToEmpty)
                }
            }

                    Row {
                        id: batteryRow
                        anchors.centerIn: parent
                        spacing: 4

                        // Battery icon
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 24
                            color: {
                                if (batteryIndicator.isCharging) return Config.successColor
                                if (batteryIndicator.isLow) return Config.errorColor
                                return Config.foregroundColor
                            }

                            Behavior on color { ColorAnimation { duration: Config.animNormal } }

                            text: {
                                let pct = batteryIndicator.batteryPercent
                                let charging = batteryIndicator.isCharging

                                if (charging)
                                {

                                    return "battery_android_bolt"
                                }

                                if (pct >= 95) return "battery_android_full"
                                if (pct >= 85) return "battery_android_5"
                                if (pct >= 70) return "battery_android_4"
                                if (pct >= 55) return "battery_android_3"
                                if (pct >= 40) return "battery_android_2"
                                if (pct >= 25) return "battery_android_1"
                                if (pct >= 10) return "battery_android_0"
                                return "battery_android_0"
                            }
                        }

                        // Battery percentage or time
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: Config.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: {
                                if (batteryIndicator.isCharging) return Config.successColor
                                if (batteryIndicator.isLow) return Config.errorColor
                                return Config.foregroundColor
                            }

                            Behavior on color { ColorAnimation { duration: Config.animNormal } }

                            text: {
                                if (batteryIndicator.showTime && batteryIndicator.timeRemaining) {
                                    return batteryIndicator.timeRemaining + (batteryIndicator.isCharging ? " left" : "")
                                }
                                return batteryIndicator.batteryPercent + "%"
                            }
                        }
                    }

                    MouseArea {
                        id: batteryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: batteryIndicator.showTime = !batteryIndicator.showTime
                    }
                }
            }