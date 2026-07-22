import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// Panel.qml — detailed view of the gpu-freq plugin, opened from the
// Plugin Center when the user has assigned this plugin's panel entry point
// to a slot. Mirrors the bar tooltip but in a roomy layout.
Item {
  id: root
  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance ?? null

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 10

    NText {
      text: "GPU Frequency"
      pointSize: 16
      font.bold: true
    }

    NText {
      text: "Real-time readouts from " + (pluginApi?.pluginSettings?.gpuCard ?? "card1")
      color: Color.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    NDivider {}

    NText {
      text: "Current:  " + (mainInstance?.curFreq   ?? "?") + " MHz"
      Layout.fillWidth: true
    }
    NText {
      text: "Active:   " + (mainInstance?.actFreq   ?? "?") + " MHz"
      Layout.fillWidth: true
    }
    NText {
      text: "Range:    " + (mainInstance?.minFreq   ?? "?") + " – " + (mainInstance?.maxFreq ?? "?") + " MHz"
      Layout.fillWidth: true
    }
    NText {
      text: "Boost:    " + (mainInstance?.boostFreq ?? "?") + " MHz"
      Layout.fillWidth: true
    }

    NDivider {}

    NText {
      text: "Utilization"
      font.bold: true
    }
    ProgressBar {
      id: utilBar
      from: 0
      to: 100
      value: mainInstance ? Math.round(mainInstance.utilizationPercent) : 0
      Layout.fillWidth: true
    }
    NText {
      text: Math.round(mainInstance ? mainInstance.utilizationPercent : 0) + " %"
      color: Color.mOnSurfaceVariant
    }
  }
}
