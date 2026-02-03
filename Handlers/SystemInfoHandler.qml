/*
 * ============================================================================
 *                        SYSTEM INFO HANDLER
 * ============================================================================
 * 
 * FILE: misc/SystemInfoHandler.qml
 * PURPOSE: Singleton for system information retrieval
 * 
 * ============================================================================
 *                              OVERVIEW
 * ============================================================================
 * 
 * This handler retrieves various system information:
 *   - User/hostname info
 *   - Kernel and OS details
 *   - CPU information
 *   - GPU information
 *   - Memory and storage usage
 *   - Software versions
 * 
 * Used primarily by the About page in settings.
 * 
 * ============================================================================
 *                         USEFUL COMMANDS
 * ============================================================================
 * 
 * SYSTEM INFO:
 *   uname -r                 <- Kernel version
 *   uname -m                 <- Architecture (x86_64, aarch64)
 *   hostnamectl              <- Hostname and OS info
 *   cat /etc/os-release      <- Distribution info
 *   uptime -p                <- Uptime in human format
 * 
 * CPU INFO:
 *   lscpu                    <- CPU details
 *   cat /proc/cpuinfo        <- Low-level CPU info
 *   nproc                    <- Number of threads
 *   cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
 * 
 * GPU INFO:
 *   lspci | grep VGA         <- GPU model
 *   glxinfo | grep "OpenGL renderer"
 * 
 * MEMORY:
 *   free -h                  <- Memory in human format
 *   cat /proc/meminfo        <- Detailed memory info
 * 
 * STORAGE:
 *   df -h /                  <- Disk usage of root
 *   lsblk                    <- Block devices
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
    //                     SYSTEM PROPERTIES
    // ========================================================================
    
    property string hostname: ""       // Computer name
    property string username: ""       // Current user
    property string kernel: ""         // Kernel version (e.g., "6.6.10-arch1-1")
    property string uptime: ""         // Uptime (e.g., "3 hours, 24 minutes")
    property string shell: ""          // User's shell (e.g., "/bin/zsh")
    property string distro: ""         // Distribution name (e.g., "Arch Linux")
    property string architecture: ""   // CPU arch (e.g., "x86_64")
    property string sessionType: ""    // "wayland" or "x11"
    
    // ========================================================================
    //                     CPU PROPERTIES
    // ========================================================================
    
    property string cpu: ""            // CPU model name
    property string cpuCores: ""       // Physical cores
    property string cpuThreads: ""     // Logical threads
    property string cpuGovernor: ""    // Power governor (performance, powersave, etc.)
    property string cpuFreq: ""        // Current frequency
    
    // ========================================================================
    //                     GPU PROPERTIES
    // ========================================================================
    
    property string gpu: ""            // GPU model name
    
    // ========================================================================
    //                     MEMORY PROPERTIES
    // ========================================================================
    
    property string memoryTotal: ""    // Total RAM
    property string memoryUsed: ""     // Used RAM
    property string swapTotal: ""      // Total swap
    property string swapUsed: ""       // Used swap
    
    // ========================================================================
    //                     STORAGE PROPERTIES
    // ========================================================================
    
    property string storageTotal: ""   // Root partition total
    property string storageUsed: ""    // Root partition used
    
    // ========================================================================
    //                     VERSION PROPERTIES
    // ========================================================================
    
    property string quickshellVersion: ""  // Quickshell version
    property string hyprVersion: ""        // Hyprland version
    
    // ========================================================================
    //                     REFRESH FUNCTION
    // ========================================================================
    // Runs all info-gathering processes
    function refresh() {
        getHostnameProc.running = true
        getUsernameProc.running = true
        getKernelProc.running = true
        getUptimeProc.running = true
        getShellProc.running = true
        getDistroProc.running = true
        getArchProc.running = true
        getSessionTypeProc.running = true
        getCpuProc.running = true
        getCpuGovernorProc.running = true
        getGpuProc.running = true
        getMemoryProc.running = true
        getStorageProc.running = true
        getQuickshellVersionProc.running = true
        getHyprVersionProc.running = true
    }
    
    // ========================================================================
    //                     PROCESSES
    // ========================================================================
    
    property var getHostnameProc: Process {
        command: ["sh", "-c", "cat /etc/hostname 2>/dev/null || cat /proc/sys/kernel/hostname"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hostname = this.text.trim()
            }
        }
    }
    
    property var getUsernameProc: Process {
        command: ["whoami"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.username = this.text.trim()
            }
        }
    }
    
    property var getKernelProc: Process {
        command: ["uname", "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.kernel = this.text.trim()
            }
        }
    }
    
    property var getUptimeProc: Process {
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.uptime = this.text.trim().replace("up ", "")
            }
        }
    }
    
    property var getShellProc: Process {
        command: ["sh", "-c", "basename $SHELL"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.shell = this.text.trim()
            }
        }
    }
    
    property var getDistroProc: Process {
        command: ["sh", "-c", "grep '^PRETTY_NAME=' /etc/os-release | cut -d'\"' -f2"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.distro = this.text.trim()
            }
        }
    }
    
    property var getArchProc: Process {
        command: ["uname", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.architecture = this.text.trim()
            }
        }
    }
    
    property var getSessionTypeProc: Process {
        command: ["sh", "-c", "echo $XDG_SESSION_TYPE"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.sessionType = this.text.trim()
            }
        }
    }
    
    property var getCpuProc: Process {
        command: ["sh", "-c", "LANG=C lscpu"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                for (let line of lines) {
                    if (line.startsWith("Model name:")) {
                        root.cpu = line.split(':').slice(1).join(':').trim().replace(/\s+/g, ' ')
                    } else if (line.startsWith("CPU(s):")) {
                        root.cpuThreads = line.split(':')[1].trim()
                    } else if (line.startsWith("Core(s) per socket:")) {
                        root.cpuCores = line.split(':')[1].trim()
                    } else if (line.startsWith("CPU max MHz:")) {
                        let mhz = parseFloat(line.split(':')[1].trim())
                        root.cpuFreq = (mhz / 1000).toFixed(2) + " GHz"
                    }
                }
            }
        }
    }
    
    property var getCpuGovernorProc: Process {
        command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.cpuGovernor = this.text.trim()
            }
        }
    }
    
    property var getGpuProc: Process {
        command: ["sh", "-c", "lspci | grep -i 'vga\\|3d\\|display' | head -1 | sed 's/.*: //'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.gpu = this.text.trim()
            }
        }
    }
    
    property var getMemoryProc: Process {
        command: ["sh", "-c", "LANG=C free -h"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split('\n')
                for (let line of lines) {
                    let parts = line.split(/\s+/)
                    if (line.startsWith("Mem:")) {
                        root.memoryTotal = parts[1]
                        root.memoryUsed = parts[2]
                    } else if (line.startsWith("Swap:")) {
                        root.swapTotal = parts[1]
                        root.swapUsed = parts[2]
                    }
                }
            }
        }
    }
    
    property var getStorageProc: Process {
        command: ["sh", "-c", "df -h / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(/\s+/)
                if (parts.length >= 4) {
                    root.storageTotal = parts[1]
                    root.storageUsed = parts[2]
                }
            }
        }
    }
    
    property var getQuickshellVersionProc: Process {
        command: ["sh", "-c", "quickshell --version 2>/dev/null | head -1 || echo 'Unknown'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.quickshellVersion = this.text.trim()
            }
        }
    }
    
    property var getHyprVersionProc: Process {
        command: ["sh", "-c", "hyprctl version -j 2>/dev/null | jq -r '.tag // .version' || echo 'Unknown'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.hyprVersion = this.text.trim()
            }
        }
    }
}
