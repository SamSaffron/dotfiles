#!/usr/bin/env python3
"""Lifecycle tests for the direct term-llm System Help bridge."""

from __future__ import annotations

import importlib.util
import json
import os
import pathlib
import tempfile
import time
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("system-help-bridge.py")
SPEC = importlib.util.spec_from_file_location("system_help_bridge", MODULE_PATH)
assert SPEC and SPEC.loader
bridge_module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(bridge_module)
Bridge = bridge_module.Bridge


MOCK_CLI = r'''#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import time

args = sys.argv[1:]
with open(os.environ["MOCK_CAPTURE"], "a", encoding="utf-8") as capture:
    capture.write(json.dumps(args, separators=(",", ":")) + "\n")

prompt = args[-1]
resume_arg = next((arg for arg in args if arg.startswith("--resume=")), "")
if resume_arg:
    session_id = resume_arg.split("=", 1)[1]
else:
    session_id = "session-exact-123"

def emit(value):
    print(json.dumps(value, separators=(",", ":")), flush=True)

emit({
    "type": "session.started", "seq": 0, "ts": "2026-09-12T00:00:00Z",
    "session_id": session_id, "provider": "mock", "model": "mock-model",
    "agent": "system-help", "tools": "shell,read_file", "mcp": "",
    "yolo": False, "search": False, "resuming": bool(resume_arg),
})
if prompt == "__fail__":
    emit({"type": "error", "seq": 1, "ts": "x", "message": "mock failure"})
    emit({"type": "stats", "seq": 2, "ts": "x", "tool_calls": 0})
    emit({"type": "done", "seq": 3, "ts": "x", "tokens": 0})
    print("mock stderr detail", file=sys.stderr)
    raise SystemExit(3)
if prompt == "__eof__":
    emit({"type": "text.delta", "seq": 1, "ts": "x", "text": "clean eof"})
    raise SystemExit(0)
if prompt in {"__wait__", "__new__", "__shutdown__"}:
    emit({"type": "text.delta", "seq": 1, "ts": "x", "text": "partial"})
    time.sleep(30)
    raise SystemExit(0)
if prompt == "__bad_json__":
    print("not json", flush=True)
    time.sleep(30)
    raise SystemExit(0)

emit({"type": "text.delta", "seq": 1, "ts": "x", "text": "hello "})
emit({"type": "text.delta", "seq": 2, "ts": "x", "text": "world"})
emit({
    "type": "tool.started", "seq": 3, "ts": "x", "call_id": "call-1",
    "name": "read_file", "info": "(/tmp/example)", "args": {"path": "/tmp/example"},
})
emit({
    "type": "guardian.review", "seq": 4, "ts": "x", "call_id": "call-1",
    "tool": "read_file", "path": "/tmp/example", "is_write": False,
    "command": "", "workdir": "", "message": "guardian: approved",
    "outcome": "approved", "model": "guardian-model",
})
emit({
    "type": "tool.completed", "seq": 5, "ts": "x", "call_id": "call-1",
    "name": "read_file", "info": "(/tmp/example)", "success": True,
})
emit({"type": "usage", "seq": 6, "ts": "x", "input_tokens": 10, "output_tokens": 2})
emit({"type": "stats", "seq": 7, "ts": "x", "tool_calls": 1})
emit({"type": "done", "seq": 8, "ts": "x", "tokens": 2})
'''


def wait_for(predicate, timeout: float = 4.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.01)
    raise AssertionError("timed out waiting for bridge state")


