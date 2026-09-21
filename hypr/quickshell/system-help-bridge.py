#!/usr/bin/env python3
"""Snapshot bridge from Quickshell to ``term-llm ask --json``."""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import signal
import subprocess
import sys
import threading
import uuid
from typing import Any


AGENT = "system-help"
STATE_VERSION = 1


def state_home() -> pathlib.Path:
    return pathlib.Path(os.environ.get("XDG_STATE_HOME", pathlib.Path.home() / ".local/state"))


def json_dump(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def display_value(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    return json_dump(value)


class Bridge:
    def __init__(self, emit=print, executable: str | None = None):
        self.emit_line = emit
        self.executable = executable or os.environ.get("TERM_LLM_BIN", "term-llm")
        self.lock = threading.RLock()
        self.state_dir = state_home() / "system-help"
        # Deliberately distinct from the retired HTTP bridge's conversation.json.
        self.state_file = self.state_dir / "conversation-cli.json"
        self.session_id = ""
        self.response_id = ""
        self.messages: list[dict[str, Any]] = []
        self.ask_user = None
        self.approval = None
        self.running = False
        self.transitioning = False
        self.connected = False
        self.status = "idle"
        self.error = ""
        self.generation = 0
        self.process: subprocess.Popen[str] | None = None
        self.worker: threading.Thread | None = None
        self.cancelled_generations: set[int] = set()
        self.closed = False
        self.load_local_state()

    def emit(self, payload: dict[str, Any]) -> None:
        try:
            self.emit_line(json_dump(payload), flush=True)
        except (BrokenPipeError, OSError):
            # Quickshell has gone away; main's EOF path will reap the child.
            pass

    def snapshot(self) -> None:
        with self.lock:
            payload = {
                "type": "snapshot",
                "connected": self.connected,
                "status": self.status,
                "error": self.error,
                "running": self.running,
                "session_id": self.session_id,
                "response_id": self.response_id,
                "messages": self.messages,
                "ask_user": self.ask_user,
                "approval": self.approval,
            }
            self.emit(payload)

    @staticmethod
    def _load_messages(value: Any) -> list[dict[str, Any]]:
        if not isinstance(value, list):
            return []
        messages: list[dict[str, Any]] = []
        for raw in value:
            if not isinstance(raw, dict):
                continue
            kind = str(raw.get("kind") or "")
            item_id = str(raw.get("id") or "")
            if kind in {"user", "assistant"} and item_id:
                messages.append(
                    {"id": item_id, "kind": kind, "text": str(raw.get("text") or "")}
                )
            elif kind == "tool" and item_id:
                status = str(raw.get("status") or "error")
                if status == "running":
                    status = "error"
                messages.append(
                    {
                        "id": item_id,
                        "kind": "tool",
                        "call_id": str(raw.get("call_id") or ""),
                        "name": str(raw.get("name") or "tool"),
                        "status": status,
                        "arguments": str(raw.get("arguments") or ""),
                        "result": str(raw.get("result") or ""),
                    }
                )
        return messages

    def load_local_state(self) -> None:
        try:
            saved = json.loads(self.state_file.read_text(encoding="utf-8"))
            if not isinstance(saved, dict) or saved.get("version") != STATE_VERSION:
                return
            self.session_id = str(saved.get("session_id") or "")
            self.messages = self._load_messages(saved.get("messages"))
        except (OSError, ValueError, TypeError):
            pass

    def save_local_state(self) -> None:
        with self.lock:
            payload = {
                "version": STATE_VERSION,
                "backend": "term-llm-cli",
                "session_id": self.session_id,
                "messages": self.messages,
            }
            self.state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
            os.chmod(self.state_dir, 0o700)
            temp = self.state_file.with_suffix(".tmp")
            temp.write_text(json_dump(payload) + "\n", encoding="utf-8")
            os.chmod(temp, 0o600)
            temp.replace(self.state_file)

    def connect(self) -> None:
        # A direct CLI bridge has no server to start or session to hydrate.
        with self.lock:
            if self.closed:
                return
            self.connected = True
            self.status = "ready"
            self.error = ""
        self.snapshot()

    def build_argv(self, text: str, session_id: str) -> list[str]:
        argv = [
            self.executable,
            "ask",
            "--agent",
            AGENT,
            "--json",
            "--approval",
            "auto",
        ]
        if session_id:
            # Cobra gives --resume an optional value: use = to avoid resuming
            # the global latest session and treating the ID as prompt text.
            argv.append("--resume=" + session_id)
        # Everything after this marker is data, even when the prompt starts with '-'.
        argv.extend(["--", text])
        return argv

    def send(self, text: str) -> None:
        text = text.strip()
        with self.lock:
            if not text or self.running or self.transitioning or self.closed:
                return
            self.generation += 1
            generation = self.generation
            session_id = self.session_id
            self.response_id = "cli-run-" + uuid.uuid4().hex
            self.running = True
            self.connected = True
            self.status = "connecting"
            self.error = ""
            self.ask_user = self.approval = None
            self.messages.append(
                {"id": "user-" + uuid.uuid4().hex, "kind": "user", "text": text}
            )
            try:
                self.save_local_state()
            except OSError as error:
                self.running = False
                self.status = "error"
                self.error = f"Could not save System Help conversation: {error}"
                self.snapshot()
                return
        self.snapshot()
        worker = threading.Thread(
            target=self._run,
            args=(text, session_id, generation),
            name=f"system-help-{generation}",
            daemon=True,
        )
        with self.lock:
            if generation != self.generation or self.closed:
                return
            self.worker = worker
        worker.start()

    def _run(self, text: str, resume_session_id: str, generation: int) -> None:
        argv = self.build_argv(text, resume_session_id)
        try:
            with self.lock:
                if (
                    self.closed
                    or generation != self.generation
                    or generation in self.cancelled_generations
                ):
                    self._finish_run(generation, cancelled=True)
                    return
                # Popen while holding the lock closes the new/stop race: once those
                # commands can run, there is either no child or a registered child.
                process = subprocess.Popen(
                    argv,
                    stdin=subprocess.DEVNULL,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    bufsize=1,
                    start_new_session=True,
                    cwd=os.environ.get("SYSTEM_HELP_CWD", str(pathlib.Path.home())),
                )
                self.process = process
        except (OSError, ValueError) as error:
            self._finish_run(generation, failure=f"Could not start term-llm: {error}")
            return

        stderr_chunks: list[str] = []

        def drain_stderr() -> None:
            assert process.stderr is not None
            for chunk in iter(lambda: process.stderr.read(4096), ""):
                stderr_chunks.append(chunk)
                if sum(map(len, stderr_chunks)) > 65536:
                    del stderr_chunks[:-8]

        stderr_thread = threading.Thread(target=drain_stderr, daemon=True)
        stderr_thread.start()
        saw_session = False
        saw_done = False
        event_error = ""
        parse_error = ""
        assert process.stdout is not None
        try:
            for raw_line in process.stdout:
                with self.lock:
                    if generation != self.generation or self.closed:
                        break
                line = raw_line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                except json.JSONDecodeError as error:
                    parse_error = f"Invalid term-llm JSONL output: {error.msg}"
                    self._terminate_process(process)
                    break
                if not isinstance(event, dict):
                    parse_error = "Invalid term-llm JSONL output: expected an object"
                    self._terminate_process(process)
                    break
                event_type = str(event.get("type") or "")
                if event_type == "session.started":
                    saw_session = True
                elif event_type == "done":
                    saw_done = True
                elif event_type == "error":
                    event_error = str(event.get("message") or "term-llm failed")
                fatal = self.process_event(event, generation, resume_session_id)
                if fatal:
                    parse_error = fatal
                    self._terminate_process(process)
                    break
        except OSError as error:
            parse_error = f"Could not read term-llm output: {error}"
            self._terminate_process(process)

        returncode = process.wait()
        stderr_thread.join(timeout=1)
        process.stdout.close()
        if process.stderr is not None:
            process.stderr.close()
        stderr = "".join(stderr_chunks).strip()
        with self.lock:
            cancelled = generation in self.cancelled_generations
        failure = ""
        if not cancelled:
            if parse_error:
                failure = parse_error
            elif event_error:
                failure = event_error
            elif returncode != 0:
                failure = self._process_error(returncode, stderr)
            elif not saw_session:
                failure = "term-llm ended before reporting a session id"
            # A clean EOF is terminal even if an older CLI omitted `done`.
            elif not saw_done:
                saw_done = True
        self._finish_run(generation, cancelled=cancelled, failure=failure)

    @staticmethod
    def _process_error(returncode: int, stderr: str) -> str:
        lines = [line.strip() for line in stderr.splitlines() if line.strip()]
        if lines:
            return lines[-1]
        return f"term-llm exited with status {returncode}"

    def process_event(
        self, event: dict[str, Any], generation: int, resume_session_id: str = ""
    ) -> str:
        event_type = str(event.get("type") or "")
        with self.lock:
            if generation != self.generation or self.closed:
                return ""
            if event_type == "session.started":
                session_id = str(event.get("session_id") or "")
                if not session_id:
                    return "term-llm did not report a session id"
                if event.get("yolo") is True:
                    return "term-llm unexpectedly enabled yolo approval mode"
                if resume_session_id and session_id != resume_session_id:
                    return "term-llm resumed a different session"
                self.session_id = session_id
                self.status = "streaming"
            elif event_type == "text.delta":
                message = self.ensure_assistant()
                message["text"] += str(event.get("text") or "")
            elif event_type == "tool.started":
                tool = self.ensure_tool(event)
                tool.update(
                    {
                        "name": str(event.get("name") or tool["name"]),
                        "status": "running",
                        "arguments": display_value(event.get("args")),
                    }
                )
            elif event_type == "tool.completed":
                tool = self.ensure_tool(event)
                tool["name"] = str(event.get("name") or tool["name"])
                tool["status"] = "done" if event.get("success") is True else "error"
            elif event_type == "guardian.review":
                tool = self.ensure_tool(event, str(event.get("tool") or ""))
                message = str(event.get("message") or "")
                if message:
                    tool["result"] = message
                if str(event.get("outcome") or "").lower() == "denied":
                    tool["status"] = "error"
            elif event_type == "error":
                self.error = str(event.get("message") or "term-llm failed")
                self.status = "error"
            try:
                self.save_local_state()
            except OSError as error:
                return f"Could not save System Help conversation: {error}"
        self.snapshot()
        return ""

    def ensure_assistant(self) -> dict[str, Any]:
        # Only coalesce adjacent text from this run. A tool creates a boundary:
        # later text must not be appended above it in the transcript.
        prefix = "assistant-" + self.response_id + "-"
        if self.messages:
            last = self.messages[-1]
            if last.get("kind") == "assistant" and last.get("id", "").startswith(prefix):
                return last
        message = {"id": prefix + uuid.uuid4().hex, "kind": "assistant", "text": ""}
        self.messages.append(message)
        return message

    def ensure_tool(self, event: dict[str, Any], name: str = "") -> dict[str, Any]:
        call_id = str(event.get("call_id") or "")
        prefix = "tool-" + self.response_id + "-"
        for message in reversed(self.messages):
            if (message.get("kind") == "tool"
                    and message.get("id", "").startswith(prefix)
                    and message.get("call_id") == call_id):
                return message
        stable_id = call_id or uuid.uuid4().hex
        tool = {
            "id": "tool-" + self.response_id + "-" + stable_id,
            "kind": "tool",
            "call_id": call_id,
            "name": name or str(event.get("name") or "tool"),
            "status": "running",
            "arguments": display_value(event.get("args")),
            "result": "",
        }
        self.messages.append(tool)
        return tool

    def _finish_run(
        self, generation: int, cancelled: bool = False, failure: str = ""
    ) -> None:
        with self.lock:
            if generation != self.generation:
                self.cancelled_generations.discard(generation)
                return
            self.process = None
            self.worker = None
            self.running = False
            self.ask_user = self.approval = None
            if cancelled:
                self.status = "cancelled"
                self.error = ""
            elif failure:
                self.status = "error"
                self.error = failure
            else:
                self.status = "completed"
                self.error = ""
            self.cancelled_generations.discard(generation)
            try:
                self.save_local_state()
            except OSError as error:
                self.status = "error"
                self.error = f"Could not save System Help conversation: {error}"
        self.snapshot()

    @staticmethod
    def _signal_process(process: subprocess.Popen[str], sig: signal.Signals) -> None:
        if process.poll() is not None:
            return
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            pass
        except OSError:
            try:
                process.send_signal(sig)
            except OSError:
                pass

    @classmethod
    def _terminate_process(cls, process: subprocess.Popen[str]) -> None:
        if process.poll() is not None:
            return
        cls._signal_process(process, signal.SIGTERM)
        try:
            process.wait(timeout=1.5)
            return
        except subprocess.TimeoutExpired:
            cls._signal_process(process, signal.SIGKILL)
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            pass

    def stop(self) -> None:
        with self.lock:
            if not self.running or self.closed:
                return
            generation = self.generation
            self.cancelled_generations.add(generation)
            process = self.process
            self.status = "stopping"
        self.snapshot()
        if process is None:
            self._finish_run(generation, cancelled=True)
        else:
            threading.Thread(
                target=self._terminate_process,
                args=(process,),
                name=f"system-help-stop-{generation}",
                daemon=True,
            ).start()

    def new_conversation(self) -> None:
        with self.lock:
            old_generation = self.generation
            process = self.process
            worker = self.worker
            if self.running:
                self.cancelled_generations.add(old_generation)
            self.generation += 1
            self.process = None
            self.worker = None
            self.transitioning = True
            self.session_id = ""
            self.response_id = ""
            self.messages = []
            self.ask_user = self.approval = None
            self.running = False
            self.status = "ready" if self.connected else "idle"
            self.error = ""
            try:
                self.save_local_state()
            except OSError as error:
                self.status = "error"
                self.error = f"Could not clear System Help conversation: {error}"
        # Do not allow a replacement turn until the old process group is gone.
        if process is not None:
            self._terminate_process(process)
        if worker is not None and worker is not threading.current_thread():
            worker.join(timeout=2)
        with self.lock:
            self.transitioning = False
            self.cancelled_generations.discard(old_generation)
        self.snapshot()

    def unsupported_interaction(self) -> None:
        with self.lock:
            self.error = (
                "Interactive prompts are not supported by term-llm ask --json; "
                "the terminal-only prompt fails closed."
            )
            if not self.running:
                self.status = "error"
        self.snapshot()

    def command(self, value: dict[str, Any]) -> None:
        action = str(value.get("action") or "")
        if action == "connect":
            self.connect()
        elif action == "send":
            self.send(str(value.get("text") or ""))
        elif action == "stop":
            self.stop()
        elif action == "new":
            self.new_conversation()
        elif action in {"ask", "approve"}:
            self.unsupported_interaction()
        elif action == "snapshot":
            self.snapshot()

    def command_error(self, error: Exception) -> None:
        with self.lock:
            self.error = str(error) or error.__class__.__name__
            if not self.running:
                self.status = "error"
        self.snapshot()

    def shutdown(self) -> None:
        with self.lock:
            if self.closed:
                return
            self.closed = True
            generation = self.generation
            process = self.process
            worker = self.worker
            if self.running:
                self.cancelled_generations.add(generation)
            self.generation += 1
            self.process = None
            self.worker = None
            self.running = False
            if self.status in {"connecting", "streaming", "stopping"}:
                self.status = "cancelled"
        if process is not None:
            self._terminate_process(process)
        if worker is not None and worker is not threading.current_thread():
            worker.join(timeout=2)
        try:
            self.save_local_state()
        except OSError:
            pass


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.parse_args()
    def interrupted(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, interrupted)
    bridge = Bridge()
    bridge.snapshot()
    try:
        for line in sys.stdin:
            try:
                value = json.loads(line)
                if isinstance(value, dict):
                    bridge.command(value)
            except Exception as error:
                bridge.command_error(error)
    except KeyboardInterrupt:
        pass
    finally:
        bridge.shutdown()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
