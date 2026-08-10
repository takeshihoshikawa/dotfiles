# Secretary workflow contract

- Treat explicit user scope as binding. “Preview,” “do not save,” and “do not update the PDF” prohibit those writes for the rest of that run.
- Use Asia/Tokyo for dates and calendar ranges. Never silently replace a requested past date with today.
- Treat existing Obsidian notes and explicit user statements as primary evidence. Calendar, GitHub, and git history may corroborate or fill gaps but must not be expanded into unsupported work details or durations.
- Read and edit note bodies through normal file access. Use the `obsidian` CLI for daily-note operations, tasks, properties, moves, renames, and deletes.
- Preserve the task locations and formats in the active global `AGENTS.md`. Do not duplicate project tasks between `tasks.md`, meeting notes, and project notes.
- Obsidian Tasks in vault-root `tasks.md` and `meetings/*.md` are the only executable-task source of truth. Every task must retain a stable `[task_id:: tsk-xxxxxxxxxxxx]`; create and complete tasks through `~/work/projects/admin/scripts/academic_ops.py` so IDs, completion dates, locking, backups, and conflict checks are applied.
- Before using project status for planning, run `academic_ops.py audit`. Do not select a project with an integrity violation as the recommended next action. Warnings may be shown with their evidence; integrity violations must be resolved first.
- For git-backed projects, `project-status.yaml` is the status source of truth. The generated block in `CLAUDE.md` and generated project-note properties must not be edited manually. Use `academic_ops.py project render` or the `close-project-session` skill.
- Generated control labels are English (`Current Status`, `Phase`, `Next task`, `Concern`, `Updated`); project-content values and task text may remain Japanese. Accept legacy Japanese labels during migration only.
- A task completion that would close the current `next_task_id` must include an approved replacement or an approved status change in the same transaction.
- Never connect Outlook Mail or Teams. The university account is intentionally unavailable. Use Google Calendar only when the connected calendar is relevant.
- Before any git edit or commit, follow the repository-divergence rules in `AGENTS.md`. Never force-push or discard unrelated changes.
- Keep routine answers compact. Expand only when a decision, exception, or risk needs explanation.
