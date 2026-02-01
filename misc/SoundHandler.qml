/*
 * ============================================================================
 *                           SOUND HANDLER
 * ============================================================================
 * 
 * FILE: misc/SoundHandler.qml
 * PURPOSE: Singleton for PulseAudio/PipeWire sound management
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This handler manages all audio functionality:
 *   - Discovering output devices (speakers, headphones)
 *   - Discovering input devices (microphones)
 *   - Controlling volume and mute state
 *   - Managing per-application audio streams
 *   - Moving streams between devices
 * 
 * Works with both PulseAudio and PipeWire (via pactl compatibility).
 * 
 * ============================================================================
 *                         QML CONCEPTS USED
 * ============================================================================
 * 
 * QTOBJECT:
 *   - Pure logic component, no visual representation
 *   - Use instead of Item when you don't need positioning
 *   - Lighter weight than Item
 * 
 * PROCESS (from Quickshell.Io):
 *   - Runs shell commands and captures output
 *   - command: ["executable", "arg1", "arg2"]
 *   - running: true  <- starts the process
 *   - stdout: StdioCollector { } captures output
 * 
 * STDIOCOLLECTOR:
 *   - Collects output from a Process
 *   - this.text contains the full output
 *   - onStreamFinished: called when command completes
 * 
 * PROPERTY VAR:
 *   - JavaScript variable type (can hold arrays, objects, etc.)
 *   - property var outputDevices: []  <- starts as empty array
 *   - Changing this triggers UI updates for bound properties
 * 
 * ============================================================================
 *                         AUDIO TERMINOLOGY
 * ============================================================================
 * 
 * SINK: Output device (speakers, headphones)
 *   - Where audio goes TO
 *   - pactl list sinks  <- shows all output devices
 * 
 * SOURCE: Input device (microphone, line-in)
 *   - Where audio comes FROM
 *   - pactl list sources  <- shows all input devices
 *   - Note: ".monitor" sources are loopback devices, we filter them out
 * 
 * SINK-INPUT: Application playing audio
 *   - A stream going TO a sink
 *   - Example: Firefox playing YouTube
 *   - pactl list sink-inputs  <- shows all playing apps
 * 
 * SOURCE-OUTPUT: Application recording audio
 *   - A stream coming FROM a source
 *   - Example: Discord using microphone
 *   - pactl list source-outputs  <- shows all recording apps
 * 
 * ============================================================================
 *                         USEFUL PACTL COMMANDS
 * ============================================================================
 * 
 * List all sinks (output devices):
 *   pactl list sinks
 *   pactl -f json list sinks    <- JSON format
 * 
 * Get/set default sink:
 *   pactl get-default-sink
 *   pactl set-default-sink <sink-name>
 * 
 * Set sink volume (0-100%):
 *   pactl set-sink-volume <sink-name> 75%
 * 
 * Toggle mute:
 *   pactl set-sink-mute <sink-name> toggle
 * 
 * Move application to different device:
 *   pactl move-sink-input <app-index> <sink-name>
 * 
 * ============================================================================
 *                         EXTENDING THIS HANDLER
 * ============================================================================
 * 
 * ADD NEW FUNCTION:
 *   1. Create the function in the QtObject
 *   2. Create a Process property for the command
 *   3. Call refresh() after the command if state changed
 * 
 * Example - add equalizer control:
 *   function setEqualizer(preset) {
 *       equalizerProc.preset = preset
 *       equalizerProc.running = true
 *   }
 *   
 *   property var equalizerProc: Process {
 *       property string preset
 *       command: ["some-eq-command", preset]
 *   }
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
 * 
 * QtObject is used here instead of Item because:
 * - This is purely for data/logic, no visuals needed
 * - More lightweight than Item
 * - pragma Singleton + qmldir registration makes it globally accessible
 */
