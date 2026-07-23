import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
 id: root
 property var pluginApi: null
 property string widgetId: ""
 property string section: ""
 property int sectionWidgetIndex: -1
 property int sectionWidgetsCount: 0

 // Screen-specific styling helpers
 readonly property string screenName: pluginApi?.screen?.name ?? ""
 readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
 readonly property bool isVertical: barPosition === "left" || barPosition === "right"
 readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
 readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

 // Settings from plugin
 property bool compactMode: pluginApi?.mainInstance?.pluginApi?.pluginSettings?.compactMode ?? true
 property bool showMax: pluginApi?.mainInstance?.pluginApi?.pluginSettings?.showMax ?? true
 property bool showMin: pluginApi?.mainInstance?.pluginApi?.pluginSettings?.showMin ?? false
 property bool showBoost: pluginApi?.mainInstance?.pluginApi?.pluginSettings?.showBoost ?? false
 property bool showUtil: pluginApi?.mainInstance?.pluginApi?.pluginSettings?.showUtil ?? true
 property string gpuCard: pluginApi?.mainInstance?.gpuCard ?? "card1"

 // Direct bindings to the singleton Main instance
 readonly property string curFreq: pluginApi?.mainInstance?.curFreq ?? "—"
 readonly property string maxFreq: pluginApi?.mainInstance?.maxFreq ?? "—"
 readonly property string minFreq: pluginApi?.mainInstance?.minFreq ?? "—"
 readonly property string boostFreq: pluginApi?.mainInstance?.boostFreq ?? "—"
 readonly property string actFreq: pluginApi?.mainInstance?.actFreq ?? "—"
 readonly property string utilization: pluginApi?.mainInstance?.utilization ?? "—"
 readonly property bool hasValidData: pluginApi?.mainInstance?.hasValidData ?? false

 // Derived UI metrics
 readonly property real iconSize: Style.toOdd(capsuleHeight * 0.55)

 // Compute text widths
 readonly property string freqText: curFreq !== "—" ? curFreq.replace(" MHz", "") + " MHz" : "—"
 readonly property string maxText: (showMax && maxFreq !== "—" && !compactMode) ? (" / " + maxFreq) : ""
 readonly property string utilText: (showUtil && utilization !== "—") ? (" " + utilization) : ""

 // Width estimation
 readonly property real textWidth: {
  var base = freqText.length * (compactMode ? 5.5 : 6) + maxText.length * (compactMode ? 5 : 6) + utilText.length * (compactMode ? 5 : 6)
  return base
 }

 readonly property real contentWidth: {
  if (isVertical) return capsuleHeight
  return iconSize + Style.marginS + textWidth + Style.marginS
 }
 readonly property real contentHeight: isVertical ? capsuleHeight * 2 : capsuleHeight

 implicitWidth: compactMode ? 90 : 110
 implicitHeight: Math.max(contentHeight, 22)

 // Text-only widget — no background
Row {
id: row
anchors.centerIn: parent
spacing: compactMode ? 2 : 3

// Tech label — always visible so user knows it's Intel UHD GPU
Text {
        id: labelText
        text: "Intel UHD GPU"
        font.family: Settings.data.ui.fontDefault
        font.pixelSize: compactMode ? 11 : 12
        color: "#6c7086"
        verticalAlignment: Text.AlignVCenter
    }

// Separator
Text {
text: "|"
font.pixelSize: compactMode ? 8 : 9
font.bold: true
color: "#6c7086"
verticalAlignment: Text.AlignVCenter
}

// Current frequency
Text {
    id: curText
    text: freqText
    font.family: Settings.data.ui.fontDefault
    font.pixelSize: compactMode ? 12 : 13
    font.bold: true
    color: Color.mOnSurface
    verticalAlignment: Text.AlignVCenter
}

// Max frequency (non-compact only)
Text {
id: maxTextItem
text: maxText
font.family: Settings.data.ui.fontDefault
font.pixelSize: compactMode ? 9 : 10
color: Color.mOnSurface
verticalAlignment: Text.AlignVCenter
opacity: 0.7
}

// Utilization — green tech accent
Text {
id: utilTextItem
text: utilText
font.family: Settings.data.ui.fontDefault
font.pixelSize: compactMode ? 9 : 10
color: "#00ff7f"
font.bold: true
verticalAlignment: Text.AlignVCenter
}
}

// Tooltip with full details
MouseArea {
id: tooltipArea
anchors.fill: parent
hoverEnabled: true
onEntered: TooltipService.show(root, tooltipText, BarService.getTooltipDirection(screenName))
onExited: TooltipService.hide()
}

 readonly property string tooltipText: {
  if (!hasValidData) return "Intel UHD GPU: No data"
  return "Intel UHD GPU (" + gpuCard + ")\n" +
   "Current: " + curFreq + "\n" +
   "Maximum: " + maxFreq + "\n" +
   "Minimum: " + minFreq + "\n" +
   "Boost: " + boostFreq + "\n" +
   "Active: " + actFreq + "\n" +
   "Utilization: " + utilization + "\n" +
   "Data valid: " + (hasValidData ? "Yes" : "No") + "\n" +
   "Updated: " + new Date().toLocaleTimeString()
 }

 Component.onCompleted: {
  console.debug("GPU Freq widget initialized:", "screenName:", screenName, "isVertical:", isVertical,
   "capsuleHeight:", capsuleHeight, "barFontSize:", barFontSize,
   "curFreq:", curFreq, "maxFreq:", maxFreq, "utilization:", utilization,
   "hasValidData:", hasValidData, "gpuCard:", gpuCard,
   "hasPluginApi:", !!pluginApi, "hasMainInstance:", !!(pluginApi?.mainInstance))
 }
}
