---
name: daily-check-in
description: Perform a short, read-only check of whether the user’s current work matches today’s plan and long-term goals. Use for “check in,” “am I on track,” or a lightweight course correction.
---

# Daily check-in

Read [the shared contract](../../references/secretary-contract.md). This skill is always read-only.

1. Identify the current work from the recent conversation. If there is no work to evaluate, say so in one line and stop.
2. Read `~/vault/notes/goals.md` and today’s `~/vault/daily/YYYY-MM-DD.md` when present.
3. Check whether the current work matches today’s plan, conflicts with a stated goal, or has been stuck for roughly an hour.
4. Do not ask questions, edit files, alter calendars, or run git mutations.

Return either:

- `✓ {current work} — 続行`
- Three short lines: current work, `✓/⚠/✗` assessment, and one recommended action.

Do not explain the scoring method.
