---
name: close-project-session
description: Close a git-backed academic project work session by reconciling completed and next Obsidian tasks, project status, generated CLAUDE status, project-note projection, audit, commit, and push. Use when the user says today's project work is done, "今日はここまで", or asks to update the current project state.
---

# Close project session

Read [the shared contract](../../references/secretary-contract.md) completely before acting.

## Collect and propose

1. Identify the repository and run the repository-divergence checks from global `AGENTS.md`.
2. Read the conversation, `git diff`, `project-status.yaml`, its generated `CLAUDE.md` block, and every official Obsidian task for that project.
3. Check the vocabulary conventions once, here, for the documents written this session:
   `python3 ~/work/projects/admin/scripts/vocab_check.py --repo /absolute/repository/path --all`.
   `--all` distinguishes the three states (`OK`, `未参加（.claude/vocab.toml が無い）`, `禁止語 N 件` with a list);
   a non-participating repository is out of scope unless the user asks to opt it in with a `baseline` in `.claude/vocab.toml`.
   Never mass-replace the words that split by meaning (帯・掃引・利得・製品) — read each sentence and see the 備考 column of the table;
   in `.py` files edit comments and docstrings only, because a full-text replacement also rewrites JSON keys and DataFrame column names.
   Any fix lands as its own commit before the next step, like the ledger updates.
4. If there are uncommitted changes outside `project-status.yaml` and `CLAUDE.md`, stop without writing and ask the user to preserve the ordinary work first.
5. Propose one transaction: new phase, task IDs to complete, one next task ID or project status change, concern, and update date. Never infer semantic task completion from a status sentence alone.
6. Show the exact proposal and obtain approval. Task IDs are shown for verification; the user never has to type one manually.

## Apply

After approval, preview then apply:

```bash
python3 ~/work/projects/admin/scripts/academic_ops.py close-session \
  --repo /absolute/repository/path \
  --status active \
  --phase "..." \
  --next-task-id tsk-xxxxxxxxxxxx \
  --concern "..." \
  [--complete-id tsk-yyyyyyyyyyyy]

python3 ~/work/projects/admin/scripts/academic_ops.py close-session \
  [same arguments] --apply
```

The CLI owns the Vault lock, pre-write hashes, backups, atomic writes, rollback before commit, full project audit, status-only `chore: 現在地更新` commit, and push. Do not reproduce these writes manually.

If the audit fails before commit, report that the transaction was rolled back and list the contradictions. If commit succeeds but push fails, keep the commit, report the repository as ahead, and never rewrite history or force-push.

End with the completed task, selected next task, resulting phase/status, audit result, commit, and push result.
