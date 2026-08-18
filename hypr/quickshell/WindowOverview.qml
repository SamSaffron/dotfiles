import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "Theme.js" as Theme

PanelWindow {
    id: overview

    required property var modelData
    required property var shell

    property string query: ""
    property int selectedWorkspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property var availableWorkspaces: Hyprland.workspaces.values.filter(workspace =>
        workspace.id > 0 && workspace.toplevels.values.length > 0)

    function appId(toplevel) {
        if (!toplevel)
            return "application-x-executable"
        return toplevel.lastIpcObject.class
            || toplevel.lastIpcObject.initialClass
            || (toplevel.wayland ? toplevel.wayland.appId : "")
            || "application-x-executable"
    }

    function activateWindow(toplevel) {
        if (toplevel && toplevel.wayland)
            toplevel.wayland.activate()
        shell.overviewOpen = false
    }

    function closeWindow(toplevel) {
        if (toplevel && toplevel.wayland)
            toplevel.wayland.close()
    }

    screen: modelData
    visible: shell.overviewOpen && shell.popupScreen === modelData
    color: "#99000000"
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
            query = ""
            selectedWorkspace = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            windowGrid.currentIndex = 0
            search.forceActiveFocus()
            Hyprland.refreshToplevels()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: shell.overviewOpen = false
    }

    Rectangle {
        id: overviewCard
        anchors.centerIn: parent
        width: Math.min(1500, overview.width - 80,
            Math.max(620, Math.max(1, windowGrid.count) * 360 + 40))
        readonly property int visibleRows: Math.max(1, Math.min(3,
            Math.ceil(windowGrid.count / Math.max(1, windowGrid.columnCount))))
        height: Math.min(overview.height - 72, 152 + visibleRows * windowGrid.cellHeight)
        radius: 18
        color: Theme.background
        border.width: 1
        border.color: "#45698c"

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Row {
                width: parent.width
                height: 46
                spacing: 12

                Rectangle {
                    width: parent.width - closeButton.width - 12
                    height: parent.height
                    radius: Theme.radius
                    color: Theme.backgroundRaised
                    border.width: search.activeFocus ? 1 : 0
                    border.color: Theme.accent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                        }

                        TextInput {
                            id: search
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 34
                            text: overview.query
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: "#ffffff"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            clip: true
                            onTextChanged: {
                                overview.query = text
                                windowGrid.currentIndex = 0
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text.length === 0
                                text: "Search open windows…"
                                color: Theme.textMuted
                                font: search.font
                            }

                            Keys.onPressed: event => {
                                const columns = windowGrid.columnCount
                                if (event.key === Qt.Key_Escape) {
                                    overview.shell.overviewOpen = false
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                                    const step = event.key === Qt.Key_Down ? columns : 1
                                    windowGrid.currentIndex = Math.min(windowGrid.count - 1, windowGrid.currentIndex + step)
                                    windowGrid.positionViewAtIndex(windowGrid.currentIndex, GridView.Contain)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                    const step = event.key === Qt.Key_Up ? columns : 1
                                    windowGrid.currentIndex = Math.max(0, windowGrid.currentIndex - step)
                                    windowGrid.positionViewAtIndex(windowGrid.currentIndex, GridView.Contain)
                                    event.accepted = true
                                } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && windowGrid.currentItem) {
                                    windowGrid.currentItem.activate()
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: closeButton
                    width: 46
                    height: 46
                    radius: Theme.radius
                    color: closeMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: overview.shell.overviewOpen = false
                    }
                }
            }

            Flickable {
                width: parent.width
                height: 38
                contentWidth: workspaceRow.width
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: workspaceRow
                    height: parent.height
                    spacing: 8

                    Repeater {
                        model: overview.availableWorkspaces

                        delegate: Rectangle {
                            id: workspaceButton
                            required property var modelData

                            width: Math.max(96, workspaceText.implicitWidth + 26)
                            height: 36
                            radius: Theme.radius
                            color: overview.selectedWorkspace === modelData.id && overview.query.length === 0
                                 ? Theme.accentSoft
                                 : workspaceMouse.containsMouse ? Theme.backgroundHover
                                 : Theme.backgroundRaised
                            border.width: overview.selectedWorkspace === modelData.id && overview.query.length === 0 ? 1 : 0
                            border.color: Theme.accent

                            Text {
                                id: workspaceText
                                anchors.centerIn: parent
                                text: modelData.name + "  ·  " + modelData.toplevels.values.length
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    overview.query = ""
                                    search.text = ""
                                    overview.selectedWorkspace = workspaceButton.modelData.id
                                    windowGrid.currentIndex = 0
                                }
                            }
                        }
                    }
                }
            }

            GridView {
                id: windowGrid
                width: Math.min(parent.width, Math.max(1, Math.min(count, 4)) * 360)
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height - 112
                property int columnCount: Math.max(1, Math.min(4,
                    Math.min(Math.max(1, count), Math.floor(width / 330))))
                clip: true
                cellWidth: width / columnCount
                cellHeight: 300
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    values: {
                        const needle = overview.query.trim().toLowerCase()
                        return Hyprland.toplevels.values.filter(toplevel => {
                            if (!toplevel.wayland || !toplevel.address)
                                return false
                            if (!needle)
                                return toplevel.workspace && toplevel.workspace.id === overview.selectedWorkspace
                            const haystack = (toplevel.title + " " + overview.appId(toplevel)
                                + " " + (toplevel.workspace ? toplevel.workspace.name : "")).toLowerCase()
                            return haystack.includes(needle)
                        })
                    }
                }

                delegate: Item {
                    id: windowItem
                    required property var modelData
                    required property int index

                    width: windowGrid.cellWidth
                    height: windowGrid.cellHeight

                    function activate() {
                        overview.activateWindow(modelData)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 9
                        radius: 14
                        color: Theme.backgroundRaised
                        border.width: 1
                        border.color: windowGrid.currentIndex === windowItem.index ? Theme.accent : Theme.border
                        clip: true

                        ScreencopyView {
                            id: preview
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                bottom: footer.top
                            }
                            captureSource: overview.visible ? windowItem.modelData.wayland : null
                            live: overview.visible
                        }

                        Rectangle {
                            anchors.fill: preview
                            visible: !preview.hasContent
                            color: Theme.background

                            IconImage {
                                anchors.centerIn: parent
                                width: 56
                                height: 56
                                source: Quickshell.iconPath(overview.appId(windowItem.modelData), "application-x-executable")
                            }
                        }

                        Rectangle {
                            id: footer
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 64
                            color: footerMouse.containsMouse ? "#1d3152" : Theme.background

                            MouseArea {
                                id: footerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: windowGrid.currentIndex = windowItem.index
                                onClicked: windowItem.activate()
                            }

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 9

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 28
                                    height: 28
                                    source: Quickshell.iconPath(overview.appId(windowItem.modelData), "application-x-executable")
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - closeWindowButton.width - 47
                                    Text {
                                        width: parent.width
                                        text: windowItem.modelData.title || overview.appId(windowItem.modelData)
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: overview.appId(windowItem.modelData)
                                            + (overview.query.length > 0 && windowItem.modelData.workspace
                                               ? "  ·  Workspace " + windowItem.modelData.workspace.name : "")
                                        color: Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    id: closeWindowButton
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30
                                    height: 30
                                    radius: Theme.radius
                                    color: closeWindowMouse.containsMouse ? Theme.backgroundHover : Theme.transparent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        color: closeWindowMouse.containsMouse ? Theme.critical : Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        id: closeWindowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: mouse => {
                                            mouse.accepted = true
                                            overview.closeWindow(windowItem.modelData)
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: previewMouse
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                bottom: footer.top
                            }
                            hoverEnabled: true
                            onEntered: windowGrid.currentIndex = windowItem.index
                            onClicked: windowItem.activate()
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: windowGrid.count === 0
                    text: overview.query.length > 0 ? "No matching windows" : "No windows on this workspace"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }
            }
        }
    }
}
