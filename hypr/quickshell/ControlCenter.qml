import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var stats
    required property var anchorWindow
    required property var targetScreen

    readonly property var sink: Pipewire.defaultAudioSink
    property string selectedPlayerDbus: ""
    readonly property var mediaPlayer: {
        const players = Mpris.players.values
        if (players.length === 0)
            return null
        const selected = players.find(player => player.dbusName === selectedPlayerDbus)
        if (selected)
            return selected
        return players.find(player => player.isPlaying) || players[0]
    }
    readonly property int mediaPlayerCount: Mpris.players.values.length
    property bool confirmLogout: false

    function notificationTime(value) {
        return Qt.formatDateTime(new Date(value), "HH:mm")
    }

    function formatDuration(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "--:--"
        const rounded = Math.floor(seconds)
        const minutes = Math.floor(rounded / 60)
        const remainder = rounded % 60
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    }

    function cycleMediaPlayer() {
        const players = Mpris.players.values
        if (players.length < 2)
            return
        const current = players.indexOf(mediaPlayer)
        selectedPlayerDbus = players[(current + 1) % players.length].dbusName
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width - Theme.gap
    anchor.rect.y: -height - Theme.gap
    width: 390
    height: 590
    visible: shell.controlCenterOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.controlCenterOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (!visible && shell.controlCenterOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    PwObjectTracker {
        objects: [popup.sink]
    }

    Timer {
        interval: 500
        running: popup.visible && popup.mediaPlayer && popup.mediaPlayer.isPlaying
        repeat: true
        onTriggered: if (popup.mediaPlayer) popup.mediaPlayer.positionChanged()
    }

    Timer {
        interval: 3000
        running: popup.confirmLogout
        onTriggered: popup.confirmLogout = false
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
            spacing: 14

            Row {
                width: parent.width
                height: 36

                Column {
                    width: parent.width - closeButton.width
                    Text {
                        text: shell.controlCenterPage === "controls" ? "Control center" : "Notifications"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: shell.controlCenterPage === "controls"
                              ? Qt.formatDateTime(shell.clock.date, "dddd, d MMMM")
                              : shell.notificationHistory.length + (shell.notificationHistory.length === 1 ? " recent item" : " recent items")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    id: closeButton
                    width: 32
                    height: 32
                    radius: 9
                    color: closeMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    Text { anchors.centerIn: parent; text: "󰅖"; color: Theme.text; font.family: Theme.fontFamily }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: shell.controlCenterOpen = false
                    }
                }
            }

            Row {
                width: parent.width
                height: 34
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height
                    radius: Theme.radius
                    color: shell.controlCenterPage === "controls" ? Theme.accentSoft
                         : controlsTabMouse.containsMouse ? Theme.backgroundHover
                         : Theme.backgroundRaised

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓  Controls"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: controlsTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: shell.controlCenterPage = "controls"
                    }
                }

                Rectangle {
                    width: (parent.width - 8) / 2
                    height: parent.height
                    radius: Theme.radius
                    color: shell.controlCenterPage === "notifications" ? Theme.accentSoft
                         : notificationsTabMouse.containsMouse ? Theme.backgroundHover
                         : Theme.backgroundRaised

                    Text {
                        anchors.centerIn: parent
                        text: "󰂚  Notifications" + (shell.notificationUnread > 0 ? "  ·  " + shell.notificationUnread : "")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: notificationsTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            shell.controlCenterPage = "notifications"
                            shell.markNotificationsRead()
                        }
                    }
                }
            }

            Column {
                id: controlsPage
                visible: shell.controlCenterPage === "controls"
                width: parent.width
                spacing: 14

            Grid {
                width: parent.width
                columns: 3
                spacing: 8

                QuickAction {
                    icon: "󰖩"
                    label: "Wi-Fi"
                    onTriggered: Quickshell.execDetached(["sh", "-c", "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"])
                }
                QuickAction {
                    icon: "󰂯"
                    label: "Bluetooth"
                    onTriggered: Quickshell.execDetached(["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"])
                }
                QuickAction {
                    icon: shell.doNotDisturb ? "󰂛" : "󰂚"
                    label: shell.doNotDisturb ? "DND on" : "DND off"
                    active: shell.doNotDisturb
                    onTriggered: shell.doNotDisturb = !shell.doNotDisturb
                }
                QuickAction {
                    icon: "󰍹"
                    label: "Display"
                    onTriggered: Quickshell.execDetached(["sh", "-c", "command -v wdisplays >/dev/null && wdisplays || ~/.config/hypr/resolution.sh"])
                }
                QuickAction {
                    icon: "󰌾"
                    label: "Lock"
                    onTriggered: {
                        shell.controlCenterOpen = false
                        Quickshell.execDetached(["hyprlock"])
                    }
                }
                QuickAction {
                    icon: popup.confirmLogout ? "󰜺" : "󰍃"
                    label: popup.confirmLogout ? "Confirm exit" : "Log out"
                    active: popup.confirmLogout
                    onTriggered: {
                        if (popup.confirmLogout) {
                            Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
                        } else {
                            popup.confirmLogout = true
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 62
                radius: Theme.radius
                color: Theme.backgroundRaised

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - volumeValue.width
                            text: popup.sink && popup.sink.audio && popup.sink.audio.muted ? "  Volume muted" : "  Volume"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            id: volumeValue
                            text: popup.sink && popup.sink.audio ? Math.round(popup.sink.audio.volume * 100) + "%" : "--"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                    Slider {
                        width: parent.width
                        height: 18
                        from: 0
                        to: 1
                        value: popup.sink && popup.sink.audio ? popup.sink.audio.volume : 0
                        onMoved: if (popup.sink && popup.sink.audio) popup.sink.audio.volume = value
                        background: Rectangle {
                            x: parent.leftPadding
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth
                            height: 5
                            radius: 3
                            color: Theme.border
                            Rectangle {
                                width: parent.parent.visualPosition * parent.width
                                height: parent.height
                                radius: 3
                                color: Theme.accent
                            }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.text
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 118
                radius: Theme.radius
                color: Theme.backgroundRaised

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 78
                        height: 78
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Theme.radius
                        color: Theme.background
                        clip: true

                        Image {
                            id: artwork
                            anchors.fill: parent
                            source: popup.mediaPlayer ? popup.mediaPlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !popup.mediaPlayer || artwork.status !== Image.Ready
                            text: "󰎆"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 30
                        }
                    }

                    Column {
                        width: parent.width - 88
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Row {
                            width: parent.width
                            height: 38

                            Column {
                                width: parent.width - mediaButtons.width
                                Text {
                                    width: parent.width
                                    text: popup.mediaPlayer ? (popup.mediaPlayer.trackTitle || "Unknown title") : "Nothing playing"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: popup.mediaPlayer ? (popup.mediaPlayer.trackArtist || popup.mediaPlayer.identity) : "No active media player"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }

                            Row {
                                id: mediaButtons
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8
                                MediaButton {
                                    icon: "󰒮"
                                    available: popup.mediaPlayer && popup.mediaPlayer.canGoPrevious
                                    onTriggered: if (popup.mediaPlayer) popup.mediaPlayer.previous()
                                }
                                MediaButton {
                                    icon: popup.mediaPlayer && popup.mediaPlayer.isPlaying ? "󰏤" : "󰐊"
                                    available: popup.mediaPlayer && popup.mediaPlayer.canTogglePlaying
                                    onTriggered: if (popup.mediaPlayer) popup.mediaPlayer.togglePlaying()
                                }
                                MediaButton {
                                    icon: "󰒭"
                                    available: popup.mediaPlayer && popup.mediaPlayer.canGoNext
                                    onTriggered: if (popup.mediaPlayer) popup.mediaPlayer.next()
                                }
                            }
                        }

                        Slider {
                            width: parent.width
                            height: 16
                            enabled: popup.mediaPlayer && popup.mediaPlayer.positionSupported
                                     && popup.mediaPlayer.lengthSupported && popup.mediaPlayer.canSeek
                            from: 0
                            to: popup.mediaPlayer && popup.mediaPlayer.lengthSupported ? popup.mediaPlayer.length : 1
                            value: popup.mediaPlayer && popup.mediaPlayer.positionSupported ? popup.mediaPlayer.position : 0
                            onMoved: if (popup.mediaPlayer && popup.mediaPlayer.canSeek) popup.mediaPlayer.position = value
                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: parent.availableWidth
                                height: 4
                                radius: 2
                                color: Theme.border
                                Rectangle {
                                    width: parent.parent.visualPosition * parent.width
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accent
                                }
                            }
                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: 10
                                height: 10
                                radius: 5
                                color: Theme.text
                                visible: parent.enabled
                            }
                        }

                        Row {
                            width: parent.width
                            Text {
                                width: parent.width - playerIdentity.width
                                text: popup.formatDuration(popup.mediaPlayer ? popup.mediaPlayer.position : -1)
                                      + " / " + popup.formatDuration(popup.mediaPlayer && popup.mediaPlayer.lengthSupported ? popup.mediaPlayer.length : -1)
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                            }
                            Text {
                                id: playerIdentity
                                text: popup.mediaPlayer
                                      ? popup.mediaPlayer.identity + (popup.mediaPlayerCount > 1 ? "  " + "󰅂" : "")
                                      : ""
                                color: popup.mediaPlayerCount > 1 && playerMouse.containsMouse ? Theme.text : Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                MouseArea {
                                    id: playerMouse
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    enabled: popup.mediaPlayerCount > 1
                                    hoverEnabled: true
                                    onClicked: popup.cycleMediaPlayer()
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: metricsRow
                readonly property int metricCount: stats.gpu >= 0 ? 4 : 3

                width: parent.width
                spacing: 8
                MetricCard {
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    iconSource: "file://" + Quickshell.shellPath("assets/cpu-processor.svg")
                    label: "CPU"
                    value: stats.cpu + "%"
                }
                MetricCard {
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    iconSource: "file://" + Quickshell.shellPath("assets/ram-address-space.svg")
                    label: "RAM"
                    value: stats.memory + "%"
                }
                MetricCard {
                    visible: stats.gpu >= 0
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    iconSource: "file://" + Quickshell.shellPath("assets/gpu-dual-fan.svg")
                    label: "GPU"
                    value: stats.gpu + "%"
                }
                MetricCard {
                    width: (metricsRow.width - metricsRow.spacing * (metricsRow.metricCount - 1)) / metricsRow.metricCount
                    icon: "󰋊"
                    label: "Disk"
                    value: stats.disk + "%"
                }
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: 9
                color: fallbackMouse.containsMouse ? Theme.backgroundHover : Theme.accentSoft
                Text {
                    anchors.centerIn: parent
                    text: "Return to Waybar · Fuzzel · Dunst"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                }
                MouseArea {
                    id: fallbackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["sh", "-c", "~/.config/hypr/shell-mode current"])
                }
            }
            }

            Column {
                id: notificationsPage
                visible: shell.controlCenterPage === "notifications"
                width: parent.width
                height: 390
                spacing: 10

                Row {
                    width: parent.width
                    height: 34
                    spacing: 8

                    Rectangle {
                        width: parent.width - clearHistoryButton.width - 8
                        height: parent.height
                        radius: Theme.radius
                        color: dndMouse.containsMouse ? Theme.backgroundHover
                             : shell.doNotDisturb ? Theme.accentSoft
                             : Theme.backgroundRaised

                        Text {
                            anchors.centerIn: parent
                            text: shell.doNotDisturb ? "󰂛  Do Not Disturb on" : "󰂚  Do Not Disturb off"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: dndMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: shell.doNotDisturb = !shell.doNotDisturb
                        }
                    }

                    Rectangle {
                        id: clearHistoryButton
                        width: 86
                        height: parent.height
                        radius: Theme.radius
                        color: clearHistoryMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                        opacity: shell.notificationHistory.length > 0 ? 1 : 0.5

                        Text {
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                        }
                        MouseArea {
                            id: clearHistoryMouse
                            anchors.fill: parent
                            enabled: shell.notificationHistory.length > 0
                            hoverEnabled: true
                            onClicked: shell.clearNotificationHistory()
                        }
                    }
                }

                Rectangle {
                    visible: shell.notificationHistory.length === 0
                    width: parent.width
                    height: 330
                    radius: Theme.radius
                    color: Theme.backgroundRaised

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂚"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No recent notifications"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "New notifications will be kept here"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                Flickable {
                    id: notificationFlick
                    visible: shell.notificationHistory.length > 0
                    width: parent.width
                    height: 346
                    contentWidth: width
                    contentHeight: historyColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: historyColumn
                        width: notificationFlick.width
                        spacing: 8

                        Repeater {
                            model: shell.notificationHistory

                            delegate: Rectangle {
                                id: historyCard
                                required property var modelData

                                width: historyColumn.width
                                height: 84
                                radius: Theme.radius
                                color: Theme.backgroundRaised
                                border.width: modelData.urgency === 2 ? 1 : 0
                                border.color: Theme.critical

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 38
                                        height: 38
                                        radius: Theme.radius
                                        color: Theme.background

                                        IconImage {
                                            anchors.centerIn: parent
                                            width: 28
                                            height: 28
                                            source: historyCard.modelData.appIcon
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 78
                                        spacing: 2

                                        Row {
                                            width: parent.width
                                            Text {
                                                width: parent.width - historyTime.width
                                                text: historyCard.modelData.appName
                                                color: Theme.textMuted
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                id: historyTime
                                                text: popup.notificationTime(historyCard.modelData.receivedAt)
                                                color: Theme.textMuted
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                            }
                                        }
                                        Text {
                                            width: parent.width
                                            text: historyCard.modelData.summary
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            visible: text.length > 0
                                            text: historyCard.modelData.body
                                            textFormat: Text.StyledText
                                            color: Theme.textMuted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰅖"
                                        color: historyDismissMouse.containsMouse ? Theme.text : Theme.textMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        MouseArea {
                                            id: historyDismissMouse
                                            anchors.fill: parent
                                            anchors.margins: -8
                                            hoverEnabled: true
                                            onClicked: shell.dismissNotificationHistory(historyCard.modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: notificationFlick.contentHeight > notificationFlick.height
                        anchors.right: parent.right
                        width: 3
                        height: Math.max(28, parent.height * parent.height / notificationFlick.contentHeight)
                        y: notificationFlick.visibleArea.yPosition * parent.height
                        radius: 2
                        color: Theme.textMuted
                        opacity: 0.45
                    }
                }
            }
        }
    }
}
