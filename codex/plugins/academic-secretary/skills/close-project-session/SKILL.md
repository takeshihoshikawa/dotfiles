---
name: close-project-session
description: Close a git-backed academic project work session by reconciling completed and next Obsidian tasks, project status, generated CLAUDE status, project-note projection, audit, commit, and push. Use when the user says today's project work is done, "今日はここまで", or asks to update the current project state.
---

# Close project session

Read [the shared contract](../../references/secretary-contract.md) completely before acting.

## Collect and propose

1. Identify the repository and run the repository-divergence checks from global `AGENTS.md`.
2. Read the conversation, `git diff`, `project-status.yaml`, its generated `CLAUDE.md` block, and every official Obsidian task for that project.
3. If there are uncommitted changes outside `project-status.yaml` and `CLAUDE.md`, stop without writing and ask the user to preserve the ordinary work first.
4. Propose one transaction: new phase, task IDs to complete, one next task ID or project status change, concern, and update date. Never infer semantic task completion from a status sentence alone.
5. Show the exact proposal and obtain approval. Task IDs are shown for verification; the user never has to type one manually.

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
