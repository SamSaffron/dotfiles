import Quickshell
import QtQuick
import QtQuick.Controls
import "Theme.js" as Theme

PopupWindow {
    id: popup

    required property var shell
    required property var service
    required property var anchorWindow
    required property var anchorItem
    required property var targetScreen

    property var askSelections: []
    property var askCustom: []
    property string interactionError: ""

    function resetAskAnswers() {
        const count = service.askUser ? service.askUser.questions.length : 0
        askSelections = Array.from({ length: count }, () => [])
        askCustom = Array.from({ length: count }, () => "")
        interactionError = ""
    }

    function selectAskOption(questionIndex, label, multiSelect) {
        const next = askSelections.map(values => values.slice())
        while (next.length <= questionIndex)
            next.push([])
        if (multiSelect) {
            const at = next[questionIndex].indexOf(label)
            if (at >= 0)
                next[questionIndex].splice(at, 1)
            else
                next[questionIndex].push(label)
        } else {
            next[questionIndex] = [label]
            const custom = askCustom.slice()
            custom[questionIndex] = ""
            askCustom = custom
        }
        askSelections = next
        interactionError = ""
    }

    function setAskCustom(questionIndex, value) {
        const custom = askCustom.slice()
        while (custom.length <= questionIndex)
            custom.push("")
        custom[questionIndex] = value
        askCustom = custom
        if (value.trim()) {
            const next = askSelections.map(values => values.slice())
            next[questionIndex] = []
            askSelections = next
        }
        interactionError = ""
    }

    function submitAsk() {
        if (!service.askUser)
            return
        const answers = []
        for (let index = 0; index < service.askUser.questions.length; index++) {
            const question = service.askUser.questions[index]
            const selected = askSelections[index] || []
            const custom = (askCustom[index] || "").trim()
            if (question.multi_select && selected.length === 0) {
                interactionError = (question.header || "Question " + (index + 1)) + ": choose at least one option"
                return
            }
            if (!question.multi_select && selected.length === 0 && !custom) {
                interactionError = (question.header || "Question " + (index + 1)) + ": choose or enter an answer"
                return
            }
            answers.push({
                "question_index": index,
                "header": question.header || "",
                "selected": custom || selected.join(", "),
                "selected_list": question.multi_select ? selected : undefined,
                "is_custom": Boolean(custom),
                "is_multi_select": Boolean(question.multi_select)
            })
        }
        service.answerAsk(answers, false)
    }

    function sendComposer() {
        const content = composer.text.trim()
        if (!content || service.running)
            return
        composer.clear()
        service.send(content)
    }

    anchor.window: anchorWindow
    anchor.rect.x: anchorItem.mapToItem(anchorWindow.contentItem, 0, 0).x + anchorItem.width / 2 - width / 2
    anchor.rect.y: -height - Theme.gap
    implicitWidth: 520
    implicitHeight: Math.min(700, targetScreen ? targetScreen.height - Theme.barHeight - Theme.gap * 3 : 700)
    visible: shell.systemHelpOpen && shell.popupScreen === targetScreen
    grabFocus: true
    color: Theme.transparent

    onClosed: {
        if (shell.systemHelpOpen && shell.popupScreen === targetScreen)
            shell.closePopups()
    }

    onVisibleChanged: {
        if (visible) {
            service.connectAndRestore()
            Qt.callLater(() => composer.forceActiveFocus())
        } else if (shell.systemHelpOpen && shell.popupScreen === targetScreen) {
            shell.closePopups()
        }
    }

    Connections {
        target: service
        function onAskUserChanged() { popup.resetAskAnswers() }
        function onMessagesUpdated(reset) {
            if (reset)
                transcript.followBottom = true
            transcript.scheduleFollow()
        }
    }

    Timer {
        id: followTimer
        interval: 0
        onTriggered: {
            if (transcript.followBottom && !transcript.moving) {
                transcript.forceLayout()
                transcript.positionViewAtEnd()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.background
        border.width: 1
        border.color: Theme.border

        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            height: 38

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 9

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: service.status === "error" ? Theme.critical
                         : service.running ? Theme.warning
                         : service.connected ? Theme.accent
                         : Theme.textMuted
                }

                Column {
                    Text {
                        text: "System Help"
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Text {
                        text: service.status === "input" ? "Waiting for your answer"
                            : service.status === "approval" ? "Approval needed"
                            : service.status === "reconnecting" ? "Reconnecting…"
                            : service.running ? "Working…"
                            : service.connected ? "Ready"
                            : service.status === "connecting" ? "Connecting…"
                            : "Not connected"
                        color: Theme.textMuted
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 9
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    visible: service.running
                    width: visible ? 31 : 0
                    height: 31
                    radius: 9
                    color: stopMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    Text {
                        anchors.centerIn: parent
                        text: "󰓛"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: stopMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: service.stop()
                    }
                    ToolTip.visible: stopMouse.containsMouse
                    ToolTip.text: "Stop response"
                }

                Rectangle {
                    width: 31
                    height: 31
                    radius: 9
                    color: newMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: newMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            service.newConversation()
                            composer.clear()
                            composer.forceActiveFocus()
                        }
                    }
                    ToolTip.visible: newMouse.containsMouse
                    ToolTip.text: "New conversation"
                }

                Rectangle {
                    width: 31
                    height: 31
                    radius: 9
                    color: closeMouse.containsMouse ? Theme.backgroundHover : Theme.backgroundRaised
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: Theme.text
                        font.family: Theme.fontFamily
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: shell.systemHelpOpen = false
                    }
                }
            }
        }

        ListView {
            id: transcript
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: interactionPanel.visible ? interactionPanel.top : composerBox.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            clip: true
            spacing: 8
            model: service.messages
            property bool followBottom: true

            function scheduleFollow() {
                if (followBottom && !moving && !followTimer.running)
                    followTimer.start()
            }

            onContentHeightChanged: scheduleFollow()
            onHeightChanged: scheduleFollow()
            onMovementStarted: followBottom = false
            onMovementEnded: followBottom = atYEnd

            delegate: Item {
                id: messageDelegate
                required property var model
                required property int index
                readonly property var modelData: model
                readonly property bool streaming: service.running
                    && index === transcript.count - 1 && modelData.kind === "assistant"
                width: ListView.view.width
                height: modelData.kind === "tool" ? toolBox.height : messageBox.height

                Rectangle {
                    id: messageBox
                    visible: messageDelegate.modelData.kind !== "tool"
                    width: parent.width
                    height: visible ? messageText.implicitHeight + 22 : 0
                    radius: Theme.radius
                    color: messageDelegate.modelData.kind === "user" ? Theme.backgroundRaised : Theme.transparent

                    Text {
                        id: messageText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 11
                        text: messageDelegate.modelData.text || ""
                        color: Theme.text
                        font.family: Theme.usageFontFamily
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        // Incomplete Markdown (especially tables) changes shape as
                        // tokens arrive. Format once this text segment is finished.
                        textFormat: messageDelegate.modelData.kind === "assistant" && !messageDelegate.streaming
                            ? Text.MarkdownText : Text.PlainText
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }

                Rectangle {
                    id: toolBox
                    property bool expanded: false
                    visible: messageDelegate.modelData.kind === "tool"
                    width: parent.width
                    height: visible ? 38 + (expanded ? toolDetails.implicitHeight + 12 : 0) : 0
                    radius: 8
                    color: Theme.backgroundRaised
                    border.width: 1
                    border.color: messageDelegate.modelData.status === "error" ? Theme.critical : Theme.border

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 11
                        anchors.rightMargin: 11
                        height: 38
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: toolBox.expanded ? "󰅀" : "󰅂"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - toolState.width - 28
                            text: messageDelegate.modelData.name || "tool"
                            color: Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            id: toolState
                            anchors.verticalCenter: parent.verticalCenter
                            text: messageDelegate.modelData.status === "running" ? "running"
                                : messageDelegate.modelData.status === "error" ? "failed" : "done"
                            color: messageDelegate.modelData.status === "error" ? Theme.critical : Theme.textMuted
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 9
                        }
                    }

                    MouseArea {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 38
                        onClicked: toolBox.expanded = !toolBox.expanded
                    }

                    Column {
                        id: toolDetails
                        visible: toolBox.expanded
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 38
                        anchors.leftMargin: 11
                        anchors.rightMargin: 11
                        spacing: 5

                        Text {
                            width: parent.width
                            visible: Boolean(messageDelegate.modelData.arguments)
                            text: messageDelegate.modelData.arguments || ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 10
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            visible: Boolean(messageDelegate.modelData.result)
                            text: messageDelegate.modelData.result || ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: service.messages.count === 0 && !service.error
                text: ""
            }
        }

        Rectangle {
            id: interactionPanel
            visible: Boolean(service.askUser || service.approval)
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: composerBox.top
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 8
            height: visible ? Math.min(265, interactionContent.implicitHeight + 20) : 0
            radius: Theme.radius
            color: Theme.backgroundRaised
            border.width: 1
            border.color: Theme.border

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                clip: true
                contentWidth: width
                contentHeight: interactionContent.implicitHeight

                Column {
                    id: interactionContent
                    width: parent.width
                    spacing: 8

                    Column {
                        visible: Boolean(service.askUser)
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: service.askUser ? service.askUser.questions : []

                            delegate: Column {
                                id: questionDelegate
                                required property var modelData
                                required property int index
                                width: parent.width
                                spacing: 5

                                Text {
                                    width: parent.width
                                    text: (questionDelegate.modelData.header ? questionDelegate.modelData.header + " · " : "")
                                        + questionDelegate.modelData.question
                                    color: Theme.text
                                    font.family: Theme.usageFontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    wrapMode: Text.Wrap
                                }

                                Repeater {
                                    model: questionDelegate.modelData.options || []

                                    delegate: Rectangle {
                                        id: askOption
                                        required property var modelData
                                        width: questionDelegate.width
                                        height: optionText.implicitHeight + 12
                                        radius: 7
                                        readonly property bool selected: (popup.askSelections[questionDelegate.index] || []).indexOf(modelData.label) >= 0
                                        color: selected ? Theme.accentSoft : optionMouse.containsMouse ? Theme.backgroundHover : Theme.background

                                        Text {
                                            id: optionText
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 9
                                            anchors.rightMargin: 9
                                            text: askOption.modelData.label + (askOption.modelData.description ? " — " + askOption.modelData.description : "")
                                            color: Theme.text
                                            font.family: Theme.usageFontFamily
                                            font.pixelSize: 10
                                            wrapMode: Text.Wrap
                                        }
                                        MouseArea {
                                            id: optionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: popup.selectAskOption(questionDelegate.index, askOption.modelData.label, Boolean(questionDelegate.modelData.multi_select))
                                        }
                                    }
                                }

                                TextField {
                                    visible: !questionDelegate.modelData.multi_select
                                    width: parent.width
                                    height: 32
                                    placeholderText: "Other…"
                                    text: popup.askCustom[questionDelegate.index] || ""
                                    color: Theme.text
                                    font.family: Theme.usageFontFamily
                                    font.pixelSize: 10
                                    onTextEdited: popup.setAskCustom(questionDelegate.index, text)
                                    background: Rectangle {
                                        radius: 7
                                        color: Theme.background
                                        border.width: parent.activeFocus ? 1 : 0
                                        border.color: Theme.accent
                                    }
                                }
                            }
                        }

                        Text {
                            visible: Boolean(popup.interactionError)
                            width: parent.width
                            text: popup.interactionError
                            color: Theme.critical
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 9
                            wrapMode: Text.Wrap
                        }

                        Row {
                            spacing: 7
                            Rectangle {
                                width: 78
                                height: 30
                                radius: 7
                                color: cancelAskMouse.containsMouse ? Theme.backgroundHover : Theme.background
                                Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.textMuted; font.family: Theme.usageFontFamily; font.pixelSize: 10 }
                                MouseArea { id: cancelAskMouse; anchors.fill: parent; hoverEnabled: true; onClicked: service.answerAsk([], true) }
                            }
                            Rectangle {
                                width: 78
                                height: 30
                                radius: 7
                                color: answerAskMouse.containsMouse ? Theme.accent : Theme.accentSoft
                                Text { anchors.centerIn: parent; text: "Answer"; color: Theme.text; font.family: Theme.usageFontFamily; font.pixelSize: 10; font.bold: true }
                                MouseArea { id: answerAskMouse; anchors.fill: parent; hoverEnabled: true; onClicked: popup.submitAsk() }
                            }
                        }
                    }

                    Column {
                        visible: Boolean(service.approval)
                        width: parent.width
                        spacing: 7

                        Text {
                            width: parent.width
                            text: service.approval ? service.approval.title : ""
                            color: Theme.text
                            font.family: Theme.usageFontFamily
                            font.pixelSize: 11
                            font.bold: true
                            wrapMode: Text.Wrap
                        }
                        Text {
                            width: parent.width
                            text: service.approval ? (service.approval.path || service.approval.work_dir || "") : ""
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            wrapMode: Text.WrapAnywhere
                        }
                        Repeater {
                            model: service.approval ? service.approval.options : []
                            delegate: Rectangle {
                                id: approvalOption
                                required property var modelData
                                width: parent.width
                                height: approvalText.implicitHeight + 12
                                radius: 7
                                color: approvalMouse.containsMouse ? Theme.backgroundHover : Theme.background
                                Text {
                                    id: approvalText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    text: approvalOption.modelData.label + (approvalOption.modelData.description ? " — " + approvalOption.modelData.description : "")
                                    color: approvalOption.modelData.choice === "deny" ? Theme.critical : Theme.text
                                    font.family: Theme.usageFontFamily
                                    font.pixelSize: 10
                                    wrapMode: Text.Wrap
                                }
                                MouseArea {
                                    id: approvalMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: service.decideApproval(Number(approvalOption.modelData.index), false)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: composerBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 14
            height: 72
            radius: Theme.radius
            color: Theme.backgroundRaised
            border.width: composer.activeFocus ? 1 : 0
            border.color: Theme.accent

            TextArea {
                id: composer
                anchors.left: parent.left
                anchors.right: sendButton.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 7
                anchors.rightMargin: 5
                enabled: !service.running
                placeholderText: service.running ? "Waiting for response…" : "Ask for help…"
                color: Theme.text
                placeholderTextColor: Theme.textMuted
                font.family: Theme.usageFontFamily
                font.pixelSize: 12
                wrapMode: TextEdit.Wrap
                background: null
                Keys.onPressed: event => {
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && !(event.modifiers & Qt.ShiftModifier)) {
                        event.accepted = true
                        popup.sendComposer()
                    }
                }
            }

            Rectangle {
                id: sendButton
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                width: 34
                height: 34
                radius: 9
                color: composer.text.trim() && !service.running
                     ? sendMouse.containsMouse ? Theme.accent : Theme.accentSoft
                     : Theme.background

                Text {
                    anchors.centerIn: parent
                    text: "󰒊"
                    color: composer.text.trim() && !service.running ? Theme.text : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                }
                MouseArea {
                    id: sendMouse
                    anchors.fill: parent
                    enabled: Boolean(composer.text.trim()) && !service.running
                    hoverEnabled: true
                    onClicked: popup.sendComposer()
                }
            }
        }

        Text {
            visible: Boolean(service.error) && !interactionPanel.visible
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: composerBox.top
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.bottomMargin: 6
            text: service.error
            color: Theme.critical
            font.family: Theme.usageFontFamily
            font.pixelSize: 9
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
