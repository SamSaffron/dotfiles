import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var anchorWindow
    required property var anchorItem
    required property var targetScreen

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var streams: Pipewire.nodes.values.filter(node => node.isStream && node.isSink && node.audio)
    readonly property var outputs: Pipewire.nodes.values.filter(node => !node.isStream && node.isSink && node.audio)
    property bool outputsExpanded: false
    readonly property int outputListHeight: Math.min(180, outputs.length * 38 + 10)

    function selectOutput(node) {
        if (!node)
            return
        Pipewire.preferredDefaultAudioSink = node
        Quickshell.execDetached(["wpctl", "set-default", node.id.toString()])
        outputsExpanded = false
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorItem.mapToItem(anchorWindow.contentItem, 0, 0).x + anchorItem.width - width
    anchor.rect.y: -height - Theme.gap
    implicitWidth: 400
    implicitHeight: 500 + (outputsExpanded ? outputListHeight + 10 : 0)
    visible: shell.audioOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.audioOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.audioOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    PwObjectTracker {
        objects: [popup.sink, popup.source].concat(popup.streams).concat(popup.outputs)
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Row {
                width: parent.width
                height: 34

                Column {
                    width: parent.width - outputButton.width
                    Text {
                        text: "Audio"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: Pipewire.ready ? "PipeWire connected" : "Connecting to PipeWire…"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    id: outputButton
                    width: 110
                    height: 30
                    radius: 8
                    color: outputMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    opacity: popup.outputs.length > 0 ? 1 : 0.55
                    Text {
                        anchors.centerIn: parent
                        text: popup.outputsExpanded ? "󰅀  Hide outputs" : "󰓃  Outputs (" + popup.outputs.length + ")"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                    }
                    MouseArea {
                        id: outputMouse
                        anchors.fill: parent
                        enabled: popup.outputs.length > 0
                        hoverEnabled: true
                        onClicked: popup.outputsExpanded = !popup.outputsExpanded
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: popup.outputsExpanded ? popup.outputListHeight : 0
                visible: popup.outputsExpanded
                radius: Theme.radius
                color: Theme.backgroundRaised
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 3
                    clip: true
                    model: ScriptModel { values: popup.outputs }

                    delegate: Rectangle {
                        id: outputRow
                        required property var modelData

                        readonly property bool selected: modelData === popup.sink
                        width: ListView.view.width
                        height: 35
                        radius: 7
                        color: selected ? Theme.accentSoft
                             : outputRowMouse.containsMouse ? Theme.backgroundHover
                             : Theme.background

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: outputRow.selected ? "󰄬" : "󰓃"
                                color: outputRow.selected ? Theme.accent : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 28
                                text: outputRow.modelData.description || outputRow.modelData.nickname || outputRow.modelData.name
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: outputRow.selected
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: outputRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: popup.selectOutput(outputRow.modelData)
                        }
                    }

                    ScrollBar.vertical: ScrollBar {}
                }
            }

            AudioControl {
                node: popup.sink
                icon: "󰕾"
                title: "Output"
            }

            AudioControl {
                node: popup.source
                icon: "󰍬"
                title: "Microphone"
            }

            Row {
                width: parent.width
                height: 18
                Text {
                    width: parent.width - streamCount.width
                    text: "APPLICATIONS"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                }
                Text {
                    id: streamCount
                    text: popup.streams.length + " active"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                }
            }

            Rectangle {
                width: parent.width
                height: 150
                radius: Theme.radius
                color: Theme.backgroundRaised

                Text {
                    anchors.centerIn: parent
                    visible: popup.streams.length === 0
                    text: "No applications are playing audio"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }

                ListView {
                    anchors.fill: parent
                    anchors.margins: 5
                    visible: popup.streams.length > 0
                    clip: true
                    spacing: 4
                    model: ScriptModel { values: popup.streams }
                    delegate: AudioStreamRow {
                        required property var modelData
                        node: modelData
                    }
                    ScrollBar.vertical: ScrollBar {}
                }
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 9
                color: advancedMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                Text {
                    anchors.centerIn: parent
                    text: "󰒓  Advanced audio settings"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                }
                MouseArea {
                    id: advancedMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["sh", "-c", "if command -v pavucontrol >/dev/null 2>&1; then exec pavucontrol; else exec helvum; fi"])
                }
            }
        }
    }
}
