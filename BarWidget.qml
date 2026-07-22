import QtQuick 2.15
import Style 1.0
import Color 1.0
import NIcon 1.0
import NText 1.0
import TooltipService 1.0
import BarService 1.0

Item {
    readonly property string displayText: {
        if (showUtil) {
            return "GPU " + String(Math.round(utilizationPercent)) + "% • " + actFreq + " MHz"
        } else if (showMax) {
            return curFreq + " / " + maxFreq + " MHz"
        } else if (showBoost) {
            return curFreq + " / " + boostFreq + " MHz"
        } else {
            return curFreq + " MHz"
        }
    }

    // Robust sizing: use bar metrics with safe fallbacks to avoid zero size
    readonly property real barHeight: (Style.barHeight && Style.barHeight > 0) ? Style.barHeight : 24
    readonly property real barFontSize: (Style.barFontSize && Style.barFontSize > 0) ? Style.barFontSize : 10
    readonly property real capsuleHeight: barHeight
    readonly property real iconSize: Style.toOdd(capsuleHeight * 0.55)

    readonly property real contentWidth: iconSize + Style.marginS + labelText.implicitWidth + Style.marginM
    readonly property real contentHeight: capsuleHeight

    implicitWidth: Math.max(contentWidth, 60) // Ensure minimum width
    implicitHeight: contentHeight

    Rectangle {
        id: capsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusM
        color: Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                id: iconElement
                icon: "gpu"
                pointSize: root.iconSize
                color: Color.mOnSurfaceVariant
            }

            NText {
                id: labelText
                text: root.displayText
                pointSize: root.barFontSize
                applyUiScale: false
                color: Color.mOnSurface
                elide: Text.ElideRight
            }
        }
    }

    // Hover-only for tooltip, no clicks
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        acceptedButtons: Qt.NoButton

        onEntered: TooltipService.show(root, tooltipText, BarService.getTooltipDirection(screen?.name))
        onExited: TooltipService.hide()
    }

    // Tooltip
    readonly property string tooltipText: {
        const parts = [
            "GPU: " + displayText,
            "Cur: " + curFreq + " MHz",
            "Act: " + actFreq + " MHz",
            "Max: " + maxFreq + " MHz",
            "Min: " + minFreq + " MHz",
            "Boost: " + boostFreq + " MHz",
            "Util: " + String(Math.round(utilizationPercent)) + "%"
        ]
        return parts.join("\n")
    }
}
