# Secretary workflow contract

- Treat explicit user scope as binding. “Preview,” “do not save,” and “do not update the PDF” prohibit those writes for the rest of that run.
- Use Asia/Tokyo for dates and calendar ranges. Never silently replace a requested past date with today.
- Treat existing Obsidian notes and explicit user statements as primary evidence. Calendar, GitHub, and git history may corroborate or fill gaps but must not be expanded into unsupported work details or durations.
- Read and edit note bodies through normal file access. Use the `obsidian` CLI for daily-note operations, tasks, properties, moves, renames, and deletes.
- Preserve the task locations and formats in the active global `AGENTS.md`. Do not duplicate project tasks between `tasks.md`, meeting notes, and project notes.
- Never connect Outlook Mail or Teams. The university account is intentionally unavailable. Use Google Calendar only when the connected calendar is relevant.
- Before any git edit or commit, follow the repository-divergence rules in `AGENTS.md`. Never force-push or discard unrelated changes.
- Keep routine answers compact. Expand only when a decision, exception, or risk needs explanation.
