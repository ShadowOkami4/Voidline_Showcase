# QML Reference Guide for Quickshell

A comprehensive guide to understanding and writing QML for Quickshell desktop environment on Hyprland.

## Table of Contents
1. [QML Basics](#qml-basics)
2. [Properties](#properties)
3. [Signals & Handlers](#signals--handlers)
4. [Layouts](#layouts)
5. [Animations](#animations)
6. [Quickshell Components](#quickshell-components)
7. [Common Patterns](#common-patterns)
8. [Useful Commands](#useful-commands)

---

## QML Basics

### File Structure
```qml
// Optional: Mark as singleton (only one instance)
pragma Singleton

// Imports
import Quickshell           // Core Quickshell types
import Quickshell.Hyprland  // Hyprland integration
import Quickshell.Io        // Process, file I/O
import QtQuick              // Basic QML types
import QtQuick.Layouts      // RowLayout, ColumnLayout
import QtQuick.Controls     // Buttons, Sliders, etc.

// Relative imports (local folders)
import "../misc"

// Root component
Item {
    id: root
    
    // Properties go here
    property string myProp: "value"
    
    // Child components go here
    Rectangle {
        // ...
    }
}
```

### Component IDs
```qml
Rectangle {
    id: myRect  // Unique identifier in this file
    
    // Can reference by id:
    width: myRect.height  // Same as: width: height
}
```

---

## Properties

### Basic Types
```qml
// Strings
property string name: "Hello"

// Numbers
property int count: 10
property real opacity: 0.5    // Floating point

// Booleans
property bool visible: true

// Colors
property color bg: "#1a1a1a"
property color accent: Qt.rgba(0, 0.48, 1, 1)  // RGBA 0-1

// Lists/Arrays
property var items: ["a", "b", "c"]

// Objects
property var config: { "key": "value" }
```

### Property Modifiers
```qml
// readonly - Can't be changed after initialization
readonly property string version: "1.0"

// required - MUST be set by parent (used with Repeater/Loader)
required property int index

// alias - Reference to another property
property alias text: label.text
```

### Property Bindings
```qml
// Static value
width: 100

// Binding (auto-updates when height changes)
width: height * 2

// Complex binding
color: isActive ? "#ff0000" : "#00ff00"

// Binding with function
opacity: {
    if (isHovered) return 1.0
    if (isActive) return 0.8
    return 0.5
}
```

---

## Signals & Handlers

### Built-in Signals
```qml
Rectangle {
    // Property change signals (auto-generated)
    onWidthChanged: console.log("Width is now:", width)
    onVisibleChanged: { /* do something */ }
    
    // Component lifecycle
    Component.onCompleted: {
        // Called when component is fully created
        console.log("Component ready!")
    }
    
    Component.onDestruction: {
        // Called before component is destroyed
    }
}

MouseArea {
    onClicked: console.log("Clicked!")
    onPressed: console.log("Mouse down")
    onReleased: console.log("Mouse up")
    onEntered: console.log("Mouse entered")
    onExited: console.log("Mouse left")
}
```

### Custom Signals
```qml
Item {
    // Declare signal
    signal myEvent()
    signal dataReady(string data)
    
    // Emit signal
    function doSomething() {
        myEvent()
        dataReady("hello")
    }
}

// Connect to signal
MyItem {
    onMyEvent: console.log("Event fired!")
    onDataReady: (data) => console.log("Got:", data)
}
```

---

## Layouts

### Anchors (Position relative to parent/siblings)
```qml
Rectangle {
    // Fill parent
    anchors.fill: parent
    
    // Center in parent
    anchors.centerIn: parent
    
    // Specific edges
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    
    // With margins
    anchors.margins: 10           // All sides
    anchors.topMargin: 20         // Just top
    anchors.leftMargin: 15        // Just left
    
    // Relative to sibling
    anchors.top: otherRect.bottom
    anchors.topMargin: 8
}
```

### RowLayout (Horizontal)
```qml
RowLayout {
    spacing: 8  // Gap between children
    
    Rectangle {
        Layout.preferredWidth: 100
        Layout.fillHeight: true
    }
    
    Rectangle {
        Layout.fillWidth: true   // Take remaining space
        Layout.fillHeight: true
    }
    
    Rectangle {
        Layout.alignment: Qt.AlignVCenter
    }
}
```

### ColumnLayout (Vertical)
```qml
ColumnLayout {
    spacing: 12
    
    Text {
        Layout.fillWidth: true
    }
    
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 200
    }
    
    Item {
        Layout.fillHeight: true  // Spacer
    }
}
```

### Row/Column (Simple versions)
```qml
Row {
    spacing: 4
    // Children laid out left to right
}

Column {
    spacing: 4
    // Children laid out top to bottom
}
```

---

## Animations

### Behavior (Auto-animate property changes)
```qml
Rectangle {
    width: 100
    
    // Animate width changes
    Behavior on width {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    
    // Animate color changes
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    // Animate opacity
    Behavior on opacity {
        NumberAnimation { duration: 100 }
    }
}
```

### Easing Types
```qml
// Common easing types:
easing.type: Easing.Linear      // Constant speed
easing.type: Easing.InQuad      // Slow start
easing.type: Easing.OutQuad     // Slow end
easing.type: Easing.InOutQuad   // Slow start and end
easing.type: Easing.OutCubic    // Faster slow end (common)
easing.type: Easing.OutBack     // Slight overshoot
easing.type: Easing.OutBounce   // Bouncy
easing.type: Easing.OutElastic  // Springy
```

### States & Transitions
```qml
Rectangle {
    id: rect
    
    states: [
        State {
            name: "expanded"
            PropertyChanges { target: rect; width: 200; height: 200 }
        },
        State {
            name: "collapsed"
            PropertyChanges { target: rect; width: 50; height: 50 }
        }
    ]
    
    transitions: Transition {
        NumberAnimation {
            properties: "width,height"
            duration: 200
        }
    }
    
    // Change state
    state: isExpanded ? "expanded" : "collapsed"
}
```

---

## Quickshell Components

### PanelWindow (Dock to screen edge)
```qml
PanelWindow {
    id: bar
    
    // Which screen to appear on
    screen: modelData  // From Variants
    
    // Dock to edges
    anchors {
        top: true       // Dock to top
        left: true      // Stretch to left edge
        right: true     // Stretch to right edge
    }
    
    // Reserve space so windows don't overlap
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 36  // Height of bar
    
    // Background color (use "transparent" for custom shapes)
    color: "#1a1a1a"
    
    // Size
    implicitHeight: 36
}
```

### PopupWindow (Floating popup)
```qml
PopupWindow {
    id: popup
    
    // Anchor to another window
    property var parentBar
    anchor.window: parentBar
    anchor.rect.x: 100  // Offset from anchor
    anchor.rect.y: 50
    
    // Size
    implicitWidth: 300
    implicitHeight: 400
    
    // Visibility bound to state
    visible: ShellState.popupVisible
    
    color: "transparent"  // We draw our own background
}
```

### FloatingWindow (Standalone window)
```qml
FloatingWindow {
    implicitWidth: 600
    implicitHeight: 400
    
    visible: ShellState.windowVisible
    color: "#1a1a1a"
    
    // Content goes here
}
```

### Singleton (Global state/config)
```qml
// File: Config.qml
pragma Singleton

import Quickshell

Singleton {
    id: root
    
    readonly property color accentColor: "#007AFF"
    property bool darkMode: true
    
    function doSomething() {
        // ...
    }
}

// Usage in other files:
Rectangle {
    color: Config.accentColor
    visible: Config.darkMode
}
```

### Process (Run shell commands)
```qml
import Quickshell.Io

Process {
    id: myProcess
    
    // Command as array (safer)
    command: ["pactl", "get-sink-volume", "@DEFAULT_SINK@"]
    
    // Or with shell:
    command: ["sh", "-c", "echo hello && echo world"]
    
    // Capture output
    stdout: StdioCollector {
        onStreamFinished: {
            console.log("Output:", this.text)
        }
    }
    
    // Handle errors
    stderr: StdioCollector {
        onStreamFinished: {
            console.log("Error:", this.text)
        }
    }
}

// Run the process:
Button {
    onClicked: myProcess.running = true
}
```

### GlobalShortcut (Keyboard shortcuts)
```qml
import Quickshell.Hyprland

GlobalShortcut {
    name: "toggleLauncher"  // Used in Hyprland bind
    description: "Toggle App Launcher"
    
    onPressed: {
        ShellState.toggleLauncher()
    }
}

// Add to hyprland.conf:
// bind = SUPER, space, global, quickshell:toggleLauncher
```

### Hyprland Integration
```qml
import Quickshell.Hyprland

// Get active workspace
Text {
    text: Hyprland.focusedWorkspace?.id ?? "?"
}

// List all workspaces
Repeater {
    model: Object.values(Hyprland.workspaces)
    delegate: Text {
        text: modelData.id
    }
}

// Run Hyprland command
Button {
    onClicked: Hyprland.dispatch("workspace 3")
}

// Close popup on click outside
HyprlandFocusGrab {
    windows: [popup]
    active: popup.visible
    onCleared: popup.visible = false
}
```

### SystemClock (Time)
```qml
import Quickshell

SystemClock {
    id: clock
    precision: SystemClock.Minutes  // or .Seconds
}

Text {
    text: Qt.formatDateTime(clock.date, "hh:mm")
}
```

### DesktopEntries (Applications)
```qml
import Quickshell

// List all apps
Repeater {
    model: DesktopEntries.applications.values
    delegate: Text {
        required property var modelData
        text: modelData.name
    }
}

// Launch an app
Button {
    onClicked: {
        let app = DesktopEntries.applications.values[0]
        app.execute()
    }
}
```

---

## Common Patterns

### Repeater (Create multiple items)
```qml
Row {
    Repeater {
        model: 10  // Create 10 items (index 0-9)
        // model: myArray  // Or use an array
        
        delegate: Rectangle {
            required property int index
            required property var modelData  // If using array
            
            width: 20
            height: 20
            color: index === 0 ? "red" : "blue"
        }
    }
}
```

### Inline Component (Reusable within file)
```qml
Item {
    // Define component
    component MyButton: Rectangle {
        property string label: ""
        signal clicked()
        
        width: 100
        height: 40
        color: mouseArea.pressed ? "#333" : "#222"
        
        Text {
            anchors.centerIn: parent
            text: parent.label
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
    
    // Use component
    MyButton {
        label: "Click Me"
        onClicked: console.log("Button clicked!")
    }
}
```

### Timer
```qml
Timer {
    id: refreshTimer
    interval: 1000          // 1 second
    running: true           // Start immediately
    repeat: true            // Keep repeating
    triggeredOnStart: true  // Fire immediately on start
    
    onTriggered: {
        console.log("Timer fired!")
    }
}

// Control timer
Button {
    onClicked: {
        refreshTimer.start()   // Start
        refreshTimer.stop()    // Stop
        refreshTimer.restart() // Restart
    }
}
```

### Flickable (Scrollable area)
```qml
Flickable {
    anchors.fill: parent
    contentHeight: content.height  // Total scrollable height
    clip: true  // Hide content outside bounds
    
    Column {
        id: content
        width: parent.width
        
        // Many items here...
    }
}
```

### Loader (Dynamic loading)
```qml
Loader {
    id: pageLoader
    
    // Load different components based on condition
    sourceComponent: currentPage === "home" ? homePage : settingsPage
    
    // Or load from file
    source: "pages/" + currentPage + ".qml"
}

Component {
    id: homePage
    Rectangle { color: "red" }
}

Component {
    id: settingsPage
    Rectangle { color: "blue" }
}
```

---

## Useful Commands

### Hyprland Commands (via Hyprland.dispatch)
```bash
# Workspaces
workspace 3              # Switch to workspace 3
movetoworkspace 5        # Move window to workspace 5
movetoworkspacesilent 5  # Move without following

# Window control
togglefloating           # Toggle floating mode
fullscreen 1             # Toggle fullscreen
pin                      # Pin window (show on all workspaces)
killactive               # Close focused window

# Launch apps
exec kitty               # Run command
exec-once waybar         # Run once (for autostart)

# Layout
layoutmsg cyclenext      # Focus next window
layoutmsg swapnext       # Swap with next window
```

### pactl Commands (Audio)
```bash
# Volume
pactl set-sink-volume @DEFAULT_SINK@ 50%
pactl set-sink-mute @DEFAULT_SINK@ toggle
pactl get-sink-volume @DEFAULT_SINK@

# Devices
pactl list sinks         # Output devices
pactl list sources       # Input devices
pactl set-default-sink <name>
```

### nmcli Commands (Network)
```bash
nmcli device wifi list
nmcli device wifi connect "SSID" password "pass"
nmcli connection show
nmcli radio wifi on/off
```

### brightnessctl Commands
```bash
brightnessctl s 50%      # Set to 50%
brightnessctl s +10%     # Increase 10%
brightnessctl s 10%-     # Decrease 10%
brightnessctl g          # Get current
brightnessctl m          # Get max
```

### bluetoothctl Commands
```bash
bluetoothctl power on/off
bluetoothctl scan on/off
bluetoothctl devices
bluetoothctl connect XX:XX:XX:XX:XX:XX
bluetoothctl disconnect XX:XX:XX:XX:XX:XX
```

---

## Tips

1. **Use `console.log()` for debugging**
   ```qml
   onClicked: console.log("Value:", myProperty)
   ```

2. **Optional chaining for null safety**
   ```qml
   text: Hyprland.focusedWorkspace?.name ?? "Unknown"
   ```

3. **Qt.rgba() for colors with alpha**
   ```qml
   color: Qt.rgba(1, 1, 1, 0.1)  // White at 10% opacity
   ```

4. **Use Config singleton for shared values**
   ```qml
   color: Config.accentColor
   font.pixelSize: Config.fontSize
   ```

5. **Bind visibility to state**
   ```qml
   visible: ShellState.panelVisible
   opacity: visible ? 1 : 0
   Behavior on opacity { NumberAnimation { duration: 150 } }
   ```

6. **Material Symbols for icons**
   ```qml
   Text {
       text: "settings"  // Icon name
       font.family: "Material Symbols Outlined"
       font.pixelSize: 24
   }
   ```
   Browse icons: https://fonts.google.com/icons
