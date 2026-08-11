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

Normally invoke `~/work/projects/admin/scripts/repo_snapshot.py --fetch --pull-safe --format json`. If the user explicitly requests a preview or prohibits updates, invoke it with `--format json` instead and report that remote state was not refreshed.

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

After synchronization, review every discovered repository under `~/work/projects`; exclude only `~/dotfiles`. Include dirty, diverged, no-upstream, and fetch-failed repositories in the inactivity review, but do not synchronize, evacuate, or delete them automatically.

Before proposing any repository for evacuation, archive, or deletion, run `academic_ops.py audit --project {repo-name} --format json` when a matching Obsidian project note exists. A project with `status: active` or `status: waiting`, an integrity violation, or any unfinished task is not an archive/delete candidate. Report the blocking state and task IDs instead.

Treat a repository as used within the last seven days when either source shows a recent session:

- Claude Code: a file under `~/.claude/projects/-Users-takeshi-work-projects-{name}/` has an mtime within seven days.
- Codex: a JSONL file under `~/.codex/sessions/` has an mtime within seven days and its `session_meta.payload.cwd` equals the repository path.

Do not use git log or reflog as activity evidence because this workflow's own pull changes them. If neither session source has a matching directory or record, label the result `セッションログ無し`. This intentionally does not detect direct edits made outside Claude Code and Codex.

Treat every repository without a matching session in the last seven days as a deletion candidate, regardless of git state or whether `data/` exists. The seven-day inactivity rule alone determines candidacy. Git state determines whether deletion is currently safe, and local-only data determines what must be evacuated before deletion.

For every deletion candidate:

1. Record the snapshot classification. A dirty, diverged, no-upstream, or fetch-failed repository remains a deletion candidate but is not `削除可`.
2. Confirm every local branch is fully pushed and the stash is empty.
3. Inspect untracked and ignored files, including `data/`, for local-only data, `.env`, scripts, notes, credentials, or other valuable content. Regenerable environments, dependencies, and caches do not require evacuation.
4. If git safety checks pass and valuable local-only content does not exist, classify the repository as `削除可`.
5. If valuable local-only content exists, classify the repository as `退避待ち` and determine its authoritative storage from the repository's `CLAUDE.md`, `AGENTS.md`, README, path configuration, or the global data-management policy. Never assume S3 is authoritative when the project designates NAS, an external HDD, or another location.
6. If the authoritative destination or project-specific synchronization procedure is unclear, keep the repository as a deletion candidate but mark it `退避先要確認`. Ask the user rather than inventing a destination or deleting the repository.
7. If git safety checks fail, keep the repository as a deletion candidate but mark it `git確認待ち` and report the exact blocker. Resolve it only through the normal safe synchronization workflow; never discard or overwrite work to make a repository deletable.

After the user selects a candidate with local-only content, evacuate it before deleting the repository:

1. Recheck that the repository and destination state have not changed.
2. Use the documented project-specific synchronization procedure when one exists. Otherwise propose the exact source, destination, and copy method and obtain confirmation before writing to external storage.
3. Verify the evacuation using file counts and total bytes plus a content check such as checksums, a manifest comparison, or an equivalent tool-specific verification. A successful copy command alone is insufficient.
4. Preserve the verified destination and evidence in the final report. Delete only after evacuation and verification succeed.

Report the result at the end:

```text
削除候補（7日以上未使用）:
  - some-old-repo（セッションログ無し）
    状態: 削除可（ローカル専用データなし）

  - tree-species-classification
    状態: 退避待ち
    退避元: data/
    正本: /Volumes/research/tree-species-classification
    → 退避と検証後に削除可

  - another-project
    状態: 退避先要確認
    退避元: data/raw/（24 GB）
    → 正本の保存先を確認してください

候補外（7日以内に使用）:
  - active-project（最終セッション 2026-07-30）

git側の担保が未達:
  - third-repo
    状態: git確認待ち
    → feature/x が未push 3コミット
```

Ask the user to select any repository to remove. After selection, rerun all pre-deletion checks and verify that the state has not changed. Delete only the exact selected path, then explain that repositories without local-only data can be restored by cloning.

Never force-push, reset, or choose one side of a binary conflict automatically. Never delete a repository until the user explicitly selects it after seeing the proposal.
