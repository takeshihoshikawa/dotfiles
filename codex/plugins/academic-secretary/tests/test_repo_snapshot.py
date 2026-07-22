from __future__ import annotations

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "repo_snapshot.py"
SPEC = importlib.util.spec_from_file_location("repo_snapshot", SCRIPT)
assert SPEC and SPEC.loader
repo_snapshot = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(repo_snapshot)


def git(cwd: Path, *args: str) -> None:
    subprocess.run(["git", "-C", str(cwd), *args], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


class RepoSnapshotTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.remote = root / "remote.git"
        self.writer = root / "writer"
        self.reader = root / "reader"
        subprocess.run(["git", "init", "--bare", str(self.remote)], check=True, stdout=subprocess.PIPE)
        subprocess.run(["git", "clone", str(self.remote), str(self.writer)], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        git(self.writer, "config", "user.name", "Test User")
        git(self.writer, "config", "user.email", "test@example.com")
        (self.writer / "note.txt").write_text("one\n")
        git(self.writer, "add", "note.txt")
        git(self.writer, "commit", "-m", "initial")
        git(self.writer, "push", "-u", "origin", "HEAD")
        subprocess.run(["git", "clone", str(self.remote), str(self.reader)], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        git(self.reader, "config", "user.name", "Test User")
        git(self.reader, "config", "user.email", "test@example.com")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_dirty_repo_is_not_pulled(self) -> None:
        (self.writer / "note.txt").write_text("one\ntwo\n")
        git(self.writer, "add", "note.txt")
        git(self.writer, "commit", "-m", "remote update")
        git(self.writer, "push")
        (self.reader / "local.txt").write_text("dirty\n")

        item = repo_snapshot.snapshot_repo(self.reader, fetch=True, pull_safe=True, target_date=None)

        self.assertEqual(item["state"], "dirty")
        self.assertEqual(item["behind"], 1)
        self.assertFalse(item["pulled"])

    def test_clean_behind_repo_is_pulled(self) -> None:
        (self.writer / "note.txt").write_text("one\ntwo\n")
        git(self.writer, "add", "note.txt")
        git(self.writer, "commit", "-m", "remote update")
        git(self.writer, "push")

        item = repo_snapshot.snapshot_repo(self.reader, fetch=True, pull_safe=True, target_date=None)

        self.assertTrue(item["pulled"])
        self.assertEqual(item["state"], "synced")
        self.assertEqual(item["behind"], 0)

    def test_diverged_repo_is_left_untouched(self) -> None:
        (self.writer / "remote.txt").write_text("remote\n")
        git(self.writer, "add", "remote.txt")
        git(self.writer, "commit", "-m", "remote update")
        git(self.writer, "push")
        (self.reader / "local.txt").write_text("local\n")
        git(self.reader, "add", "local.txt")
        git(self.reader, "commit", "-m", "local update")

        item = repo_snapshot.snapshot_repo(self.reader, fetch=True, pull_safe=True, target_date=None)

        self.assertEqual(item["state"], "diverged")
        self.assertEqual((item["ahead"], item["behind"]), (1, 1))
        self.assertFalse(item["pulled"])


if __name__ == "__main__":
    unittest.main()
