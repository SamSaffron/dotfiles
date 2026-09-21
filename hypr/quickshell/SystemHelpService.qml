import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property bool connected: false
    property bool running: false
    property string status: "idle"
    property string error: ""
    property string sessionId: ""
    property string responseId: ""
    property alias messages: messageModel
    property var pendingSnapshot: null
    signal messagesUpdated(bool reset)

    ListModel { id: messageModel }

    Timer {
        id: snapshotTimer
        interval: 50
        onTriggered: {
            const value = root.pendingSnapshot
            root.pendingSnapshot = null
            if (value)
                root.applySnapshot(value)
        }
    }

    function syncMessages(incoming) {
        let reset = incoming.length < messageModel.count
        for (let i = 0; !reset && i < messageModel.count; i++)
            reset = messageModel.get(i).messageId !== incoming[i].id
        if (reset)
            messageModel.clear()

        for (let i = 0; i < incoming.length; i++) {
            const item = incoming[i]
            const row = {
                messageId: item.id || "",
                kind: item.kind || "",
                text: item.text || "",
                name: item.name || "",
                status: item.status || "",
                arguments: item.arguments || "",
                result: item.result || ""
            }
            if (i >= messageModel.count) {
                messageModel.append(row)
            } else {
                for (const key of Object.keys(row)) {
                    if (messageModel.get(i)[key] !== row[key])
                        messageModel.setProperty(i, key, row[key])
                }
            }
        }
        messagesUpdated(reset)
    }
    property var askUser: null
    property var approval: null
    readonly property bool ready: connected && !running

    function command(value) {
        if (!bridgeProcess.running)
            bridgeProcess.running = true
        bridgeProcess.write(JSON.stringify(value) + "\n")
    }

    function connectAndRestore() {
        command({ "action": "connect" })
    }

    function send(text) {
        const content = text.trim()
        if (content && !running)
            command({ "action": "send", "text": content })
    }

    function stop() {
        if (running)
            command({ "action": "stop" })
    }

    function newConversation() {
        command({ "action": "new" })
    }

    function answerAsk(answers, cancelled) {
        command({ "action": "ask", "answers": answers, "cancelled": Boolean(cancelled) })
    }

    function decideApproval(choice, cancelled) {
        command({ "action": "approve", "choice": choice, "cancelled": Boolean(cancelled) })
    }

    function applySnapshot(value) {
        connected = Boolean(value.connected)
        running = Boolean(value.running)
        status = value.status || "idle"
        error = value.error || ""
        sessionId = value.session_id || ""
        responseId = value.response_id || ""
        syncMessages(value.messages || [])
        askUser = value.ask_user || null
        approval = value.approval || null
    }

    function handleLine(line) {
        if (!line.trim())
            return
        try {
            const value = JSON.parse(line)
            if (value.type === "snapshot") {
                if (value.running) {
                    pendingSnapshot = value
                    if (!snapshotTimer.running)
                        snapshotTimer.start()
                } else {
                    snapshotTimer.stop()
                    pendingSnapshot = null
                    applySnapshot(value)
                }
            }
        } catch (parseError) {
            console.warn("Could not parse System Help bridge event:", parseError)
        }
    }

    Process {
        id: bridgeProcess
        command: ["python3", Quickshell.shellDir + "/system-help-bridge.py"]
        stdinEnabled: true
        running: true

        stdout: SplitParser {
            onRead: data => root.handleLine(data)
        }

        stderr: SplitParser {
            onRead: data => console.warn("System Help bridge:", data)
        }

        onExited: (exitCode, exitStatus) => {
            snapshotTimer.stop()
            root.pendingSnapshot = null
            root.connected = false
            root.running = false
            root.status = "error"
            root.error = "System Help bridge stopped"
            restartTimer.restart()
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        onTriggered: if (!bridgeProcess.running) bridgeProcess.running = true
    }
}
