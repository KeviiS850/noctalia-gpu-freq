import QtQuick
import Quickshell.Io
import qs.Commons

// Main.qml — the singleton instance for the plugin. Noctalia only instantiates
// this if manifest.entryPoints.main is set. BarWidget and Panel then read the
// exposed bindings (curFreq, maxFreq, etc.) via pluginApi.mainInstance.
Item {
    id: root
    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property bool showMax:  cfg.showMax   ?? defaults.showMax   ?? false
    readonly property bool showMin:  cfg.showMin   ?? defaults.showMin   ?? false
    readonly property bool showBoost:cfg.showBoost ?? defaults.showBoost ?? false

    // ─── Frequency observers ───
    FileView {
        id: curView
        path: "/sys/class/drm/card1/gt_cur_freq_mhz"
        watchChanges: true
        onFileChanged: curView.reload()
    }
    FileView {
        id: minView
        path: "/sys/class/drm/card1/gt_min_freq_mhz"
        watchChanges: true
        onFileChanged: minView.reload()
    }
    FileView {
        id: maxView
        path: "/sys/class/drm/card1/gt_max_freq_mhz"
        watchChanges: true
        onFileChanged: maxView.reload()
    }
    FileView {
        id: boostView
        path: "/sys/class/drm/card1/gt_boost_freq_mhz"
        watchChanges: true
        onFileChanged: boostView.reload()
    }
    FileView {
        id: actView
        path: "/sys/class/drm/card1/gt_act_freq_mhz"
        watchChanges: true
        onFileChanged: actView.reload()
    }
    FileView {
        id: rp0View
        path: "/sys/class/drm/card1/gt_RP0_freq_mhz"
        watchChanges: true
        onFileChanged: rp0View.reload()
    }
    FileView {
        id: rp1View
        path: "/sys/class/drm/card1/gt_RP1_freq_mhz"
        watchChanges: true
        onFileChanged: rp1View.reload()
    }
    FileView {
        id: rpnView
        path: "/sys/class/drm/card1/gt_RPn_freq_mhz"
        watchChanges: true
        onFileChanged: rpnView.reload()
    }

    // ─── helpers ───
    function _mhz(view) {
        var t = (view.text() || "").trim()
        if (t === "") {
            return NaN
        }
        var n = parseInt(t, 10)
        if (isNaN(n)) {
            return NaN
        }
        return n
    }
    function _intOrNaN(view) { return _mhz(view) }

    // ─── bindings ───
    readonly property real curFreqRaw:   _mhz(curView)
    readonly property real maxFreqRaw:   _mhz(maxView)
    readonly property real minFreqRaw:   _mhz(minView)
    readonly property real boostFreqRaw: _mhz(boostView)
    readonly property real actFreqRaw:   _mhz(actView)
    readonly property real rp0FreqRaw:   _mhz(rp0View)
    readonly property real rp1FreqRaw:   _mhz(rp1View)
    readonly property real rpnFreqRaw:   _mhz(rpnView)

    // Convenience formatted strings used by BarWidget to keep its existing API.
    readonly property string curFreq:   isNaN(curFreqRaw)   ? "?" : String(curFreqRaw)
    readonly property string maxFreq:   isNaN(maxFreqRaw)   ? "?" : String(maxFreqRaw)
    readonly property string minFreq:   isNaN(minFreqRaw)   ? "?" : String(minFreqRaw)
    readonly property string boostFreq: isNaN(boostFreqRaw) ? "?" : String(boostFreqRaw)
    readonly property string actFreq:   isNaN(actFreqRaw)   ? "?" : String(actFreqRaw)
    readonly property string rp0Freq:   isNaN(rp0FreqRaw)   ? "?" : String(rp0FreqRaw)
    readonly property string rp1Freq:   isNaN(rp1FreqRaw)   ? "?" : String(rp1FreqRaw)
    readonly property string rpnFreq:   isNaN(rpnFreqRaw)   ? "?" : String(rpnFreqRaw)

    // Utilization fraction (0.0–1.0) of active vs max — useful for the bar gauge.
    readonly property real utilFraction:
        (isNaN(actFreqRaw) || isNaN(maxFreqRaw) || maxFreqRaw <= 0) ? 0.0
        : Math.min(1.0, Math.max(0.0, actFreqRaw / maxFreqRaw))
    // Utilization fraction (0.0–1.0)
    readonly property real utilization: utilFraction
    // Utilization percentage (0-100)
    readonly property real utilizationPercent: utilFraction * 100

    // Default settings (mirrors manifest defaults)
    readonly property bool showUtil: pluginApi?.pluginSettings?.showUtil ?? pluginApi?.manifest?.metadata?.defaultSettings?.showUtil ?? true
    readonly property bool showMax: pluginApi?.pluginSettings?.showMax ?? pluginApi?.manifest?.metadata?.defaultSettings?.showMax ?? false
    readonly property bool showMin: pluginApi?.pluginSettings?.showMin ?? pluginApi?.manifest?.metadata?.defaultSettings?.showMin ?? false
    readonly property bool showBoost: pluginApi?.pluginSettings?.showBoost ?? pluginApi?.manifest?.metadata?.defaultSettings?.showBoost ?? false

    // Colors for graphs (defaults match Panel fallback)
    readonly property color colorGood: "#22c55e"
    readonly property color colorWarning: "#f59e0b"
    readonly property color colorCritical: "#ef4444"

    // Timer to ensure updates even if inotify misses
    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            curView.reload()
            minView.reload()
            maxView.reload()
            boostView.reload()
            actView.reload()
            rp0View.reload()
            rp1View.reload()
            rpnView.reload()
        }
    }
}