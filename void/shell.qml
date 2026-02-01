import Quickshell
import QtQuick

Scope {
    Variants {
        model: Quickshell.screens
        
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
