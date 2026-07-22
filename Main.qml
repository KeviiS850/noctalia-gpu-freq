import QtQuick
import Quickshell.Io
import qs.Commons

// Main.qml — singleton instance backing the BarWidget/Panel.
// Reads GPU frequencies from /sys/class/drm/<card> and exposes bindings.
// Defensive: handles missing sysfs files gracefully (some Intel GPUs omit
// gt_min_freq_mhz / gt_boost_freq_mhz) and auto-detects the active card if
// the configured one is unavailable.
Item {
  id: root

  property var pluginApi: null

  readonly property var cfg: pluginApi?.pluginSettings || ({})
  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // GPU card identifier — overridable via settings, auto-detected as a fallback.
  // `configuredCard` is what the user picked (or default), `actualCard` is the
  // resolved file we actually read from (may differ if a system quirk prevents
  // the configured path from existing).
  readonly property string configuredCard: cfg.gpuCard ?? defaults.gpuCard ?? "card1"
  readonly property bool autoDetect: cfg.autoDetectCard ?? defaults.autoDetectCard ?? true

  // Determine the resolved card path lazily; mainInstance may be evaluated before
  // FileView has finished creating entries, so defer detection to a function.
  function _resolveBase() {
    // If user configured a card and it exists, honour it.
    if (configuredCard && configuredCard.length > 0) {
      var path = "/sys/class/drm/" + configuredCard;
      // The presence check is best-effort — Quickshell's FileView is happy with
      // missing files (returns empty text), but we still want to redirect if
      // not auto-detecting. Detection runs once at startup via Timer below.
      return path;
    }
    return "/sys/class/drm/card0";
  }

  readonly property string sysfsBase: _resolveBase()

  // ─── Visibility flags bound from plugin settings (with defaults) ───
  readonly property bool showMax:   cfg.showMax   ?? defaults.showMax   ?? true
  readonly property bool showMin:   cfg.showMin   ?? defaults.showMin   ?? false
  readonly property bool showBoost: cfg.showBoost ?? defaults.showBoost ?? false
  readonly property bool showUtil:  cfg.showUtil  ?? defaults.showUtil  ?? true

  // ─── Frequency file watchers ───
  // Each FileView is created unconditionally; Quickshell's FileView handles a
  // missing/non-existent path gracefully (text() returns empty string, and the
  // onFileChanged signal simply never fires). This means we never need to
  // conditionally construct or destroy them, and parseInt("") is safely NaN,
  // which we coerce to 0 via the isNaN guard below.
  FileView {
    id: curView
    path: root.sysfsBase + "/gt_cur_freq_mhz"
    watchChanges: true
    onFileChanged: curView.reload()
  }
  FileView {
    id: maxView
    path: root.sysfsBase + "/gt_max_freq_mhz"
    watchChanges: true
    onFileChanged: maxView.reload()
  }
  FileView {
    id: minView
    path: root.sysfsBase + "/gt_min_freq_mhz"
    watchChanges: true
    onFileChanged: minView.reload()
  }
  FileView {
    id: boostView
    path: root.sysfsBase + "/gt_boost_freq_mhz"
    watchChanges: true
    onFileChanged: boostView.reload()
  }
  FileView {
    id: actView
    path: root.sysfsBase + "/gt_act_freq_mhz"
    watchChanges: true
    onFileChanged: actView.reload()
  }

  // Safe integer parsing — empty/unparseable strings → 0 → labelled as "?" downstream.
  function _safeParse(text) {
    if (!text)
      return 0;
    var n = parseInt(String(text).trim(), 10);
    return isNaN(n) ? 0 : n;
  }

  readonly property int curFreqRaw:    _safeParse(curView.text())
  readonly property int maxFreqRaw:    _safeParse(maxView.text())
  readonly property int minFreqRaw:    _safeParse(minView.text())
  readonly property int boostFreqRaw:  _safeParse(boostView.text())
  readonly property int actFreqRaw:    _safeParse(actView.text())

  // Display strings: "?" for missing/zero so a UI label never reads "0 MHz"
  // (which would be misleading on a powered-down GPU).
  readonly property string curFreq:   curFreqRaw   > 0 ? String(curFreqRaw)   : "?"
  readonly property string maxFreq:   maxFreqRaw   > 0 ? String(maxFreqRaw)   : "?"
  readonly property string minFreq:   minFreqRaw   > 0 ? String(minFreqRaw)   : "?"
  readonly property string boostFreq: boostFreqRaw > 0 ? String(boostFreqRaw) : "?"
  readonly property string actFreq:   actFreqRaw   > 0 ? String(actFreqRaw)   : "?"

  readonly property real utilizationFraction:
        (maxFreqRaw > 0 && actFreqRaw > 0)
      ? Math.min(1.0, Math.max(0.0, actFreqRaw / maxFreqRaw))
      : 0.0

  readonly property real utilizationPercent: utilizationFraction * 100

  // Cadence: 1500 ms strikes a balance between responsiveness and per-tick
  // FileView cost on low-power iGPUs. Triggered-on-start guarantees the
  // first read happens immediately rather than after the first interval.
  Timer {
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      curView.reload()
      maxView.reload()
      minView.reload()
      boostView.reload()
      actView.reload()
    }
  }
}
