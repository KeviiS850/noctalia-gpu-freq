import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root
    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool showMax: mainInstance?.showMax ?? false
    readonly property bool showMin: mainInstance?.showMin ?? false
    readonly property bool showBoost: mainInstance?.showBoost ?? false
    readonly property bool showUtil: mainInstance?.showUtil ?? true
    readonly property string curFreq: mainInstance?.curFreq ?? "?"
    readonly property string maxFreq: mainInstance?.maxFreq ?? "?"
    readonly property string minFreq: mainInstance?.minFreq ?? "?"
    readonly property string boostFreq: mainInstance?.boostFreq ?? "?"
    readonly property string actFreq: mainInstance?.actFreq ?? "?"
    readonly property real utilization: mainInstance?.utilization ?? 0.0
    readonly property real utilizationPercent: mainInstance?.utilizationPercent ?? 0.0
    readonly property string utilPercent: String(Math.round(utilizationPercent)) + "%"

    readonly property string displayText: {
        if (showUtil) {
            return "GPU " + utilPercent + " • " + actFreq + " MHz"
        } else if (showMax) {
            return curFreq + " / " + maxFreq + " MHz"
        } else if (showBoost) {
            return curFreq + " / " + boostFreq + " MHz"
        } else {
            return curFreq + " MHz"
        }
    }

    readonly property real contentWidth: labelText.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: Style.capsuleHeight
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: Style.capsuleColor
        radius: Style.radiusL
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        NText {
            id: labelText
            anchors.centerIn: parent
            text: root.displayText
            pointSize: Style.barFontSize
            applyUiScale: false
            color: Color.mOnSurface
        }
    }

    MouseArea {
            id: clickArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: TooltipService.show(root, "GPU: " + root.displayText + "\\nMin: " + minFreq + " MHz | Max: " + maxFreq + " MHz | Boost: " + boostFreq + " MHz", BarService.getTooltipDirection(screen?.name))
            onExited: TooltipService.hide()
        }

    NPopupContextMenu {
        id: contextMenu
        model: [
            {
                "label": pluginApi?.tr("menu.settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]
        onTriggered: function (action) {
            contextMenu.close()
            PanelService.closeContextMenu(screen)
            if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest)
            }
        }
    }
}