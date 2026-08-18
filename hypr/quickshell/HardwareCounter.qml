import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

BarPill {
    id: root

    required property url iconSource
    required property int value
    property int warningAt: 70
    property int criticalAt: 90
    readonly property color valueColor: value >= criticalAt ? Theme.critical
        : value >= warningAt ? Theme.warning
        : Theme.text

    text: ""
    interactive: false
    implicitWidth: Theme.barCounterWidth
    width: implicitWidth

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 4

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            source: root.iconSource
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.barValueWidth
            text: root.value + "%"
            color: root.valueColor
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.bold: true
            horizontalAlignment: Text.AlignLeft
        }
    }
}
