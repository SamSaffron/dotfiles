import QtQuick
import "Theme.js" as Theme

Column {
    id: root

    required property string icon
    required property string label
    required property string value

    width: 94
    spacing: 3

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.icon
        color: Theme.accent
        font.family: Theme.fontFamily
        font.pixelSize: 17
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.value
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.bold: true
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 9
    }
}
