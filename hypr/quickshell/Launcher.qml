import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

PanelWindow {
    id: launcher

    required property var modelData
    required property var shell

    screen: modelData
    visible: shell.launcherOpen && shell.popupScreen === modelData
    color: "#66000000"
    focusable: true
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    onVisibleChanged: {
        if (visible) {
            search.text = ""
            appList.currentIndex = 0
            search.forceActiveFocus()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: shell.launcherOpen = false
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(620, launcher.width - 48)
        height: Math.min(650, launcher.height - 80)
        radius: 16
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                width: parent.width
                height: 52
                radius: 12
                color: Theme.backgroundRaised
                border.width: search.activeFocus ? 1 : 0
                border.color: Theme.accent

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                    }

                    TextInput {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        color: Theme.text
                        selectionColor: Theme.accent
                        selectedTextColor: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: search.text.length === 0
                            text: "Search applications…"
                            color: Theme.textMuted
                            font: search.font
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                shell.launcherOpen = false
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 1)
                                appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                appList.currentIndex = Math.max(0, appList.currentIndex - 1)
                                appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                                event.accepted = true
                            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && appList.currentItem) {
                                appList.currentItem.launch()
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            Text {
                text: search.text.length === 0 ? "Applications" : appList.count + " results"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
            }

            ListView {
                id: appList
                width: parent.width
                height: parent.height - 100
                spacing: 4
                clip: true
                currentIndex: 0

                model: ScriptModel {
                    values: {
                        const needle = search.text.trim().toLowerCase()
                        const entries = DesktopEntries.applications.values.slice()
                        const filtered = needle.length === 0 ? entries : entries.filter(entry => {
                            return entry.name.toLowerCase().includes(needle)
                                || entry.genericName.toLowerCase().includes(needle)
                                || entry.keywords.join(" ").toLowerCase().includes(needle)
                        })
                        return filtered.sort((a, b) => a.name.localeCompare(b.name)).slice(0, 80)
                    }
                }

                highlightMoveDuration: 120
                highlight: Rectangle {
                    radius: 10
                    color: Theme.accentSoft
                }

                delegate: Item {
                    id: entry
                    required property var modelData
                    required property int index

                    width: appList.width
                    height: 54

                    function launch() {
                        modelData.execute()
                        shell.launcherOpen = false
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 12

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 9
                            color: Theme.backgroundRaised
                            IconImage {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 50
                            Text {
                                width: parent.width
                                text: entry.modelData.name
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: entry.modelData.genericName || entry.modelData.comment
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: appList.currentIndex = entry.index
                        onClicked: entry.launch()
                    }
                }

                ScrollBar.vertical: ScrollBar {}
            }
        }
    }
}
