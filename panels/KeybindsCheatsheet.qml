/*
 * ============================================================================
 *                         KEYBINDS CHEATSHEET
 * ============================================================================
 * 
 * FILE: panels/KeybindsCheatsheet.qml
 * PURPOSE: Display all Hyprland keybinds in a visual keyboard-style overlay
 * 
 * ============================================================================
 */

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PopupWindow {
    id: cheatsheetPanel
    
    property var parentBar
    
    // Track open state separately from visibility for exit animations
    property bool isOpen: ShellState.cheatsheetVisible
    property bool isClosing: false
    
    // Center on screen
    anchor.window: parentBar
    anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
    anchor.rect.y: Config.barHeight + Config.topMargin + 24
    
    implicitWidth: 720
    implicitHeight: 520
    
    // Stay visible during close animation
    visible: isOpen || isClosing
    color: "transparent"
    
    onIsOpenChanged: {
        if (!isOpen) {
            isClosing = true
            closeTimer.start()
        }
    }
    
    // Timer to hide after close animation
    Timer {
        id: closeTimer
        interval: Config.animSpring
        onTriggered: cheatsheetPanel.isClosing = false
    }
    
    // Parsed keybinds data - array of {category, binds: [{mods, key, description}]}
    property var categories: []
    property string searchQuery: ""
    
    // Focus grab
    HyprlandFocusGrab {
        active: cheatsheetPanel.visible
        windows: [cheatsheetPanel]
        onCleared: ShellState.cheatsheetVisible = false
    }
    
    // Read keybinds file on visibility
    onVisibleChanged: {
        if (visible) {
            keybindsReader.running = true
            searchField.text = ""
            searchQuery = ""
        }
    }
    
    // File reader for keybinds
    Process {
        id: keybindsReader
        command: ["cat", "/home/okami/.config/hypr/defaults/keybinds.conf"]
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                cheatsheetPanel.parseKeybinds(data)
            }
        }
    }
    
    // Parse keybinds from file content
    function parseKeybinds(content) {
        let lines = content.split('\n')
        let result = []
        let currentCategory = "General"
        let currentBinds = []
        
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim()
            
            // Check for category comment (##Category name)
            if (line.startsWith('##')) {
                // Save previous category if it has binds
                if (currentBinds.length > 0) {
                    result.push({
                        category: currentCategory,
                        binds: currentBinds
                    })
                }
                currentCategory = line.substring(2).trim()
                currentBinds = []
                continue
            }
            
            // Parse bindd/bindmd/bindeld/bindld lines
            if (line.match(/^bind[a-z]*d\s*=/)) {
                let parts = line.replace(/^bind[a-z]*d\s*=\s*/, '')
                
                let firstComma = parts.indexOf(',')
                if (firstComma === -1) continue
                
                let mods = parts.substring(0, firstComma).trim()
                let rest = parts.substring(firstComma + 1)
                
                let secondComma = rest.indexOf(',')
                if (secondComma === -1) continue
                
                let key = rest.substring(0, secondComma).trim()
                let rest2 = rest.substring(secondComma + 1)
                
                let thirdComma = rest2.indexOf(',')
                if (thirdComma === -1) continue
                
                let description = rest2.substring(0, thirdComma).trim()
                
                if (description.length > 0) {
                    description = description.charAt(0).toUpperCase() + description.slice(1)
                }
                
                currentBinds.push({
                    mods: mods,
                    key: key,
                    description: description
                })
            }
        }
        
        // Don't forget the last category
        if (currentBinds.length > 0) {
            result.push({
                category: currentCategory,
                binds: currentBinds
            })
        }
        
        categories = result
    }
    
    // Get total keybind count
    function getTotalCount() {
        let count = 0
        for (let i = 0; i < categories.length; i++) {
            count += categories[i].binds.length
        }
        return count
    }
    
    // Filter keybinds by search
    function getFilteredCategories() {
        if (!searchQuery || searchQuery.length === 0) return categories
        
        let query = searchQuery.toLowerCase()
        let filtered = []
        
        for (let i = 0; i < categories.length; i++) {
            let cat = categories[i]
            let matchingBinds = cat.binds.filter(function(bind) {
                return bind.description.toLowerCase().includes(query) ||
                       bind.key.toLowerCase().includes(query) ||
                       bind.mods.toLowerCase().includes(query)
            })
            
            if (matchingBinds.length > 0) {
                filtered.push({
                    category: cat.category,
                    binds: matchingBinds
                })
            }
        }
        
        return filtered
    }
    
    // Get display text for a key
    function getKeyDisplay(key) {
        let k = key.toUpperCase()
        // Special key mappings
        if (k === "SPACE") return "Space"
        if (k === "RETURN" || k === "ENTER") return "Enter"
        if (k === "ESCAPE" || k === "ESC") return "Esc"
        if (k === "TAB") return "Tab"
        if (k === "BACKSPACE") return "⌫"
        if (k === "DELETE") return "Del"
        if (k === "UP") return "↑"
        if (k === "DOWN") return "↓"
        if (k === "LEFT") return "←"
        if (k === "RIGHT") return "→"
        if (k === "PRINT") return "PrtSc"
        if (k === "SLASH") return "/"
        if (k === "MINUS") return "-"
        if (k === "EQUAL") return "="
        if (k === "COMMA") return ","
        if (k === "PERIOD") return "."
        if (k.match(/^F\d+$/)) return k
        if (k === "MOUSE:272") return "LMB"
        if (k === "MOUSE:273") return "RMB"
        if (k === "MOUSE_DOWN") return "Scroll ↓"
        if (k === "MOUSE_UP") return "Scroll ↑"
        
        // Media / XF86 keys - display with nice icons/names
        if (k === "XF86AUDIORAISEVOLUME") return "Vol +"
        if (k === "XF86AUDIOLOWERVOLUME") return "Vol -"
        if (k === "XF86AUDIOMUTE") return "Mute"
        if (k === "XF86AUDIOMICMUTE") return "Mic Mute"
        if (k === "XF86AUDIOPLAY") return "▶"
        if (k === "XF86AUDIOPAUSE") return "⏸"
        if (k === "XF86AUDIONEXT") return "⏭"
        if (k === "XF86AUDIOPREV") return "⏮"
        if (k === "XF86AUDIOSTOP") return "⏹"
        if (k === "XF86MONBRIGHTNESSUP") return "☀+"
        if (k === "XF86MONBRIGHTNESSDOWN") return "☀-"
        if (k === "XF86KBDBRIGHTNESSUP") return "⌨+"
        if (k === "XF86KBDBRIGHTNESSDOWN") return "⌨-"
        if (k === "XF86CALCULATOR") return "Calc"
        if (k === "XF86MAIL") return "Mail"
        if (k === "XF86SEARCH") return "Search"
        if (k === "XF86EXPLORER") return "Files"
        if (k === "XF86HOMEPAGE") return "Home"
        
        // Default - return as-is but capitalized
        return k
    }
    
    // Get modifier display
    function getModDisplay(mod) {
        let m = mod.toUpperCase().trim()
        if (m === "SUPER") return "Super"
        if (m === "SHIFT") return "Shift"
        if (m === "CTRL" || m === "CONTROL") return "Ctrl"
        if (m === "ALT") return "Alt"
        return m
    }
    
    // Main container
    Rectangle {
        id: container
        anchors.fill: parent
        radius: Config.panelRadius
        color: Config.backgroundColor
        border.width: 1
        border.color: Config.borderColor
        
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 1.2
            shadowVerticalOffset: 8
            shadowHorizontalOffset: 0
        }
        
        opacity: cheatsheetPanel.isOpen ? 1 : 0
        scale: cheatsheetPanel.isOpen ? 1 : 0.9
        transformOrigin: Item.Top
        
        // M3 Expressive spring animation
        Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { 
            NumberAnimation { 
                duration: Config.animSpring
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            } 
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Config.padding
            spacing: Config.spacing
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Config.spacing
                
                // Icon
                Rectangle {
                    width: 48
                    height: 48
                    radius: Config.smallRadius
                    color: Config.accentColorDim
                    
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 28
                        color: Config.accentColor
                        text: "keyboard"
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        font.family: Config.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        color: Config.foregroundColor
                        text: "Keyboard Shortcuts"
                    }
                    
                    Text {
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                        text: cheatsheetPanel.getTotalCount() + " keybinds configured"
                    }
                }
                
                // Close button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: closeBtn.containsMouse ? Config.surfaceColorHover : "transparent"
                    
                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                    
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.iconSize
                        color: Config.dimmedColor
                        text: "close"
                    }
                    
                    MouseArea {
                        id: closeBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.cheatsheetVisible = false
                    }
                }
            }
            
            // Search bar
            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Config.smallRadius
                color: Config.surfaceColor
                border.width: searchField.activeFocus ? 2 : 1
                border.color: searchField.activeFocus ? Config.accentColor : Config.borderColor
                
                Behavior on border.color { ColorAnimation { duration: Config.animFast } }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    
                    Text {
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Config.iconSize
                        color: Config.dimmedColor
                        text: "search"
                    }
                    
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Config.fontFamily
                        font.pixelSize: 14
                        color: Config.foregroundColor
                        clip: true
                        
                        Text {
                            anchors.fill: parent
                            visible: !searchField.text && !searchField.activeFocus
                            font.family: Config.fontFamily
                            font.pixelSize: 14
                            color: Config.dimmedColor
                            text: "Search keybinds..."
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onTextChanged: cheatsheetPanel.searchQuery = text
                        
                        Keys.onEscapePressed: {
                            if (text.length > 0) {
                                text = ""
                            } else {
                                ShellState.cheatsheetVisible = false
                            }
                        }
                    }
                }
            }
            
            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.borderColor
            }
            
            // Keybinds list
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: keybindsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                
                ColumnLayout {
                    id: keybindsCol
                    width: parent.width
                    spacing: 8
                    
                    Repeater {
                        model: cheatsheetPanel.getFilteredCategories()
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            
                            // Category header
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                color: "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    spacing: 8
                                    
                                    Rectangle {
                                        width: 4
                                        height: 16
                                        radius: 2
                                        color: Config.accentColor
                                    }
                                    
                                    Text {
                                        font.family: Config.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        color: Config.accentColor
                                        text: modelData.category
                                    }
                                    
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Config.borderColor
                                    }
                                    
                                    Text {
                                        font.family: Config.fontFamily
                                        font.pixelSize: 11
                                        color: Config.dimmedColor
                                        text: modelData.binds.length + " binds"
                                    }
                                }
                            }
                            
                            // Keybinds in this category
                            Repeater {
                                model: modelData.binds
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 40
                                    radius: Config.smallRadius
                                    color: bindMouse.containsMouse ? Config.surfaceColor : "transparent"
                                    
                                    Behavior on color { ColorAnimation { duration: Config.animFast } }
                                    
                                    MouseArea {
                                        id: bindMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 8
                                        spacing: 12
                                        
                                        // Key combination
                                        Row {
                                            spacing: 4
                                            Layout.preferredWidth: 180
                                            Layout.alignment: Qt.AlignVCenter
                                            
                                            // Modifier keys
                                            Repeater {
                                                model: modelData.mods ? modelData.mods.split(" ").filter(function(m) { return m.length > 0 }) : []
                                                
                                                Rectangle {
                                                    width: modText.implicitWidth + 12
                                                    height: 26
                                                    radius: 5
                                                    color: Config.surfaceColorHover
                                                    border.width: 1
                                                    border.color: Config.borderColor
                                                    
                                                    Text {
                                                        id: modText
                                                        anchors.centerIn: parent
                                                        font.family: Config.fontFamily
                                                        font.pixelSize: 11
                                                        font.weight: Font.Medium
                                                        color: Config.foregroundColor
                                                        text: cheatsheetPanel.getModDisplay(modelData)
                                                    }
                                                }
                                            }
                                            
                                            // Plus sign
                                            Text {
                                                visible: modelData.mods && modelData.mods.length > 0
                                                anchors.verticalCenter: parent.verticalCenter
                                                font.family: Config.fontFamily
                                                font.pixelSize: 12
                                                color: Config.dimmedColor
                                                text: "+"
                                            }
                                            
                                            // Main key
                                            Rectangle {
                                                width: Math.max(keyText.implicitWidth + 12, 28)
                                                height: 26
                                                radius: 5
                                                color: Config.accentColor
                                                
                                                Text {
                                                    id: keyText
                                                    anchors.centerIn: parent
                                                    font.family: Config.fontFamily
                                                    font.pixelSize: 11
                                                    font.weight: Font.Bold
                                                    color: Config.onAccent
                                                    text: cheatsheetPanel.getKeyDisplay(modelData.key)
                                                }
                                            }
                                        }
                                        
                                        // Description
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            font.family: Config.fontFamily
                                            font.pixelSize: 13
                                            color: Config.foregroundColor
                                            text: modelData.description
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Empty state
                    Item {
                        Layout.fillWidth: true
                        height: 120
                        visible: cheatsheetPanel.getFilteredCategories().length === 0
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 48
                                color: Config.dimmedColor
                                text: cheatsheetPanel.categories.length === 0 ? "hourglass_empty" : "search_off"
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                font.family: Config.fontFamily
                                font.pixelSize: 14
                                color: Config.dimmedColor
                                text: cheatsheetPanel.categories.length === 0 ? "Loading keybinds..." : "No matching shortcuts"
                            }
                        }
                    }
                }
            }
            
            // Footer
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Config.borderColor
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Row {
                    spacing: 6
                    
                    Rectangle {
                        width: 28
                        height: 22
                        radius: 4
                        color: Config.surfaceColor
                        border.width: 1
                        border.color: Config.borderColor
                        
                        Text {
                            anchors.centerIn: parent
                            font.family: Config.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Config.dimmedColor
                            text: "Esc"
                        }
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Config.fontFamily
                        font.pixelSize: 12
                        color: Config.dimmedColor
                        text: "Close"
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    font.family: Config.fontFamily
                    font.pixelSize: 12
                    color: Config.dimmedColor
                    text: "Super + - to toggle"
                }
            }
        }
    }
}
