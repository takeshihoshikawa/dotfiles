---
name: morning-brief
description: Build a morning secretary brief from goals, the latest daily note, the prior weekly plan, Google Calendar, Obsidian tasks, GitHub issues, and repository state. Use for morning, today planning, or tomorrow planning.
---

# Morning brief

Read [the shared contract](../../references/secretary-contract.md). Interpret “tomorrow” explicitly; otherwise target today.

## Collect

Run independent reads in parallel where possible.

1. Resolve `../../scripts/repo_snapshot.py` relative to this skill and run it with `--fetch --pull-safe --format json`. Report only pulls, failures, dirty repos, and divergence.
2. After safe pulls finish, run:

```bash
python3 ~/work/projects/admin/scripts/project_mirror.py
python3 ~/work/projects/admin/scripts/project_radar.py
```

Show only warnings from these scripts.

3. Read `~/vault/notes/goals.md` and the newest daily note strictly before the target date.
4. Find the Monday of the target week, subtract seven days, and read `~/vault/weekly/weekly-{previous Monday}.md`. Extract the target weekday from `## 来週の計画` and `## 来週の重点`. This previous-week offset is required because weekly filenames represent the reviewed week.
5. Use connected Google Calendar data for the target date and following date in Asia/Tokyo. Do not attempt Outlook or Teams.
6. Get unfinished tasks with `obsidian tasks todo format=json`; fall back to `rg` only if the CLI output is unavailable. Exclude `#waiting`. Separate overdue, due on target date, and undated next candidates.
7. Retrieve open GitHub issues when available, but do not treat an issue as today’s task unless its context supports that choice.

## Present

Show, in order:

1. Long-term goals, compactly.
2. Previous work and explicit observations.
3. Weekly plan for the target day when available.
4. Target-day and following-day calendars.
5. Overdue, due-today, and up to ten next-task candidates.
6. Important repository warnings.

Then ask which tasks to prioritize. Do not change task dates, completion, priority, or calendar events until the user approves the exact changes. Batch approved changes and report them briefly.
