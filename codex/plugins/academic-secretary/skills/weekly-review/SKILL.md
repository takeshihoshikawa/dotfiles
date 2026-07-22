---
name: weekly-review
description: Conduct a staged weekly review covering evidence-based reflection, current project screening, task proposals, and next-week planning. Use for weekly review, last-week review, task cleanup, or planning the coming week.
---

# Weekly review

Read [the shared contract](../../references/secretary-contract.md). Proceed in phases and obtain approval before every write.

## Resolve the period

- Explicit `0`, “this week,” `-1`, or “last week” always wins.
- If omitted, use the previous week on Monday–Wednesday and the current week on Thursday–Sunday.
- The reflection evidence window is Monday 00:00 through Sunday 23:59:59 in Asia/Tokyo. Never count later progress as a target-week accomplishment.

## Phase 1: collect silently

Collect in parallel:

- Daily notes within the evidence window; these are the primary record.
- Completed Obsidian tasks only when their completion date is demonstrably inside the window.
- Current unfinished and `#waiting` tasks.
- `~/vault/notes/goals.md`.
- Open GitHub issues as current planning context.
- Connected Google Calendar events for the next two weeks, including the Japanese-holiday calendar when available.
- Assigned course sessions under `courses/{course_id}/sessions/` for the next two weeks.
- Current `active` and `waiting` project metadata and non-chore last commits.

Current project state is planning context, not retrospective evidence. A project that advanced after the review window must not be reported as having advanced during that week.

## Phase 2: reflect

Summarize achievements, misses, and reasons under education, research, and administration. Then include explicit cross-cutting observations. Ask the user for corrections, a one-line feeling about the week, and a one-line connection to `goals.md`.

## Phase 3: organize work

Show the next two weeks of calendar and teaching commitments, current inbox tasks, `#waiting` items, and open GitHub issues. Propose only actionable tasks for next week.

Ask which proposed tasks to adopt. Apply approved tasks to the locations defined by global `AGENTS.md`; do not duplicate meeting-originated tasks or add checkboxes to project notes.

Check whether one or two `研究コアブロック` events already exist next week. Suggest 08:00–10:30 weekday slots that avoid holidays and conflicts. Create events only after approval.

## Phase 4: plan

Build a weekday plan from calendar commitments and approved tasks. Ask for the single most important focus and incorporate it as `## 来週の重点`.

## Phase 5: save

Show the final report and ask whether to save it. Save as:

```text
~/vault/weekly/weekly-{reviewed-week Monday YYYY-MM-DD}.md
```

Include the reflection, the user’s weekly statement, goal connection, next-week plan, and next-week focus. Respect preview-only or no-save scope without asking again.
