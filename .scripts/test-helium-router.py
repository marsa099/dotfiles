#!/usr/bin/env python3
"""Isolated router tests: no browser, desktop IPC, or network access."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROUTER = Path(__file__).with_name("helium-router")


class RouterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        bin_dir = self.home / "bin"
        bin_dir.mkdir()
        helper = self.home / "repos/qs-picker/scripts/bookmarks"
        helper.parent.mkdir(parents=True)
        helper.write_text('#!/bin/sh\nprintf "%s\\n" "$ROUTE"\nexit "${ROUTE_EXIT:-0}"\n')
        helper.chmod(0o755)
        for tool in ("qs", "helium", "teams-for-linux"):
            script = bin_dir / tool
            script.write_text(
                '#!/usr/bin/env python3\nimport json, os, sys\n'
                'with open(os.environ["CALLS"], "a") as f:\n'
                ' f.write(json.dumps([os.path.basename(sys.argv[0])] + sys.argv[1:]) + "\\n")\n')
            script.chmod(0o755)
        # Avoid compositor focus polling; keep the real setsid detachment.
        niri = bin_dir / "niri"
        niri.write_text('#!/bin/sh\nprintf \'[{"id":1,"app_id":"teams"}]\\n\'\n')
        niri.chmod(0o755)
        self.calls = self.home / "calls"
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=str(bin_dir) + ":" + os.environ["PATH"],
                        CALLS=str(self.calls), ROUTE="unmatched")

    def run_router(self, *urls):
        return subprocess.run(["bash", str(ROUTER), *urls], env=self.env,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                              timeout=2)

    def wait_calls(self, count):
        for _ in range(100):
            rows = [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []
            if len(rows) >= count:
                return rows
            time.sleep(.02)
        self.fail(f"expected {count} calls, got {rows}")

    def test_unmatched_preserves_url_and_only_calls_picker(self):
        url = 'https://claude.ai/login?returnTo=%2Foauth%3Fredirect%3Dhttp%253A%252F%252Flocalhost&state=a;$(false)'
        self.assertEqual(self.run_router(url).returncode, 0)
        self.assertEqual(self.wait_calls(1), [["qs", "-p", str(self.home / "repos/qs-picker/shell.qml"),
                         "ipc", "call", "url-profile-picker", "openUrl", url]])

    def test_matched_private_does_not_prompt(self):
        self.env["ROUTE"] = "Private 9226"
        self.run_router("https://ui.com/")
        call, = self.wait_calls(1)
        self.assertEqual(call[0], "helium")
        self.assertIn("--profile-directory=Private", call)
        self.assertEqual(call[-1], "https://ui.com/")

    def test_each_matched_profile(self):
        for profile, port in (("SIS", 9222), ("SISAdmin", 9223), ("Koderiet", 9224), ("Regent", 9225)):
            self.env["ROUTE"] = f"{profile} {port}"
            self.run_router("https://example.org/")
            call = self.wait_calls(1)[0]
            self.assertIn(f"--profile-directory={profile}", call)
            self.assertIn(f"--remote-debugging-port={port}", call)
            self.calls.unlink()

    def test_no_args_opens_private(self):
        self.run_router()
        call, = self.wait_calls(1)
        self.assertEqual(call[-2:], ["--profile-directory=Private", "--remote-debugging-port=9226"])

    def test_multiple_unmatched_links_are_not_lost(self):
        urls = ["https://example.org/one", "https://example.org/two"]
        self.run_router(*urls)
        calls = self.wait_calls(2)
        self.assertEqual(sorted(c[-1] for c in calls), urls)
        self.assertTrue(all(c[0] == "qs" for c in calls))

    def test_classification_errors_never_launch(self):
        for route, status in (("", "1"), ("bogus", "0")):
            self.env.update(ROUTE=route, ROUTE_EXIT=status)
            self.assertNotEqual(self.run_router("https://example.org/").returncode, 0)
            self.assertFalse(self.calls.exists())

    def test_sis_teams_handoff_preserved(self):
        url = "https://teams.microsoft.com/l/chat?tenantId=59176df8-78c5-4eb6-aa88-4f0778ef5cb0"
        self.run_router(url)
        self.assertEqual(self.wait_calls(1), [["teams-for-linux", url]])


if __name__ == "__main__":
    unittest.main()
