import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// PluginSettings.qml — settings dialog content for the gpu-freq plugin.
// Noctalia injects pluginApi + pluginSettingsChange with the standard contract:
//   pluginApi: { mainInstance, manifest, pluginSettings, ... }
//   pluginSettingsChange(newSettings): callback to persist changes
Item {
  id: root

  property var pluginApi: null
  property var pluginSettingsChange: null

  readonly property var cfg: pluginApi?.pluginSettings ?? ({})

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    NText {
      text: "GPU Frequency — Display Options"
      pointSize: 14
      font.bold: true
    }

    NText {
      text: "Toggle which values appear in the bar widget. Changes save automatically."
      color: Color.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    // ── Toggle row builder ──
    NCheckbox {
      id: utilCheck
      Layout.fillWidth: true
      label: "Show utilization %  (recommended — compact bar display)"
      checked: cfg.showUtil ?? true
      onCheckedChanged: persist()
    }
    NCheckbox {
      id: maxCheck
      Layout.fillWidth: true
      label: "Show max frequency (e.g.  “…/650 MHz”)"
      checked: cfg.showMax ?? true
      onCheckedChanged: persist()
    }
    NCheckbox {
      id: minCheck
      Layout.fillWidth: true
      label: "Show min frequency"
      checked: cfg.showMin ?? false
      onCheckedChanged: persist()
    }
    NCheckbox {
      id: boostCheck
      Layout.fillWidth: true
      label: "Show boost frequency"
      checked: cfg.showBoost ?? false
      onCheckedChanged: persist()
    }

    NDivider {}

    NText {
      text: "Hardware"
      pointSize: 12
      font.bold: true
    }

    NText {
      text: "GPU DRM card identifier (e.g. card0, card1)."
      color: Color.mOnSurfaceVariant
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    TextField {
      id: cardField
      Layout.fillWidth: true
      text: cfg.gpuCard ?? "card1"
      placeholderText: "card1"
      onEditingFinished: persist()
    }

    NCheckbox {
      id: autoCheck
      Layout.fillWidth: true
      label: "Auto-detect active GPU card"
      checked: cfg.autoDetectCard ?? true
      onCheckedChanged: persist()
    }
  }

  function persist() {
    if (!pluginSettingsChange)
      return;
    pluginSettingsChange({
      "showUtil":         utilCheck.checked,
      "showMax":          maxCheck.checked,
      "showMin":          minCheck.checked,
      "showBoost":        boostCheck.checked,
      "gpuCard":          cardField.text.trim() || "card1",
      "autoDetectCard":   autoCheck.checked
    });
  }
}
