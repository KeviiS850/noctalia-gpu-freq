import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    // Settings from plugin configuration
    property string gpuCard: pluginApi?.pluginSettings?.gpuCard ?? "card1"
    property int pollIntervalMs: pluginApi?.pluginSettings?.pollIntervalMs ?? 1500

    // Live GPU data properties (exposed to BarWidget via pluginApi.mainInstance)
    property string curFreq: "—"
    property string maxFreq: "—"
    property string minFreq: "—"
    property string boostFreq: "—"
    property string actFreq: "—"
    property string utilization: "—"
    property bool hasValidData: false

    // Timer for polling sysfs
    Timer {
        id: pollTimer
        interval: root.pollIntervalMs
        running: true
        repeat: true
        onTriggered: readGpuFreq()
    }

    // Process objects for reading sysfs files (like latency-monitor Host.qml does)
    Process {
        id: readCurProc
        command: ["cat", "/sys/class/drm/" + gpuCard + "/gt_cur_freq_mhz"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim().length > 0) curFreq = (parseInt(line.trim()) + " MHz")
            }
        }
        onExited: function(exitCode) { if (exitCode !== 0) curFreq = "—"; checkValidData(); }
    }
    Process {
        id: readMaxProc
        command: ["cat", "/sys/class/drm/" + gpuCard + "/gt_max_freq_mhz"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim().length > 0) maxFreq = (parseInt(line.trim()) + " MHz")
            }
        }
        onExited: function(exitCode) { if (exitCode !== 0) maxFreq = "—"; checkValidData(); }
    }
    Process {
        id: readMinProc
        command: ["cat", "/sys/class/drm/" + gpuCard + "/gt_min_freq_mhz"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim().length > 0) minFreq = (parseInt(line.trim()) + " MHz")
            }
        }
        onExited: function(exitCode) { if (exitCode !== 0) minFreq = "—"; checkValidData(); }
    }
    Process {
        id: readBoostProc
        command: ["cat", "/sys/class/drm/" + gpuCard + "/gt_boost_freq_mhz"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim().length > 0) boostFreq = (parseInt(line.trim()) + " MHz")
            }
        }
        onExited: function(exitCode) { if (exitCode !== 0) boostFreq = "—"; checkValidData(); }
    }
    Process {
        id: readActProc
        command: ["cat", "/sys/class/drm/" + gpuCard + "/gt_act_freq_mhz"]
        running: false
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.trim().length > 0) actFreq = (parseInt(line.trim()) + " MHz")
            }
        }
        onExited: function(exitCode) { if (exitCode !== 0) actFreq = "—"; checkValidData(); }
    }

    function checkValidData() {
        hasValidData = curFreq !== "—" || maxFreq !== "—" || actFreq !== "—"
        // Calculate utilization from current/max frequency if both available
        if (curFreq !== "—" && maxFreq !== "—") {
            var curVal = parseInt(curFreq)
            var maxVal = parseInt(maxFreq)
            if (maxVal > 0) {
                var util = Math.round((curVal / maxVal) * 100)
                utilization = util + "%"
            }
        } else {
            utilization = "—"
        }
    }

    function readGpuFreq() {
        readCurProc.running = true
        readMaxProc.running = true
        readMinProc.running = true
        readBoostProc.running = true
        readActProc.running = true
    }

    // Initial read
    Component.onCompleted: readGpuFreq()
}