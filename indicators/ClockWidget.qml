/*
 * ============================================================================
 *                           CLOCK WIDGET
 * ============================================================================
 * 
 * FILE: indicators/ClockWidget.qml
 * PURPOSE: Displays the current time in the center of the bar
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This is a simple widget that shows the current time.
 * It uses Quickshell's SystemClock to get the current time and
 * automatically updates when the time changes.
 * 
 * ============================================================================
 *                         HOW IT WORKS
 * ============================================================================
 * 
 * 1. SYSTEM CLOCK:
 *    - SystemClock is a Quickshell component that provides current date/time
 *    - It has a 'date' property that updates automatically
 *    - 'precision' controls how often it updates:
 *      - SystemClock.Seconds - updates every second
 *      - SystemClock.Minutes - updates every minute (more efficient)
 * 
 * 2. TIME FORMATTING:
 *    - Qt.formatDateTime() formats the date according to a format string
 *    - Common format specifiers:
 *      - hh: Hour with leading zero (01-12 or 00-23 depending on locale)
 *      - mm: Minutes with leading zero (00-59)
 *      - ss: Seconds with leading zero (00-59)
 *      - AP: AM/PM indicator
 *      - dddd: Full day name (Monday, Tuesday...)
 *      - MMMM: Full month name (January, February...)
 *      - dd: Day of month (01-31)
 *      - yyyy: Full year (2024)
 * 
 * 3. SIZING:
 *    - Uses implicitWidth/Height based on text size
 *    - This allows the parent layout to properly size around it
 * 
 * ============================================================================
 *                         CUSTOMIZATION
 * ============================================================================
 * 
 * To change the time format, modify the timeFormat property:
 * 
 *   "hh:mm"       -> 14:30
 *   "hh:mm:ss"    -> 14:30:45
 *   "h:mm AP"     -> 2:30 PM
 *   "ddd, hh:mm"  -> Mon, 14:30
 * 
 * ============================================================================
 */

import Quickshell
import QtQuick

// Import configuration singleton from the misc folder
import "../misc"

/*
 * ============================================================================
 *                          MAIN WIDGET
 * ============================================================================
 * 
 * Item is the most basic visual QML element. It's invisible itself but
 * can contain visible children (like our Text). It's used here because
 * we just need a container with sizing - no background needed.
 */
Item {
    id: clockWidget
    
    /*
     * ------------------------------------------------------------------------
     *                          PROPERTIES
     * ------------------------------------------------------------------------
     * 
     * timeFormat: The format string for displaying time.
     * This can be overridden when using the component:
     *   ClockWidget { timeFormat: "hh:mm:ss" }
     */
    property string timeFormat: "hh:mm"
    
    /*
     * ------------------------------------------------------------------------
     *                          SIZING
     * ------------------------------------------------------------------------
     * 
     * implicitWidth/Height: The natural size of this component.
     * We set them to match the text's size so the clock takes up
     * exactly as much space as needed.
     * 
     * This is important for layouts - the parent RowLayout uses these
     * to know how much space to give the clock.
     */
    implicitWidth: clockText.implicitWidth
    implicitHeight: clockText.implicitHeight
    
    /*
     * ========================================================================
     *                          SYSTEM CLOCK
     * ========================================================================
     * 
     * SystemClock is a Quickshell-provided component that gives us
     * the current date and time.
     * 
     * Properties:
     *   - date: The current date/time as a JavaScript Date object
     *   - precision: How often to update (Minutes or Seconds)
     * 
     * We use Minutes precision because we're not showing seconds,
     * which means fewer updates and better performance.
     */
    SystemClock {
        id: clock
        
        // Only update once per minute (efficient since we don't show seconds)
        // Use SystemClock.Seconds if you want to show seconds
        precision: SystemClock.Minutes
    }
    
    /*
     * ========================================================================
     *                 TIME DISPLAY (M3 Expressive)
     * ========================================================================
     * 
     * M3 Expressive uses bolder typography with more personality.
     */
    
    // Expressive container with subtle hover effect
    Rectangle {
        id: clockContainer
        anchors.centerIn: parent
        width: clockContent.width + 16
        height: clockContent.height + 8
        radius: Config.smallRadius
        color: clockMouse.containsMouse ? Config.surfaceColorHover : "transparent"
        
        scale: clockMouse.pressed ? 0.96 : 1.0
        
        Behavior on color { ColorAnimation { duration: Config.animFast } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuart } }
        
        Row {
            id: clockContent
            anchors.centerIn: parent
            spacing: 8
            
            Text {
                id: clockText
                anchors.verticalCenter: parent.verticalCenter
                
                text: Qt.formatDateTime(clock.date, clockWidget.timeFormat)
                
                // M3 Expressive typography - bolder, more playful
                color: Config.foregroundColor
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSizeTitle
                font.weight: Font.DemiBold
            }
            
            // Date pill badge (shows day)
            Rectangle {
                visible: clockMouse.containsMouse
                anchors.verticalCenter: parent.verticalCenter
                width: dateText.width + 12
                height: 22
                radius: 11
                color: Config.accentColorSurface
                
                opacity: clockMouse.containsMouse ? 1 : 0
                scale: clockMouse.containsMouse ? 1 : 0.8
                
                Behavior on opacity { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutQuart } }
                Behavior on scale { NumberAnimation { duration: Config.animNormal; easing.type: Easing.OutBack } }
                
                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "ddd d")
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: Config.accentColor
                }
            }
        }
        
        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Could add click action here (e.g., open calendar)
        }
    }
}
