#!/usr/bin/env python3

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "update"


def command(*args, cwd=None, env=None):
    return subprocess.run(
        args,
        cwd=cwd,
        env=env,
        text=True,
        capture_output=True,
        check=True,
    ).stdout.strip()


class LazyQuarantineTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.origin = self.root / "origin.git"
        self.author = self.root / "author"
        self.plugins = self.root / "plugins"
        self.plugin = self.plugins / "example.nvim"
        self.config = self.root / "config"
        self.state = self.root / "state.json"
        self.specs = self.root / "specs.json"
        self.config.mkdir()
        self.plugins.mkdir()

        command("git", "init", "--bare", str(self.origin))
        command("git", "clone", str(self.origin), str(self.author))
        command("git", "config", "user.name", "Test Author", cwd=self.author)
        command("git", "config", "user.email", "test@example.com", cwd=self.author)
        command("git", "checkout", "-b", "main", cwd=self.author)
        self.first = self.commit("plugin.lua", "return 'one'\n", "first")
        command("git", "push", "-u", "origin", "main", cwd=self.author)
        command("git", "clone", "--branch", "main", str(self.origin), str(self.plugin))
        self.write_lock(self.first)
        self.specs.write_text(
            json.dumps(
                {
                    "example.nvim": {
                        "url": str(self.origin),
                        "branch": "main",
                    }
                }
            )
        )

    def tearDown(self):
        self.temporary.cleanup()

    def commit(self, filename, contents, message):
        (self.author / filename).write_text(contents)
        command("git", "add", filename, cwd=self.author)
        command("git", "commit", "-m", message, cwd=self.author)
        return command("git", "rev-parse", "HEAD", cwd=self.author)

    def push(self):
        command("git", "push", "origin", "main", cwd=self.author)

    def write_lock(self, sha):
        (self.config / "lazy-lock.json").write_text(
            json.dumps(
                {"example.nvim": {"branch": "main", "commit": sha}}, indent=2
            )
            + "\n"
        )

    def updater_args(self, operation, *extra):
        return (
            str(SCRIPT),
            operation,
            "--config-dir",
            str(self.config),
            "--plugin-root",
            str(self.plugins),
            "--state-file",
            str(self.state),
            "--spec-file",
            str(self.specs),
            *extra,
        )

    def updater(self, operation, *extra, env=None):
        return command(*self.updater_args(operation, *extra), env=env)

    def updater_result(self, operation, *extra, env=None):
        return subprocess.run(
            self.updater_args(operation, *extra),
            env=env,
            text=True,
            capture_output=True,
        )

    def test_promotes_only_after_first_seen_quarantine(self):
        second = self.commit("plugin.lua", "return 'two'\n", "second")
        self.push()
        observe_output = self.updater("observe", "--jobs", "2")
        self.assertIn("fetching 1 plugin repository with 1 worker", observe_output)
        self.assertIn("[1/1] observe example.nvim", observe_output)
        self.assertIn("fetch checkpoint complete: 1 plugins", observe_output)

        output = self.updater("promote", "--no-sync")
        self.assertIn("no quarantined updates", output)
        self.assertEqual(self.first, json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]["commit"])

        state = json.loads(self.state.read_text())
        state["plugins"]["example.nvim"][second] = 0
        self.state.write_text(json.dumps(state))
        output = self.updater("promote", "--no-sync")
        self.assertIn("promote example.nvim", output)
        self.assertEqual(second, json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]["commit"])
        self.assertEqual(
            "{\n"
            f'  "example.nvim": {{ "branch": "main", "commit": "{second}" }}\n'
            "}\n",
            (self.config / "lazy-lock.json").read_text(),
        )

    def test_urgent_reviews_only_the_quarantine_bypass(self):
        second = self.commit("plugin.lua", "return 'two'\n", "mature second")
        self.push()
        self.updater("observe")
        state = json.loads(self.state.read_text())
        state["plugins"]["example.nvim"][second] = 0
        self.state.write_text(json.dumps(state))

        third = self.commit("plugin.lua", "return 'three'\n", "young third")
        self.push()
        capture = self.root / "triage.txt"
        fake = self.root / "term-llm"
        fake.write_text(
            "#!/usr/bin/env python3\n"
            "import os, sys\n"
            "open(os.environ['TRIAGE_CAPTURE'], 'w').write(sys.stdin.read())\n"
            "print('{\"verdict\":\"PASS\",\"reason\":\"coherent test change\"}')\n"
        )
        fake.chmod(0o755)
        env = os.environ.copy()
        env["TRIAGE_CAPTURE"] = str(capture)

        output = self.updater(
            "update", "--urgent", "--no-sync", "--term-llm", str(fake), env=env
        )
        report = capture.read_text()
        self.assertIn("young third", report)
        self.assertNotIn("mature second", report)
        self.assertIn("urgent triage passed", output)
        self.assertEqual(third, json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]["commit"])

    def test_conservative_reviews_every_pending_change(self):
        self.commit("plugin.lua", "return 'two'\n", "older second")
        third = self.commit("other.lua", "return 'three'\n", "young third")
        self.push()
        capture = self.root / "triage.txt"
        fake = self.root / "term-llm"
        fake.write_text(
            "#!/usr/bin/env python3\n"
            "import os, sys\n"
            "open(os.environ['TRIAGE_CAPTURE'], 'w').write(sys.stdin.read())\n"
            "print('{\"verdict\":\"PASS\",\"reason\":\"coherent test changes\"}')\n"
        )
        fake.chmod(0o755)
        env = os.environ.copy()
        env["TRIAGE_CAPTURE"] = str(capture)

        output = self.updater(
            "update",
            "--conservative",
            "--no-sync",
            "--term-llm",
            str(fake),
            env=env,
        )
        report = capture.read_text()
        self.assertIn("older second", report)
        self.assertIn("young third", report)
        self.assertIn("conservative triage passed", output)
        self.assertEqual(third, json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]["commit"])
    def test_unreachable_observation_loses_its_age(self):
        second = self.commit("plugin.lua", "return 'two'\n", "second")
        self.push()
        self.updater("observe")
        state = json.loads(self.state.read_text())
        state["plugins"]["example.nvim"][second] = 0
        self.state.write_text(json.dumps(state))

        command("git", "push", "--force", "origin", f"{self.first}:main", cwd=self.author)
        self.updater("observe")
        self.assertNotIn(
            second,
            json.loads(self.state.read_text())["plugins"]["example.nvim"],
        )

        command("git", "push", "--force", "origin", f"{second}:main", cwd=self.author)
        self.updater("observe")
        output = self.updater("promote", "--no-sync")
        self.assertIn("no quarantined updates", output)
        self.assertEqual(
            self.first,
            json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]["commit"],
        )

    def test_new_plugin_is_cloned_without_checkout_then_quarantined(self):
        (self.config / "lazy-lock.json").write_text("{}\n")
        shutil.rmtree(self.plugin)

        self.updater("observe")
        self.assertTrue((self.plugin / ".git").is_dir())
        self.assertFalse((self.plugin / "plugin.lua").exists())
        self.assertEqual({}, json.loads((self.config / "lazy-lock.json").read_text()))

        state = json.loads(self.state.read_text())
        state["plugins"]["example.nvim"][self.first] = 0
        self.state.write_text(json.dumps(state))
        output = self.updater("promote", "--no-sync")
        self.assertIn("pin new plugin example.nvim", output)
        pin = json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]
        self.assertEqual({"branch": "main", "commit": self.first}, pin)

    def test_conservative_reviews_entire_new_plugin(self):
        (self.config / "lazy-lock.json").write_text("{}\n")
        shutil.rmtree(self.plugin)
        capture = self.root / "triage.txt"
        fake = self.root / "term-llm"
        fake.write_text(
            "#!/usr/bin/env python3\n"
            "import os, sys\n"
            "open(os.environ['TRIAGE_CAPTURE'], 'w').write(sys.stdin.read())\n"
            "print('{\"verdict\":\"PASS\",\"reason\":\"reviewed full plugin\"}')\n"
        )
        fake.chmod(0o755)
        env = os.environ.copy()
        env["TRIAGE_CAPTURE"] = str(capture)

        self.updater(
            "update",
            "--conservative",
            "--no-sync",
            "--term-llm",
            str(fake),
            env=env,
        )
        report = capture.read_text()
        self.assertIn("BASE: (new plugin)", report)
        self.assertIn("return 'one'", report)
        pin = json.loads((self.config / "lazy-lock.json").read_text())["example.nvim"]
        self.assertEqual(self.first, pin["commit"])

    def test_ai_triage_failures_leave_lockfile_unchanged(self):
        self.commit("plugin.lua", "return 'two'\n", "second")
        self.push()
        fake = self.root / "term-llm"
        before = (self.config / "lazy-lock.json").read_text()
        cases = (
            ("print('{\"verdict\":\"FAIL\",\"reason\":\"suspicious\"}')", 0),
            ("print('not json')", 0),
            ("print('provider failed')", 3),
        )
        for body, exit_code in cases:
            with self.subTest(body=body):
                fake.write_text(
                    "#!/usr/bin/env python3\n"
                    + body
                    + "\n"
                    + f"raise SystemExit({exit_code})\n"
                )
                fake.chmod(0o755)
                result = self.updater_result(
                    "update", "--conservative", "--no-sync", "--term-llm", str(fake)
                )
                self.assertNotEqual(0, result.returncode)
                self.assertEqual(before, (self.config / "lazy-lock.json").read_text())

        missing = self.updater_result(
            "update",
            "--conservative",
            "--no-sync",
            "--term-llm",
            str(self.root / "missing-term-llm"),
        )
        self.assertNotEqual(0, missing.returncode)
        self.assertEqual(before, (self.config / "lazy-lock.json").read_text())

    def test_non_fast_forward_review_fails_closed(self):
        command("git", "checkout", "--orphan", "rewritten", cwd=self.author)
        command("git", "rm", "-rf", ".", cwd=self.author)
        rewritten = self.commit("plugin.lua", "return 'rewritten'\n", "rewritten history")
        command("git", "push", "--force", "origin", f"{rewritten}:main", cwd=self.author)
        before = (self.config / "lazy-lock.json").read_text()
        fake = self.root / "term-llm"
        fake.write_text(
            "#!/usr/bin/env python3\n"
            "print('{\"verdict\":\"PASS\",\"reason\":\"test\"}')\n"
        )
        fake.chmod(0o755)

        result = self.updater_result(
            "update", "--conservative", "--no-sync", "--term-llm", str(fake)
        )
        self.assertNotEqual(0, result.returncode)
        self.assertIn("not a fast-forward", result.stderr)
        self.assertEqual(before, (self.config / "lazy-lock.json").read_text())

    def test_remote_mismatch_fails_closed(self):
        command(
            "git",
            "remote",
            "set-url",
            "origin",
            str(self.root / "unexpected.git"),
            cwd=self.plugin,
        )
        result = self.updater_result("observe")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("origin is", result.stderr)


if __name__ == "__main__":
    unittest.main()
