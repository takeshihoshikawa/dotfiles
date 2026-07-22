---
name: sync-repos
description: Inspect and safely synchronize git repositories used across multiple machines. Use when the user asks to sync repos, diagnose divergence, pull safe updates, or prepare work for another computer.
---

# Sync repositories

Read [the shared contract](../../references/secretary-contract.md).

Resolve `../../scripts/repo_snapshot.py` relative to this `SKILL.md` and invoke it with `--fetch --pull-safe --format json`.

The script may fetch and pull only clean, behind-only repositories. It never commits, pushes, resets, or resolves divergence.

Summarize repositories as synced, pulled, dirty, ahead, diverged, no-upstream, or fetch-failed. Keep synced repositories aggregated.

For dirty repositories:

1. Inspect the diff and check for WIP, generated files, secrets, or unrelated changes.
2. Do not commit or push unless the user explicitly requested publication or approves the exact proposed scope after seeing it.
3. Treat `claude/.claude/settings.json` and `codex/.codex/config.toml` as intentional user configuration unless proven otherwise; never discard them automatically.

Never force-push, reset, or choose one side of a binary conflict automatically.
