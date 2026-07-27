---
name: sync-repos
description: Inspect and safely synchronize git repositories used across multiple machines, and propose archiving repositories unused for at least seven days. Use when the user asks to sync repos, diagnose divergence, pull safe updates, clean up stale checkouts, or prepare work for another computer.
---

# Sync repositories

## Codex execution profile

Use `gpt-5.6-sol` with `high` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_sync_repos` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

---

Read [the shared contract](../../references/secretary-contract.md).

Resolve `../../scripts/repo_snapshot.py` relative to this `SKILL.md` and invoke it with `--fetch --pull-safe --format json`.

The script may fetch and pull only clean, behind-only repositories. It never commits, pushes, resets, or resolves divergence.

Summarize repositories as synced, pulled, dirty, ahead, diverged, no-upstream, or fetch-failed. Keep synced repositories aggregated.
Classify a repository with uncommitted changes as dirty regardless of its ahead/behind position. Do not apply automatic actions or archival checks to no-upstream or fetch-failed repositories.

For dirty repositories:

1. Inspect the diff and check for WIP, generated files, secrets, or unrelated changes.
2. Commit and push only when the changes form one coherent, complete unit with no WIP markers, secrets, or unrelated edits.
3. If the only change in `claude/.claude/settings.json` is the `model` key, show the old and new values and ask whether the change was intentional. Do not commit it automatically. If it was accidental and no other changes exist in that file, restore the file only after confirmation. If other changes coexist, edit only the `model` value; never discard the whole file.
4. Treat other changes in `claude/.claude/settings.json` and all changes in `codex/.codex/config.toml` as intentional user configuration unless proven otherwise; never discard them automatically.

Push an ahead-only repository automatically. Never touch a diverged repository.

Use this compact, emoji-free output:

```text
synced:    12件
pulled:    tree-species-classification (+2)
committed: cultural-heritage-digital-twin — "Fix author initial K.→T." → pushed
dirty:     some-repo (src/model.py 他2件) — WIPコメントあり、手動で確認
diverged:  harvest-accessibility (ahead 13, behind 13) — 内容確認してから対処
```

## Stale repository review

After synchronization, review only synced repositories under `~/work/projects`; exclude `~/dotfiles`, dirty, diverged, no-upstream, and fetch-failed repositories.

Treat a repository as used within the last seven days when either source shows a recent session:

- Claude Code: a file under `~/.claude/projects/-Users-takeshi-work-projects-{name}/` has an mtime within seven days.
- Codex: a JSONL file under `~/.codex/sessions/` has an mtime within seven days and its `session_meta.payload.cwd` equals the repository path.

Do not use git log or reflog as activity evidence because this workflow's own pull changes them. If neither session source has a matching directory or record, label the result `セッションログ無し`. This intentionally does not detect direct edits made outside Claude Code and Codex.

Separate stale repositories by whether a `data/` directory exists:

- Without `data/`: before proposing deletion, confirm every local branch is fully pushed, the stash is empty, and ignored files contain nothing valuable such as `.env`, local-only scripts, or personal notes. Regenerable environments and dependencies do not block archival.
- With `data/`: report only. Do not run synchronization scripts or delete anything; project-specific knowledge is required to verify NAS or other authoritative storage.

Report the result at the end:

```text
退避候補（7日以上未使用・data/なし・チェック通過。このセッションで削除可）:
  - some-old-repo（セッションログ無し）

プロジェクト側で対応が必要（7日以上未使用・data/あり）:
  - tree-species-classification
    → そのプロジェクトのセッションで NAS 同期を確認のうえ削除を検討してください

要確認（7日以上未使用だがgit側の担保が未達）:
  - third-repo（feature/x が未push 3コミット）
```

Ask the user to select any repository to remove. After selection, rerun all pre-deletion checks and verify that the state has not changed. Delete only the exact selected path, then explain that repositories without local-only data can be restored by cloning.

Never force-push, reset, or choose one side of a binary conflict automatically. Never delete a repository until the user explicitly selects it after seeing the proposal.