class BridgeCLITest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = pathlib.Path(self.temp.name)
        self.mock = root / "term-llm-mock"
        self.mock.write_text(MOCK_CLI, encoding="utf-8")
        self.mock.chmod(0o700)
        self.capture = root / "argv.jsonl"
        self.old_env = {
            key: os.environ.get(key)
            for key in ("XDG_STATE_HOME", "TERM_LLM_BIN", "MOCK_CAPTURE")
        }
        os.environ["XDG_STATE_HOME"] = str(root / "state")
        os.environ["TERM_LLM_BIN"] = str(self.mock)
        os.environ["MOCK_CAPTURE"] = str(self.capture)
        self.snapshots: list[dict] = []
        self.bridge = Bridge(emit=self.collect)

    def tearDown(self) -> None:
        self.bridge.shutdown()
        for key, value in self.old_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
        self.temp.cleanup()

    def collect(self, line: str, flush: bool = False) -> None:
        self.snapshots.append(json.loads(line))

    def captured_argv(self) -> list[list[str]]:
        if not self.capture.exists():
            return []
        return [json.loads(line) for line in self.capture.read_text().splitlines()]

    def wait_finished(self) -> None:
        wait_for(lambda: not self.bridge.running)

    def test_real_jsonl_projection_persistence_and_exact_resume_argv(self) -> None:
        self.bridge.connect()
        self.assertTrue(self.bridge.connected)
        self.assertFalse(self.capture.exists(), "connect must not invoke term-llm")

        prompt = "--resume is prompt data"
        self.bridge.send(prompt)
        self.wait_finished()
        self.assertEqual("completed", self.bridge.status)
        self.assertEqual("session-exact-123", self.bridge.session_id)
        assistant = next(m for m in self.bridge.messages if m["kind"] == "assistant")
        tool = next(m for m in self.bridge.messages if m["kind"] == "tool")
        self.assertEqual("hello world", assistant["text"])
        self.assertEqual("done", tool["status"])
        self.assertEqual('{"path":"/tmp/example"}', tool["arguments"])
        self.assertEqual("guardian: approved", tool["result"])

        first = self.captured_argv()[0]
        self.assertEqual(
            [
                "ask", "--agent", "system-help", "--json", "--approval", "auto",
                "--", prompt,
            ],
            first,
        )
        self.assertNotIn("--yolo", first)

        restored = Bridge(emit=lambda *_args, **_kwargs: None)
        self.assertEqual("session-exact-123", restored.session_id)
        self.assertEqual(self.bridge.messages, restored.messages)
        restored.shutdown()

        self.bridge.send("second turn")
        self.wait_finished()
        second = self.captured_argv()[1]
        self.assertEqual(
            [
                "ask", "--agent", "system-help", "--json", "--approval", "auto",
                "--resume=session-exact-123", "--", "second turn",
            ],
            second,
        )
        self.assertIn("--resume=session-exact-123", second)

    def test_text_tool_text_preserves_execution_order(self) -> None:
        self.bridge.response_id = "test-run"
        events = [
            {"type": "text.delta", "text": "I’ll check "},
            {"type": "text.delta", "text": "memory."},
            {"type": "tool.started", "call_id": "shell-1", "name": "shell"},
            {"type": "tool.completed", "call_id": "shell-1", "success": True},
            {"type": "text.delta", "text": "Memory looks "},
            {"type": "text.delta", "text": "healthy."},
            {"type": "tool.started", "call_id": "shell-2", "name": "shell"},
            {"type": "tool.completed", "call_id": "shell-2", "success": True},
            {"type": "text.delta", "text": "No swapping."},
        ]
        for event in events:
            self.bridge.process_event(event, self.bridge.generation)
        messages = self.bridge.messages
        self.assertEqual(
            ["assistant", "tool", "assistant", "tool", "assistant"],
            [m["kind"] for m in messages],
        )
        self.assertEqual(
            ["I’ll check memory.", "Memory looks healthy.", "No swapping."],
            [m["text"] for m in messages if m["kind"] == "assistant"],
        )
        self.assertEqual(len(messages), len({m["id"] for m in messages}))
        restored = Bridge(emit=lambda *_args, **_kwargs: None)
        self.assertEqual(messages, restored.messages)
        restored.shutdown()

    def test_reused_tool_call_id_does_not_update_an_earlier_turn(self) -> None:
        for run in ("first", "second"):
            self.bridge.response_id = run
            self.bridge.process_event(
                {"type": "tool.started", "call_id": "same-id", "name": "shell"},
                self.bridge.generation,
            )
            self.bridge.process_event(
                {"type": "tool.completed", "call_id": "same-id", "success": True},
                self.bridge.generation,
            )
        self.assertEqual(2, len(self.bridge.messages))
        self.assertTrue(all(m["status"] == "done" for m in self.bridge.messages))

    def test_failure_and_clean_eof_are_terminal(self) -> None:
        self.bridge.send("__fail__")
        self.wait_finished()
        self.assertEqual("error", self.bridge.status)
        self.assertEqual("mock failure", self.bridge.error)

        self.bridge.send("__eof__")
        self.wait_finished()
        self.assertEqual("completed", self.bridge.status)
        self.assertEqual("", self.bridge.error)
        self.assertEqual("clean eof", self.bridge.messages[-1]["text"])

    def test_malformed_output_fails_and_reaps_process(self) -> None:
        self.bridge.send("__bad_json__")
        self.wait_finished()
        self.assertEqual("error", self.bridge.status)
        self.assertIn("Invalid term-llm JSONL output", self.bridge.error)
        self.assertIsNone(self.bridge.process)

    def test_stop_cancels_process_group_without_allowing_overlap(self) -> None:
        self.bridge.send("__wait__")
        wait_for(lambda: self.bridge.process is not None and len(self.bridge.messages) >= 2)
        first_process = self.bridge.process
        self.bridge.send("must be ignored")
        self.assertEqual(1, len(self.captured_argv()))
        self.bridge.stop()
        self.wait_finished()
        self.assertEqual("cancelled", self.bridge.status)
        self.assertIsNotNone(first_process)
        self.assertIsNotNone(first_process.poll())
        self.assertEqual(1, len(self.captured_argv()))

    def test_new_cancels_then_clears_cli_state(self) -> None:
        self.bridge.connect()
        self.bridge.send("__new__")
        wait_for(lambda: self.bridge.process is not None and len(self.bridge.messages) >= 2)
        process = self.bridge.process
        self.bridge.new_conversation()
        self.assertEqual("ready", self.bridge.status)
        self.assertFalse(self.bridge.running)
        self.assertEqual("", self.bridge.session_id)
        self.assertEqual("", self.bridge.response_id)
        self.assertEqual([], self.bridge.messages)
        self.assertIsNotNone(process)
        self.assertIsNotNone(process.poll())
        state = json.loads(self.bridge.state_file.read_text())
        self.assertEqual("term-llm-cli", state["backend"])
        self.assertEqual("", state["session_id"])
        self.assertEqual([], state["messages"])
        self.assertTrue(self.bridge.state_file.name.endswith("-cli.json"))

    def test_shutdown_on_bridge_input_eof_reaps_child(self) -> None:
        self.bridge.send("__shutdown__")
        wait_for(lambda: self.bridge.process is not None)
        process = self.bridge.process
        self.bridge.shutdown()
        self.assertTrue(self.bridge.closed)
        self.assertFalse(self.bridge.running)
        self.assertIsNotNone(process)
        self.assertIsNotNone(process.poll())

    def test_interaction_commands_fail_closed_without_fake_protocol(self) -> None:
        self.bridge.command({"action": "approve", "choice": 2})
        self.assertEqual("error", self.bridge.status)
        self.assertIn("not supported", self.bridge.error)
        self.assertIsNone(self.bridge.approval)
        self.assertIsNone(self.bridge.ask_user)
        self.assertEqual([], self.captured_argv())


if __name__ == "__main__":
    unittest.main()
