# Secretary workflow contract

- Treat explicit user scope as binding. “Preview,” “do not save,” and “do not update the PDF” prohibit those writes for the rest of that run.
- Use Asia/Tokyo for dates and calendar ranges. Never silently replace a requested past date with today.
- Treat existing Obsidian notes and explicit user statements as primary evidence. Calendar, GitHub, and git history may corroborate or fill gaps but must not be expanded into unsupported work details or durations.
- Read and edit note bodies through normal file access. Use the `obsidian` CLI for daily-note operations, tasks, properties, moves, renames, and deletes.
- Preserve the task locations and formats in the active global instructions (`AGENTS.md` or `CLAUDE.md`, as applicable). Do not duplicate project tasks between `tasks.md`, meeting notes, and project notes.
- Obsidian Tasks in vault-root `tasks.md` and `meetings/*.md` are the only executable-task source of truth. Every task must retain a stable `[task_id:: tsk-xxxxxxxxxxxx]`; create and complete tasks through `~/work/projects/admin/scripts/academic_ops.py` so IDs, completion dates, locking, backups, and conflict checks are applied.
- Before using project status for planning, run `academic_ops.py audit`. Do not select a project with an integrity violation as the recommended next action. Warnings may be shown with their evidence; integrity violations must be resolved first.
- For git-backed projects, `project-status.yaml` is the status source of truth. The generated block in `CLAUDE.md` and generated project-note properties must not be edited manually. Use `academic_ops.py project render` or the `close-project-session` skill.
- Generated control labels are English (`Current Status`, `Phase`, `Next task`, `Concern`, `Updated`); project-content values and task text may remain Japanese. Accept legacy Japanese labels during migration only.
- A task completion that would close the current `next_task_id` must include an approved replacement or an approved status change in the same transaction.
- Never connect Outlook Mail or Teams. The university account is intentionally unavailable. Use Google Calendar only when the connected calendar is relevant.
- Before any git edit or commit, follow the repository-divergence rules in `AGENTS.md`. Never force-push or discard unrelated changes.
- Keep routine answers compact. Expand only when a decision, exception, or risk needs explanation.

## Shared planning and reporting workflows

- `morning-workflow.md`, `daily-report-workflow.md`, and `weekly-review-workflow.md` in this directory are the sole maintained workflow bodies. Both clients read them; the skill entrypoints retain only discovery metadata and client execution details.
- Morning plans are saved under `## 朝の計画` in the target daily note after approval. The current session can carry later explicit revisions and work reports; do not require the user to retype them at recap time.
- A preview-only or no-save run of these three workflows is read-only: use `repo_snapshot.py` without `--fetch` or `--pull-safe` (with `--date` if needed), and skip `project_radar.py`, task mutations, note creation, and other projection writes. `academic_ops.py audit` and ordinary reads remain available. Do not run workflow collection commands merely because someone is editing or reviewing this skill.
- Obtain approval for the concrete draft or task changes required by the workflow; existing explicit authorization remains valid. Phase 6 of weekly review records only the user's answer to the stated life-axis question and does not add a second save confirmation. A no-save instruction still prohibits that write.
- Use the canonical script operations for tasks even when an older Obsidian CLI example suggests a direct checkbox edit. Respect user scope and active global task/status rules over older examples.
