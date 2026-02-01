pragma Singleton
import QtQuick

QtObject {
    property bool actionCenterVisible: false
    
    function toggleActionCenter() {
        actionCenterVisible = !actionCenterVisible
    }
}
