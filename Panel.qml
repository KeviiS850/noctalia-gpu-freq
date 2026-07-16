import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    readonly property real maxHeight: 540 * Style.uiScaleRatio
    property real contentPreferredHeight: Math.min(contentColumn.implicitHeight + Style.marginL * 2, maxHeight)
    property bool panelReady: false

    Behavior on contentPreferredHeight {
        enabled: panelReady
        NumberAnimation { duration: 180; easing.type: Easing.InOutCubic }
    }

    readonly property var mainInstance: pluginApi?.mainInstance

    // Data bindings
    readonly property string curFreq: mainInstance?.curFreq ?? "?"
    readonly property string maxFreq: mainInstance?.maxFreq ?? "?"
    readonly property string minFreq: mainInstance?.minFreq ?? "?"
    readonly property string boostFreq: mainInstance?.boostFreq ?? "?"
    readonly property string actFreq: mainInstance?.actFreq ?? "?"
    readonly property real utilization: mainInstance?.utilization ?? 0.0
    readonly property real utilizationPercent: mainInstance?.utilizationPercent ?? 0.0
    readonly property string utilPercent: String(Math.round(utilizationPercent)) + "%"

    // Colors
    readonly property color colorGood: mainInstance?.colorGood ?? "#22c55e"
    readonly property color colorWarning: mainInstance?.colorWarning ?? "#f59e0b"
    readonly property color colorCritical: mainInstance?.colorCritical ?? "#ef4444"

    // History (60 samples = 60 seconds at 1s interval)
    property var freqHistory: []
    property var utilHistory: []

    Timer {
        id: historyTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            freqHistory.push(parseFloat(curFreq) || 0)
            utilHistory.push(utilizationPercent)
            if (freqHistory.length > 60) freqHistory.shift()
            if (utilHistory.length > 60) utilHistory.shift()
        }
    }

    function statusColor(u) {
        // u is now 0-100 (utilizationPercent)
        if (u > 80) return root.colorCritical
        else if (u > 50) return root.colorWarning
        else return root.colorGood
    }

    function _threshY(thresh, maxVal, h) {
        if (maxVal <= 0 || h <= 0) return -1
        const pad = maxVal * 0.12
        const norm = (thresh + pad) / (maxVal + pad * 2)
        return h * (1.0 - norm)
    }

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: contentColumn
            anchors { fill: parent; margins: Style.marginL }
            spacing: Style.marginM

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NIcon { icon: "activity"; pointSize: Style.fontSizeXL; color: Color.mPrimary; Layout.alignment: Qt.AlignVCenter }
                NText { text: "GPU Monitor"; pointSize: Style.fontSizeL; font.weight: Font.Bold; color: Color.mOnSurface; Layout.alignment: Qt.AlignVCenter }
                Item { Layout.fillWidth: true }

                NIconButton {
                    icon: "x"; tooltipText: pluginApi?.tr("panel.close")
                    onClicked: { const s = root.pluginApi?.panelOpenScreen; if (s) root.pluginApi.closePanel(s) }
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // ── Current values card ──
            NBox {
                Layout.fillWidth: true
                ColumnLayout { anchors.fill: parent; anchors.margins: Style.marginM; spacing: Style.marginXS

                    RowLayout { Layout.fillWidth: true; spacing: Style.marginM
                        NIcon { icon: "cpu"; pointSize: Style.fontSizeM; color: Color.mPrimary; Layout.alignment: Qt.AlignVCenter }
                        NText { text: "ACTIVE"; pointSize: Style.fontSizeXS; color: root.colorGood; font.weight: Font.Medium }
                        Item { Layout.fillWidth: true }
                        NText { text: actFreq + " MHz"; pointSize: Style.fontSizeM; font.family: Settings.data.ui.fontFixed; color: Color.mOnSurface; font.weight: Font.Bold }
                    }
                    RowLayout { Layout.fillWidth: true; spacing: Style.marginM
                        NIcon { icon: "cpu"; pointSize: Style.fontSizeM; color: Color.mSecondary; Layout.alignment: Qt.AlignVCenter }
                        NText { text: "CUR/MAX"; pointSize: Style.fontSizeXS; color: Color.mPrimary; font.weight: Font.Medium }
                        Item { Layout.fillWidth: true }
                        NText { text: curFreq + " / " + maxFreq + " MHz"; pointSize: Style.fontSizeS; font.family: Settings.data.ui.fontFixed; color: Color.mOnSurfaceVariant }
                    }
                    RowLayout { Layout.fillWidth: true; spacing: Style.marginM
                        NIcon { icon: "cpu"; pointSize: Style.fontSizeM; color: Color.mSecondary; Layout.alignment: Qt.AlignVCenter }
                        NText { text: "BOOST"; pointSize: Style.fontSizeXS; color: root.colorWarning; font.weight: Font.Medium }
                        Item { Layout.fillWidth: true }
                        NText { text: boostFreq + " MHz"; pointSize: Style.fontSizeS; font.family: Settings.data.ui.fontFixed; color: Color.mOnSurfaceVariant }
                    }
                    RowLayout { Layout.fillWidth: true; spacing: Style.marginM
                        NIcon { icon: "cpu"; pointSize: Style.fontSizeM; color: Color.mSecondary; Layout.alignment: Qt.AlignVCenter }
                        NText { text: "UTIL"; pointSize: Style.fontSizeXS; color: root.statusColor(root.utilization); font.weight: Font.Medium }
                        Item { Layout.fillWidth: true }
                        NText { text: utilPercent; pointSize: Style.fontSizeM; font.family: Settings.data.ui.fontFixed; color: root.statusColor(root.utilization); font.weight: Font.Bold }
                    }
                }
            }

            NDivider { Layout.fillWidth: true; opacity: 0.4 }

            // ── Utilization graph ──
            NBox {
                Layout.fillWidth: true
                implicitHeight: utilGraph.implicitHeight + utilTimeAxis.implicitHeight + Style.marginXS

                Item {
                    id: utilGraphArea
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 120 * Style.uiScaleRatio

                    NGraph {
                        id: utilGraph
                        anchors.fill: parent
                        values: root.utilHistory
                        minValue: 0
                        maxValue: 100
                        animateScale: true
                        fill: true
                        fillOpacity: 0.15
                        strokeWidth: Math.max(1, Style.uiScaleRatio)
                        color: root.statusColor(root.utilizationPercent)
                        updateInterval: 1000
                    }

                    // Threshold lines (50%, 80%)
                    Repeater {
                        model: [{ thresh: 50, color: root.colorWarning }, { thresh: 80, color: root.colorCritical }]
                        delegate: Item {
                            required property var modelData
                            readonly property real _y: root._threshY(modelData.thresh, utilGraph.maxValue, utilGraph.height)
                            readonly property color _col: modelData.color
                            visible: _y >= 0 && _y <= utilGraph.height
                            y: _y

                            Row {
                                anchors { left: parent.left; right: utilLabelBox.left; rightMargin: Style.marginXS }
                                spacing: Style.marginXS
                                Repeater {
                                    model: Math.ceil(parent.width / 7)
                                    delegate: Rectangle { width: Style.marginS; height: 1; color: Qt.alpha(parent.parent.parent._col, 0.40) }
                                }
                            }

                            Rectangle {
                                id: utilLabelBox
                                anchors.right: parent.right
                                y: -height / 2
                                implicitWidth: utilThreshLabel.implicitWidth + Style.marginXS * 2
                                implicitHeight: utilThreshLabel.implicitHeight + 2
                                radius: Style.radiusXS
                                color: Qt.alpha(parent._col, 0.12)
                                NText { id: utilThreshLabel; anchors.centerIn: parent; text: modelData.thresh + "%"; pointSize: Style.fontSizeXS * 0.85; color: parent.parent._col }
                            }
                        }
                    }

                    // Hover tooltip
                    MouseArea {
                        id: hoverUtil
                        anchors.fill: parent
                        hoverEnabled: true

                        readonly property int _idx: {
                            const n = root.utilHistory.length
                            if (n < 2 || !containsMouse) return -1
                            return Math.max(0, Math.min(n - 1, Math.round(mouseX / width * (n - 1))))
                        }
                        readonly property real _val: _idx >= 0 ? (root.utilHistory[_idx] ?? -1) : -1

                        Rectangle {
                            visible: hoverUtil._idx >= 0
                            x: hoverUtil._idx >= 0 ? (hoverUtil._idx / Math.max(root.utilHistory.length - 1, 1)) * parent.width - width / 2 : 0
                            width: 1
                            height: parent.height
                            color: Qt.alpha(Color.mOnSurface, 0.25)

                            Rectangle {
                                readonly property string _label: hoverUtil._val < 0 ? "" : String(hoverUtil._val.toFixed(1)) + "%"
                                readonly property real _rawX: -(implicitWidth / 2)
                                x: Math.max(-parent.x, Math.min(parent.width - parent.x - implicitWidth, _rawX))
                                y: Style.marginXS
                                implicitWidth: utilBubbleText.implicitWidth + Style.marginS * 2
                                implicitHeight: utilBubbleText.implicitHeight + Style.marginXS * 2
                                radius: Style.radiusS
                                color: Color.mSurfaceVariant
                                border.color: Qt.alpha(Color.mOnSurface, 0.15)
                                border.width: Style.marginM
                                NText { id: utilBubbleText; anchors.centerIn: parent; text: parent._label; pointSize: Style.fontSizeXS; color: Color.mOnSurface }
                            }
                        }
                    }
                }

                // Time axis
                Row {
                    id: utilTimeAxis
                    anchors { left: parent.left; right: parent.right; top: utilGraphArea.bottom; topMargin: Style.marginXS }
                    visible: root.utilHistory.length >= 2

                    Repeater {
                        model: 3
                        delegate: Item {
                            required property int index
                            width: utilTimeAxis.width / 3
                            height: utilTimeLabel.implicitHeight

                            readonly property int _sIdx: {
                                const n = root.utilHistory.length
                                if (n < 2) return -1
                                return index === 0 ? 0 : index === 1 ? Math.floor(n / 2) : n - 1
                            }

                            NText {
                                id: utilTimeLabel
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: parent._sIdx >= 0
                                text: {
                                    const s = parent._sIdx
                                    const secsAgo = Math.round((root.utilHistory.length - 1 - s) * 1)
                                    if (secsAgo < 60) return secsAgo + "s ago"
                                    const m = Math.floor(secsAgo / 60)
                                    const secs = secsAgo % 60
                                    return m + "m " + secs + "s ago"
                                }
                                pointSize: Style.fontSizeXS * 0.85
                                color: Qt.alpha(Color.mSecondary, 0.6)
                            }
                        }
                    }
                }
            }

            NDivider { Layout.fillWidth: true; opacity: 0.4 }

            // ── Frequency history graph ──
            NBox {
                Layout.fillWidth: true
                implicitHeight: freqGraph.implicitHeight + freqTimeAxis.implicitHeight + Style.marginXS

                Item {
                    id: freqGraphArea
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: 120 * Style.uiScaleRatio

                    NGraph {
                        id: freqGraph
                        anchors.fill: parent
                        values: root.freqHistory
                        minValue: 0
                        maxValue: (root.freqHistory.length > 0 ? Math.max(...root.freqHistory, parseFloat(root.maxFreq) || 1000) * 1.15 : 1000)
                        animateScale: true
                        fill: true
                        fillOpacity: 0.12
                        strokeWidth: Math.max(1, Style.uiScaleRatio)
                        color: Color.mPrimary
                        updateInterval: 1000
                    }

                    // Hover tooltip
                    MouseArea {
                        id: hoverFreq
                        anchors.fill: parent
                        hoverEnabled: true

                        readonly property int _idx: {
                            const n = root.freqHistory.length
                            if (n < 2 || !containsMouse) return -1
                            return Math.max(0, Math.min(n - 1, Math.round(mouseX / width * (n - 1))))
                        }
                        readonly property real _val: _idx >= 0 ? (root.freqHistory[_idx] ?? -1) : -1

                        Rectangle {
                            visible: hoverFreq._idx >= 0
                            x: hoverFreq._idx >= 0 ? (hoverFreq._idx / Math.max(root.freqHistory.length - 1, 1)) * parent.width - width / 2 : 0
                            width: 1
                            height: parent.height
                            color: Qt.alpha(Color.mOnSurface, 0.25)

                            Rectangle {
                                readonly property string _label: hoverFreq._val < 0 ? "" : String(hoverFreq._val.toFixed(0)) + " MHz"
                                readonly property real _rawX: -(implicitWidth / 2)
                                x: Math.max(-parent.x, Math.min(parent.width - parent.x - implicitWidth, _rawX))
                                y: Style.marginXS
                                implicitWidth: freqBubbleText.implicitWidth + Style.marginS * 2
                                implicitHeight: freqBubbleText.implicitHeight + Style.marginXS * 2
                                radius: Style.radiusS
                                color: Color.mSurfaceVariant
                                border.color: Qt.alpha(Color.mOnSurface, 0.15)
                                border.width: Style.marginM
                                NText { id: freqBubbleText; anchors.centerIn: parent; text: parent._label; pointSize: Style.fontSizeXS; color: Color.mOnSurface }
                            }
                        }
                    }
                }

                // Time axis
                Row {
                    id: freqTimeAxis
                    anchors { left: parent.left; right: parent.right; top: freqGraphArea.bottom; topMargin: Style.marginXS }
                    visible: root.freqHistory.length >= 2

                    Repeater {
                        model: 3
                        delegate: Item {
                            required property int index
                            width: freqTimeAxis.width / 3
                            height: freqTimeLabel.implicitHeight

                            readonly property int _sIdx: {
                                const n = root.freqHistory.length
                                if (n < 2) return -1
                                return index === 0 ? 0 : index === 1 ? Math.floor(n / 2) : n - 1
                            }

                            NText {
                                id: freqTimeLabel
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: parent._sIdx >= 0
                                text: {
                                    const s = parent._sIdx
                                    const secsAgo = Math.round((root.freqHistory.length - 1 - s) * 1)
                                    if (secsAgo < 60) return secsAgo + "s ago"
                                    const m = Math.floor(secsAgo / 60)
                                    const secs = secsAgo % 60
                                    return m + "m " + secs + "s ago"
                                }
                                pointSize: Style.fontSizeXS * 0.85
                                color: Qt.alpha(Color.mSecondary, 0.6)
                            }
                        }
                    }
                }
            }

            // ── Min/Max/Boost row ──
            NBox {
                Layout.fillWidth: true
                ColumnLayout { anchors.fill: parent; anchors.margins: Style.marginM; spacing: Style.marginXS

                    RowLayout { Layout.fillWidth: true; spacing: 0
                        Repeater {
                            model: [
                                { label: "MIN", value: minFreq + " MHz", color: "#6b7280" },
                                { label: "MAX", value: maxFreq + " MHz", color: Color.mPrimary },
                                { label: "BOOST", value: boostFreq + " MHz", color: root.colorWarning }
                            ]
                            delegate: Item { Layout.fillWidth: true
                                Column { anchors.horizontalCenter: parent.horizontalCenter; spacing: 2
                                    NText { text: modelData.label; pointSize: Style.fontSizeXS; font.weight: Font.Bold; color: modelData.color }
                                    NText { text: modelData.value; pointSize: Style.fontSizeS; font.family: Settings.data.ui.fontFixed; color: Color.mOnSurface }
                                }
                            }
                        }
                    }
                }
            }

            // ── Status badge ──
            NBox {
                Layout.fillWidth: true
                ColumnLayout { anchors.fill: parent; anchors.margins: Style.marginM

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 16
                        color: root.statusColor(root.utilizationPercent)
                        opacity: 0.15
                        border.color: root.statusColor(root.utilizationPercent)
                        border.width: 1

                        NText {
                            anchors.centerIn: parent
                            text: root.utilizationPercent > 80 ? "HIGH LOAD" : root.utilizationPercent > 50 ? "MODERATE LOAD" : root.utilizationPercent > 10 ? "LIGHT LOAD" : "IDLE"
                            pointSize: Style.fontSizeXS
                            font.weight: Font.Bold
                            color: root.statusColor(root.utilizationPercent)
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: panelReady = true
}