#!/usr/bin/env python3
"""Exercise the real QML message model offscreen, without a provider or desktop."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HARNESS = r'''
import Quickshell
import QtQuick

ShellRoot {
    id: root
    property int created: 0
    property int destroyed: 0
    property var firstRow
    property var toolRow

    SystemHelpService { id: service }
    Item {
        width: 500; height: 500
        ListView {
            id: view
            anchors.fill: parent
            model: service.messages
            delegate: Item {
                required property var model
                required property int index
                readonly property var modelData: model
                property bool expanded: false
                width: 500; height: 30
                Component.onCompleted: root.created++
                Component.onDestruction: root.destroyed++
                Text { text: parent.modelData.text }
            }
        }
    }
    function check(condition, message) {
        if (!condition) {
            console.error("FAIL: " + message)
            Qt.exit(1)
            throw new Error(message)
        }
    }
    function rows(text) {
        return [
            {id: "intro", kind: "assistant", text: "Checking"},
            {id: "tool", kind: "tool", name: "shell", status: "done"},
            {id: "answer", kind: "assistant", text: text}
        ]
    }
    Timer {
        interval: 100; running: true
        onTriggered: {
            service.syncMessages(rows("A"))
            view.forceLayout()
            Qt.callLater(root.updateRows)
        }
    }
    function updateRows() {
        check(created === 3, "initial delegates")
        firstRow = view.itemAtIndex(0)
        toolRow = view.itemAtIndex(1)
        toolRow.expanded = true
        for (let i = 0; i < 100; i++)
            service.syncMessages(rows("Answer " + i))
        view.forceLayout()
        check(created === 3 && destroyed === 0, "streaming recreated delegates")
        check(firstRow === view.itemAtIndex(0), "intro identity changed")
        check(toolRow === view.itemAtIndex(1) && toolRow.expanded, "tool state lost")
        check(view.itemAtIndex(2).modelData.text === "Answer 99", "text role stale")
        for (let i = 0; i < 100; i++)
            service.handleLine(JSON.stringify({type: "snapshot", running: true, messages: rows("Batch " + i)}))
        check(service.messages.get(2).text === "Answer 99", "batch not deferred")
        batchCheck.start()
    }
    Timer {
        id: batchCheck
        interval: 100
        onTriggered: {
            check(service.messages.get(2).text === "Batch 99", "latest batch not applied")
            check(created === 3 && destroyed === 0, "batch recreated delegates")
            service.handleLine(JSON.stringify({type: "snapshot", running: true, messages: rows("stale")}))
            service.handleLine(JSON.stringify({type: "snapshot", running: false, messages: rows("Final")}))
            check(service.messages.get(2).text === "Final", "completion not immediate")
            finalCheck.start()
        }
    }
    Timer {
        id: finalCheck
        interval: 100
        onTriggered: {
            check(service.messages.get(2).text === "Final", "stale batch overwrote completion")
            service.syncMessages([{id: "new", kind: "user", text: "New"}])
            check(service.messages.count === 1 && service.messages.get(0).messageId === "new", "new conversation not reset")
            console.log("STREAMING MODEL TEST PASSED")
            Qt.quit()
        }
    }
    Timer {
        interval: 5000; running: true
        onTriggered: { console.error("FAIL: timed out"); Qt.exit(1) }
    }
}
'''


def main():
    source = Path(__file__).parent
    with tempfile.TemporaryDirectory(prefix="system-help-qml-") as temp:
        root = Path(temp)
        shutil.copyfile(source / "SystemHelpService.qml", root / "SystemHelpService.qml")
        # Service process is a harmless stub; no CLI, MCP or saved user state.
        (root / "system-help-bridge.py").write_text("import sys\nfor line in sys.stdin: pass\n")
        (root / "shell.qml").write_text(HARNESS)
        env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_STATE_HOME=str(root / "state"))
        result = subprocess.run(
            ["qs", "-p", str(root / "shell.qml"), "--no-color"],
            env=env, capture_output=True, text=True, timeout=15,
        )
        output = result.stdout + result.stderr
        print(output, end="")
        if result.returncode or "STREAMING MODEL TEST PASSED" not in output or "FAIL:" in output:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
