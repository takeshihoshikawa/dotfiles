#!/usr/bin/env python3
"""Collect deterministic git repository state for secretary workflows."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


def run_git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def discover_repositories(projects_root: Path, dotfiles: Path | None) -> list[Path]:
    repos: set[Path] = set()
    if projects_root.is_dir():
        for child in projects_root.iterdir():
            if child.is_dir() and (child / ".git").exists():
                repos.add(child.resolve())
    if dotfiles and (dotfiles / ".git").exists():
        repos.add(dotfiles.resolve())
    return sorted(repos, key=lambda path: path.name.casefold())


def git_text(repo: Path, *args: str) -> str | None:
    result = run_git(repo, *args)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def ahead_behind(repo: Path) -> tuple[str | None, int, int]:
    upstream = git_text(repo, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
    if not upstream:
        return None, 0, 0
    counts = git_text(repo, "rev-list", "--left-right", "--count", "HEAD...@{u}")
    if not counts:
        return upstream, 0, 0
    ahead_text, behind_text = counts.split()
    return upstream, int(ahead_text), int(behind_text)


def classify(dirty: bool, upstream: str | None, ahead: int, behind: int) -> str:
    if ahead and behind:
        return "diverged"
    if dirty:
        return "dirty"
    if upstream is None:
        return "no-upstream"
    if behind:
        return "pullable"
    if ahead:
        return "ahead"
    return "synced"


def commits_on(repo: Path, target_date: str) -> list[dict[str, str]]:
    result = run_git(
        repo,
        "log",
        f"--since={target_date} 00:00:00 +0900",
        f"--until={target_date} 23:59:59 +0900",
        "--format=%H%x1f%aI%x1f%s",
    )
    if result.returncode != 0:
        return []
    commits: list[dict[str, str]] = []
    for line in result.stdout.splitlines():
        parts = line.split("\x1f", 2)
        if len(parts) == 3:
            commits.append({"hash": parts[0], "time": parts[1], "subject": parts[2]})
    return commits


def snapshot_repo(
    repo: Path,
    *,
    fetch: bool,
    pull_safe: bool,
    target_date: str | None,
) -> dict[str, Any]:
    fetch_error: str | None = None
    pulled = False

    if fetch or pull_safe:
        result = run_git(repo, "fetch", "--prune")
        if result.returncode != 0:
            fetch_error = result.stderr.strip() or "git fetch failed"

    branch = git_text(repo, "branch", "--show-current") or "(detached)"
    dirty_lines = (git_text(repo, "status", "--porcelain") or "").splitlines()
    upstream, ahead, behind = ahead_behind(repo)

    if pull_safe and not fetch_error and not dirty_lines and upstream and ahead == 0 and behind > 0:
        result = run_git(repo, "pull", "--rebase", "--quiet")
        if result.returncode == 0:
            pulled = True
            upstream, ahead, behind = ahead_behind(repo)
        else:
            fetch_error = result.stderr.strip() or "git pull --rebase failed"

    state = classify(bool(dirty_lines), upstream, ahead, behind)
    item: dict[str, Any] = {
        "name": repo.name,
        "path": str(repo),
        "branch": branch,
        "upstream": upstream,
        "state": state,
        "dirty": bool(dirty_lines),
        "changes": dirty_lines,
        "ahead": ahead,
        "behind": behind,
        "pulled": pulled,
        "fetch_error": fetch_error,
    }
    if target_date:
        item["commits"] = commits_on(repo, target_date)
    return item


def render_summary(items: list[dict[str, Any]]) -> str:
    lines: list[str] = []
    synced = sum(1 for item in items if item["state"] == "synced" and not item["pulled"])
    if synced:
        lines.append(f"✅ {synced}件 synced")
    for item in items:
        if item["pulled"]:
            lines.append(f"⬇️ pulled: {item['name']}")
        elif item["fetch_error"]:
            lines.append(f"⚠️ fetch失敗: {item['name']} — {item['fetch_error']}")
        elif item["state"] != "synced":
            lines.append(
                f"⚠️ {item['state']}: {item['name']} "
                f"(ahead {item['ahead']}, behind {item['behind']})"
            )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--projects-root", type=Path, default=Path.home() / "work/projects")
    parser.add_argument("--dotfiles", type=Path, default=Path.home() / "dotfiles")
    parser.add_argument("--no-dotfiles", action="store_true")
    parser.add_argument("--repo", action="append", type=Path, help="Inspect only this repo; repeatable")
    parser.add_argument("--fetch", action="store_true")
    parser.add_argument("--pull-safe", action="store_true", help="Pull only clean, behind-only repos")
    parser.add_argument("--date", help="Also collect commits on YYYY-MM-DD in Asia/Tokyo")
    parser.add_argument("--format", choices=("json", "summary"), default="json")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.repo:
        repos = sorted({path.expanduser().resolve() for path in args.repo})
    else:
        dotfiles = None if args.no_dotfiles else args.dotfiles.expanduser()
        repos = discover_repositories(args.projects_root.expanduser(), dotfiles)

    missing = [str(repo) for repo in repos if not (repo / ".git").exists()]
    if missing:
        print(json.dumps({"error": "not a git repository", "paths": missing}, ensure_ascii=False))
        return 2

    items = [
        snapshot_repo(
            repo,
            fetch=args.fetch,
            pull_safe=args.pull_safe,
            target_date=args.date,
        )
        for repo in repos
    ]
    if args.format == "summary":
        print(render_summary(items))
    else:
        print(json.dumps(items, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
