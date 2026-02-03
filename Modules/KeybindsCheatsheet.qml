/*
* ============================================================================
* KEYBINDS CHEATSHEET
* ============================================================================
*
* Display Hyprland keybinds in a searchable overlay.
*
* ============================================================================
*/

pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

import "../misc"

PopupWindow {
    id: root

    required property var parentBar

    // ========================================================================
    //                              PROPERTIES
    // ========================================================================

    property bool isOpen: ShellState.cheatsheetVisible
        property bool isClosing: false
            property var categories: []
            property string searchQuery: ""

                // ========================================================================
                //                              WINDOW CONFIG
                // ========================================================================

                anchor.window: parentBar
                anchor.rect.x: (parentBar?.width ?? 0) / 2 - implicitWidth / 2
                anchor.rect.y: Config.barHeight + Config.topMargin + 24

                implicitWidth: 720
                implicitHeight: 520

                visible: isOpen || isClosing
                color: "transparent"

                onIsOpenChanged: {
                    if (!isOpen)
                    {
                        isClosing = true
                        closeTimer.start()
                    }
                }

                onVisibleChanged: {
                    if (visible)
                    {
                        keybindsReader.running = true
                        searchField.text = ""
                        searchQuery = ""
                    }
                }

                // ========================================================================
                //                              KEY MAPPINGS
                // ========================================================================

                readonly property var keyMap: ({
                    "SPACE": "Space", "RETURN": "Enter", "ENTER": "Enter",
                    "ESCAPE": "Esc", "ESC": "Esc", "TAB": "Tab",
                    "BACKSPACE": "⌫", "DELETE": "Del",
                    "UP": "↑", "DOWN": "↓", "LEFT": "←", "RIGHT": "→",
                    "PRINT": "PrtSc", "SLASH": "/", "MINUS": "-", "EQUAL": "=",
                    "COMMA": ", ", "PERIOD": ".",
                    "MOUSE:272": "LMB", "MOUSE:273": "RMB",
                    "MOUSE_DOWN": "Scroll ↓", "MOUSE_UP": "Scroll ↑",
                    "XF86AUDIORAISEVOLUME": "Vol +", "XF86AUDIOLOWERVOLUME": "Vol -",
                    "XF86AUDIOMUTE": "Mute", "XF86AUDIOMICMUTE": "Mic Mute",
                    "XF86AUDIOPLAY": "▶", "XF86AUDIOPAUSE": "⏸",
                    "XF86AUDIONEXT": "⏭", "XF86AUDIOPREV": "⏮", "XF86AUDIOSTOP": "⏹",
                    "XF86MONBRIGHTNESSUP": "☀+", "XF86MONBRIGHTNESSDOWN": "☀-",
                    "XF86KBDBRIGHTNESSUP": "⌨+", "XF86KBDBRIGHTNESSDOWN": "⌨-",
                    "XF86CALCULATOR": "Calc", "XF86MAIL": "Mail",
                    "XF86SEARCH": "Search", "XF86EXPLORER": "Files", "XF86HOMEPAGE": "Home"
                })

                readonly property var modMap: ({
                    "SUPER": "Super", "SHIFT": "Shift",
                    "CTRL": "Ctrl", "CONTROL": "Ctrl", "ALT": "Alt"
                })

                // ========================================================================
                //                              HELPERS
                // ========================================================================

                function getKeyDisplay(key: string): string
                {
                    const k = key.toUpperCase()
                    return keyMap[k] ?? k
                }

                function getModDisplay(mod: string): string
                {
                    const m = mod.toUpperCase().trim()
                    return modMap[m] ?? m
                }

                function getTotalCount(): int
                {
                    let count = 0
                    for (const cat of categories) count += cat.binds.length
                        return count
                    }

                    function getFilteredCategories(): var
                    {
                        if (!searchQuery) return categories

                        const query = searchQuery.toLowerCase()
                        return categories.map(cat => ({
                        category: cat.category,
                        binds: cat.binds.filter(b =>
                        b.description.toLowerCase().includes(query) ||
                        b.key.toLowerCase().includes(query) ||
                        b.mods.toLowerCase().includes(query)
                    )
                })).filter(cat => cat.binds.length > 0)
            }

            function parseKeybinds(content: string): void
            {
                const lines = content.split('\n')
                let result = []
                let currentCategory = "General"
                let currentBinds = []

                for (const line of lines) {
                    const trimmed = line.trim()

                    if (trimmed.startsWith('##'))
                    {
                    if (currentBinds.length > 0) {
                        result.push({ category: currentCategory, binds: currentBinds })
                    }
                    currentCategory = trimmed.substring(2).trim()
                    currentBinds = []
                    continue
                }

                if (trimmed.match(/^bind[a-z]*d\s*=/))
                {
                    const parts = trimmed.replace(/^bind[a-z]*d\s*=\s*/, '').split(', ')
                    if (parts.length >= 4)
                    {
                        const mods = parts[0].trim()
                        const key = parts[1].trim()
                        let desc = parts[2].trim()
                        if (desc) desc = desc.charAt(0).toUpperCase() + desc.slice(1)

                        currentBinds.push({ mods, key, description: desc })
                    }
                }
            }

            if (currentBinds.length > 0)
            {
            result.push({ category: currentCategory, binds: currentBinds })
            }

            categories = result
        }

        // ========================================================================
        //                              TIMERS & PROCESS
        // ========================================================================

        Timer {
            id: closeTimer
            interval: Config.animSpring
            onTriggered: root.isClosing = false
        }

        Process {
            id: keybindsReader
            command: ["cat", "/home/okami/.config/hypr/defaults/keybinds.conf"]
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => root.parseKeybinds(data)
            }
        }

        HyprlandFocusGrab {
            active: root.visible
            windows: [root]
            onCleared: ShellState.cheatsheetVisible = false
        }

        // ========================================================================
        //                              MAIN CONTENT
        // ========================================================================

        Rectangle {
            id: container
            anchors.fill: parent
            radius: Config.panelRadius
            color: Qt.rgba(Config.backgroundColor.r, Config.backgroundColor.g, Config.backgroundColor.b, 0.95)
            border.width: 1
            border.color: Config.borderColor

            opacity: root.isOpen ? 1 : 0
            scale: root.isOpen ? 1 : 0.9
            transformOrigin: Item.Top

            Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: Config.animSpring; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: "#40000000"
                shadowBlur: 1.2
                shadowVerticalOffset: 8
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Config.padding
                spacing: Config.spacing

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacing

                    Rectangle {
                        width: 48; height: 48; radius: Config.smallRadius
                        color: Config.accentColorDim

                        Text {
                            anchors.centerIn: parent
                            text: "keyboard"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 28
                            color: Config.accentColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Keyboard Shortcuts"
                            font { family: Config.fontFamily; pixelSize: 18; weight: Font.Medium }
                            color: Config.foregroundColor
                        }

                        Text {
                            text: root.getTotalCount() + " keybinds configured"
                            font { family: Config.fontFamily; pixelSize: 12 }
                            color: Config.dimmedColor
                        }
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: closeBtn.containsMouse ? Config.surfaceColorHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Config.iconSize
                            color: Config.dimmedColor
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

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "search"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Config.iconSize
                            color: Config.dimmedColor
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font { family: Config.fontFamily; pixelSize: 14 }
                            color: Config.foregroundColor
                            clip: true

                            Text {
                                anchors.fill: parent
                                visible: !searchField.text && !searchField.activeFocus
                                text: "Search keybinds..."
                                font { family: Config.fontFamily; pixelSize: 14 }
                                color: Config.dimmedColor
                                verticalAlignment: Text.AlignVCenter
                            }

                            onTextChanged: root.searchQuery = text
                            Keys.onEscapePressed: text ? text = "" : ShellState.cheatsheetVisible = false
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Config.borderColor }

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
                            model: root.getFilteredCategories()

                            delegate: CategorySection {
                                required property var modelData
                                categoryData: modelData
                            }
                        }

                        // Empty state
                        Item {
                            Layout.fillWidth: true
                            height: 120
                            visible: root.getFilteredCategories().length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 12

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.categories.length === 0 ? "hourglass_empty" : "search_off"
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 48
                                    color: Config.dimmedColor
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.categories.length === 0 ? "Loading keybinds..." : "No matching shortcuts"
                                    font { family: Config.fontFamily; pixelSize: 14 }
                                    color: Config.dimmedColor
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Config.borderColor }

                // Footer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Row {
                        spacing: 6
                        Rectangle {
                            width: 28; height: 22; radius: 4
                            color: Config.surfaceColor
                            border.width: 1
                            border.color: Config.borderColor

                            Text {
                                anchors.centerIn: parent
                                text: "Esc"
                                font { family: Config.fontFamily; pixelSize: 10; weight: Font.Medium }
                                color: Config.dimmedColor
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Close"
                            font { family: Config.fontFamily; pixelSize: 12 }
                            color: Config.dimmedColor
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Super + - to toggle"
                        font { family: Config.fontFamily; pixelSize: 12 }
                        color: Config.dimmedColor
                    }
                }
            }
        }

        // ========================================================================
        //                         CATEGORY SECTION
        // ========================================================================

        component CategorySection: ColumnLayout {
        id: catSection
        property var categoryData: ({})

        Layout.fillWidth: true
        spacing: 4

        // Category header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            height: 32
            spacing: 8

            Rectangle { width: 4; height: 16; radius: 2; color: Config.accentColor }

            Text {
                text: catSection.categoryData.category ?? ""
                font { family: Config.fontFamily; pixelSize: 13; weight: Font.DemiBold }
                color: Config.accentColor
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Config.borderColor }

            Text {
                text: (catSection.categoryData.binds?.length ?? 0) + " binds"
                font { family: Config.fontFamily; pixelSize: 11 }
                color: Config.dimmedColor
            }
        }

        // Keybinds
        Repeater {
            model: catSection.categoryData.binds ?? []

            delegate: KeybindRow {
                required property var modelData
                bindData: modelData
            }
        }
    }

    // ========================================================================
    //                         KEYBIND ROW
    // ========================================================================

    component KeybindRow: Rectangle {
    id: bindRow
    property var bindData: ({})

    Layout.fillWidth: true
    height: 40
    radius: Config.smallRadius
    color: bindMouse.containsMouse ? Config.surfaceColor : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

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

            Repeater {
                model: (bindRow.bindData.mods ?? "").split(" ").filter(m => m.length > 0)

                delegate: Rectangle {
                    required property string modelData
                    width: modLabel.implicitWidth + 12
                    height: 26; radius: 5
                    color: Config.surfaceColorHover
                    border.width: 1
                    border.color: Config.borderColor

                    Text {
                        id: modLabel
                        anchors.centerIn: parent
                        text: root.getModDisplay(modelData)
                        font { family: Config.fontFamily; pixelSize: 11; weight: Font.Medium }
                        color: Config.foregroundColor
                    }
                }
            }

            Text {
                visible: (bindRow.bindData.mods ?? "").length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                font { family: Config.fontFamily; pixelSize: 12 }
                color: Config.dimmedColor
            }

            Rectangle {
                width: Math.max(keyLabel.implicitWidth + 12, 28)
                height: 26; radius: 5
                color: Config.accentColor

                Text {
                    id: keyLabel
                    anchors.centerIn: parent
                    text: root.getKeyDisplay(bindRow.bindData.key ?? "")
                    font { family: Config.fontFamily; pixelSize: 11; weight: Font.Bold }
                    color: Config.onAccent
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: bindRow.bindData.description ?? ""
            font { family: Config.fontFamily; pixelSize: 13 }
            color: Config.foregroundColor
            elide: Text.ElideRight
        }
    }
}
}