QtObject {
    id: root
    
    // ========================================================================
    //                     STATE PROPERTIES
    // ========================================================================
    // These hold the current state of the audio system.
    // Other components bind to these for reactive updates.
    
    // List of output devices (speakers, headphones)
    // Each item: { name: string, description: string, volume: number, muted: bool }
    property var outputDevices: []
    
    // List of input devices (microphones)
    // Same structure as outputDevices
    property var inputDevices: []
    
    // List of apps currently playing audio
    // Each item: { index: number, name: string, volume: number, muted: bool, sink: string }
    property var playbackStreams: []
    
    // List of apps currently recording audio
    property var recordingStreams: []
    
    // Name of the default output device
    property string defaultSink: ""
    
    // Name of the default input device
    property string defaultSource: ""
    
    // ========================================================================
    //                     REFRESH FUNCTION
    // ========================================================================
    // Call this to reload all audio data from the system.
    // Triggers a chain: sinks -> default sink -> sources -> default source -> streams
    function refresh() {
        listSinksProc.running = true
    }
    
    // ========================================================================
    //                     SINK (OUTPUT) FUNCTIONS
    // ========================================================================
    
    // Timer to debounce volume changes (sliders)
    property var pendingVolumeAction: null
    property var volumeDebounceTimer: Timer {
        interval: 50
        onTriggered: {
            if (root.pendingVolumeAction) {
                root.pendingVolumeAction()
                root.pendingVolumeAction = null
            }
        }
    }
    
    // Set which output device is the default
    function setDefaultSink(sink) {
        setDefaultSinkProc.sink = sink
        setDefaultSinkProc.running = true
    }
    
    // Set volume for an output device (0-100)
    function setSinkVolume(sink, volume) {
        root.pendingVolumeAction = function() {
            setSinkVolumeProc.sink = sink
            setSinkVolumeProc.vol = volume
            setSinkVolumeProc.running = true
        }
        volumeDebounceTimer.restart()
    }
    
    // Toggle mute for an output device
    function toggleSinkMute(sink) {
        toggleSinkMuteProc.sink = sink
        toggleSinkMuteProc.running = true
    }
    
    // ========================================================================
    //                     SOURCE (INPUT) FUNCTIONS
    // ========================================================================
    
    // Set which input device is the default
    function setDefaultSource(source) {
        setDefaultSourceProc.source = source
        setDefaultSourceProc.running = true
    }
    
    // Set volume for an input device (0-100)
    function setSourceVolume(source, volume) {
        root.pendingVolumeAction = function() {
            setSourceVolumeProc.source = source
            setSourceVolumeProc.vol = volume
            setSourceVolumeProc.running = true
        }
        volumeDebounceTimer.restart()
    }
    
    // Toggle mute for an input device
    function toggleSourceMute(source) {
        toggleSourceMuteProc.source = source
        toggleSourceMuteProc.running = true
    }
    
    // ========================================================================
    //                     SINK INPUT (APP PLAYBACK) FUNCTIONS
    // ========================================================================
    
    // Set volume for an app's audio stream
    function setSinkInputVolume(index, volume) {
        root.pendingVolumeAction = function() {
            setSinkInputVolumeProc.idx = index
            setSinkInputVolumeProc.vol = volume
            setSinkInputVolumeProc.running = true
        }
        volumeDebounceTimer.restart()
    }
    
    // Toggle mute for an app's audio stream
    function toggleSinkInputMute(index) {
        toggleSinkInputMuteProc.idx = index
        toggleSinkInputMuteProc.running = true
    }
    
    // Move an app's audio to a different output device
    function moveSinkInput(index, sink) {
        moveSinkInputProc.idx = index
        moveSinkInputProc.sink = sink
        moveSinkInputProc.running = true
    }
    
    // ========================================================================
    //                     SOURCE OUTPUT (APP RECORDING) FUNCTIONS
    // ========================================================================
    
    // Set volume for an app's recording stream
    function setSourceOutputVolume(index, volume) {
        root.pendingVolumeAction = function() {
            setSourceOutputVolumeProc.idx = index
            setSourceOutputVolumeProc.vol = volume
            setSourceOutputVolumeProc.running = true
        }
        volumeDebounceTimer.restart()
    }
    
    // Toggle mute for an app's recording stream
    function toggleSourceOutputMute(index) {
        toggleSourceOutputMuteProc.idx = index
        toggleSourceOutputMuteProc.running = true
    }
    
    // Move an app's recording to a different input device
    function moveSourceOutput(index, source) {
        moveSourceOutputProc.idx = index
        moveSourceOutputProc.source = source
        moveSourceOutputProc.running = true
    }
    
    // ========================================================================
    //                     PROCESS DEFINITIONS
    // ========================================================================
    // Each Process runs a shell command and handles the output.
    // Processes are not run until .running = true
    
    /*
     * LIST SINKS (Output Devices)
     * Uses pactl with JSON output for easier parsing.
     * Falls back to awk-based parsing if JSON not available.
     */
    property var listSinksProc: Process {
        command: ["sh", "-c", `
            pactl -f json list sinks 2>/dev/null || pactl list sinks | awk '
            BEGIN { print "[" }
            /^Sink #/ { if(n++) print ","; print "{"; gsub(/^Sink #/,""); sink=$0 }
            /Name:/ { gsub(/^[[:space:]]*Name: /,""); print "\"name\": \"" $0 "\"," }
            /Description:/ { gsub(/^[[:space:]]*Description: /,""); gsub(/"/,"\\\\\""); print "\"description\": \"" $0 "\"," }
            /Mute:/ { print "\"mute\": " ($2=="yes" ? "true" : "false") "," }
            /Volume:/ && /front-left/ { match($0,/([0-9]+)%/,a); print "\"volume\": " a[1] }
            /^$/ { print "}" }
            END { print "]" }
            '
        `]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    let devices = data.map(sink => ({
                        name: sink.name || "",
                        description: sink.description || sink.name || "Unknown",
                        volume: sink.volume?.["front-left"]?.value_percent ? 
                                parseInt(sink.volume["front-left"].value_percent) : 
                                (typeof sink.volume === "number" ? sink.volume : 50),
                        muted: sink.mute || false
                    }))
                    root.outputDevices = devices
                } catch(e) {
                    console.log("SoundHandler: Failed to parse sinks:", e)
                }
                getDefaultSinkProc.running = true
            }
        }
    }
    
    property var getDefaultSinkProc: Process {
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaultSink = this.text.trim()
                listSourcesProc.running = true
            }
        }
    }
    
    property var listSourcesProc: Process {
        command: ["sh", "-c", `
            pactl -f json list sources 2>/dev/null | jq '[.[] | select(.name | contains(".monitor") | not)]' || pactl list sources | awk '
            BEGIN { print "[" }
            /^Source #/ { if(n++) print ","; print "{"; }
            /Name:/ { gsub(/^[[:space:]]*Name: /,""); if ($0 !~ /\\.monitor/) { print "\"name\": \"" $0 "\"," } else { skip=1 } }
            /Description:/ { if(!skip) { gsub(/^[[:space:]]*Description: /,""); gsub(/"/,"\\\\\""); print "\"description\": \"" $0 "\"," } }
            /Mute:/ { if(!skip) print "\"mute\": " ($2=="yes" ? "true" : "false") "," }
            /Volume:/ && /front-left/ { if(!skip) { match($0,/([0-9]+)%/,a); print "\"volume\": " a[1] } }
            /^$/ { if(!skip) print "}"; skip=0 }
            END { print "]" }
            '
        `]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let text = this.text.trim()
                    if (text) {
                        let data = JSON.parse(text)
                        let devices = data.filter(s => s.name && !s.name.includes(".monitor")).map(source => ({
                            name: source.name || "",
                            description: source.description || source.name || "Unknown",
                            volume: source.volume?.["front-left"]?.value_percent ? 
                                    parseInt(source.volume["front-left"].value_percent) : 
                                    (typeof source.volume === "number" ? source.volume : 50),
                            muted: source.mute || false
                        }))
                        root.inputDevices = devices
                    }
                } catch(e) {
                    console.log("SoundHandler: Failed to parse sources:", e)
                }
                getDefaultSourceProc.running = true
            }
        }
    }
    
    property var getDefaultSourceProc: Process {
        command: ["pactl", "get-default-source"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.defaultSource = this.text.trim()
                listSinkInputsProc.running = true
            }
        }
    }
    
    property var listSinkInputsProc: Process {
        command: ["sh", "-c", "pactl -f json list sink-inputs 2>/dev/null || echo \"[]\""]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    let streams = data.map(input => {
                        let appName = input.properties?.["application.name"]
                        if (appName === "(null)" || !appName) {
                            appName = input.properties?.["application.process.binary"] || input.properties?.["media.name"] || "Unknown"
                        }
                        return {
                            index: input.index,
                            name: appName,
                            icon: input.properties?.["application.icon_name"] || "",
                            volume: input.volume?.["front-left"]?.value_percent ? 
                                    parseInt(input.volume["front-left"].value_percent) : 
                                    (input.volume?.["mono"]?.value_percent ? parseInt(input.volume["mono"].value_percent) : 100),
                            muted: input.mute || false,
                            sinkIndex: input.sink
                        }
                    }).filter(s => s.name !== "Unknown" && s.name !== "(null)")
                    root.playbackStreams = streams
                } catch(e) {
                    root.playbackStreams = []
                }
                listSourceOutputsProc.running = true
            }
        }
    }
    
    property var listSourceOutputsProc: Process {
        command: ["sh", "-c", "pactl -f json list source-outputs 2>/dev/null || echo \"[]\""]
        
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text)
                    let streams = data.filter(output => {
                        let appId = output.properties?.["application.id"] || ""
                        let mediaName = output.properties?.["media.name"] || ""
                        let appName = output.properties?.["application.name"] || ""
                        
                        if (appId === "org.PulseAudio.pavucontrol") return false
                        if (mediaName.includes("Peak") || mediaName.includes("peak") || 
                            mediaName.includes("Ausschlags") || mediaName.includes("monitor")) return false
                        if (appName === "(null)" && !output.properties?.["application.process.binary"]) return false
                        
                        return true
                    }).map(output => {
                        let appName = output.properties?.["application.name"]
                        if (appName === "(null)" || !appName) {
                            appName = output.properties?.["application.process.binary"] || "Unknown"
                        }
                        return {
                            index: output.index,
                            name: appName,
                            icon: output.properties?.["application.icon_name"] || "",
                            volume: output.volume?.["front-left"]?.value_percent ? 
                                    parseInt(output.volume["front-left"].value_percent) : 
                                    (output.volume?.["mono"]?.value_percent ? parseInt(output.volume["mono"].value_percent) : 100),
                            muted: output.mute || false,
                            sourceIndex: output.source
                        }
                    })
                    root.recordingStreams = streams
                } catch(e) {
                    root.recordingStreams = []
                }
            }
        }
    }
    
    // Volume control processes
    property var setSinkVolumeProc: Process {
        property string sink: ""
        property int vol: 50
        command: ["pactl", "set-sink-volume", sink, vol + "%"]
        onExited: listSinksProc.running = true
    }
    
    property var toggleSinkMuteProc: Process {
        property string sink: ""
        command: ["pactl", "set-sink-mute", sink, "toggle"]
        onExited: listSinksProc.running = true
    }
    
    property var setDefaultSinkProc: Process {
        property string sink: ""
        command: ["pactl", "set-default-sink", sink]
        onExited: getDefaultSinkProc.running = true
    }
    
    property var setSourceVolumeProc: Process {
        property string source: ""
        property int vol: 50
        command: ["pactl", "set-source-volume", source, vol + "%"]
        onExited: listSourcesProc.running = true
    }
    
    property var toggleSourceMuteProc: Process {
        property string source: ""
        command: ["pactl", "set-source-mute", source, "toggle"]
        onExited: listSourcesProc.running = true
    }
    
    property var setDefaultSourceProc: Process {
        property string source: ""
        command: ["pactl", "set-default-source", source]
        onExited: getDefaultSourceProc.running = true
    }
    
    property var setSinkInputVolumeProc: Process {
        property int idx: 0
        property int vol: 50
        command: ["pactl", "set-sink-input-volume", idx.toString(), vol + "%"]
        onExited: listSinkInputsProc.running = true
    }
    
    property var toggleSinkInputMuteProc: Process {
        property int idx: 0
        command: ["pactl", "set-sink-input-mute", idx.toString(), "toggle"]
        onExited: listSinkInputsProc.running = true
    }
    
    property var moveSinkInputProc: Process {
        property int idx: 0
        property string sink: ""
        command: ["pactl", "move-sink-input", idx.toString(), sink]
        onExited: listSinkInputsProc.running = true
    }
    
    property var setSourceOutputVolumeProc: Process {
        property int idx: 0
        property int vol: 50
        command: ["pactl", "set-source-output-volume", idx.toString(), vol + "%"]
        onExited: listSourceOutputsProc.running = true
    }
    
    property var toggleSourceOutputMuteProc: Process {
        property int idx: 0
        command: ["pactl", "set-source-output-mute", idx.toString(), "toggle"]
        onExited: listSourceOutputsProc.running = true
    }
    
    property var moveSourceOutputProc: Process {
        property int idx: 0
        property string source: ""
        command: ["pactl", "move-source-output", idx.toString(), source]
        onExited: listSourceOutputsProc.running = true
    }
}
