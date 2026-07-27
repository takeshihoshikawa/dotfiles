---
name: morning-brief
description: Build a morning secretary brief from goals, the latest daily note, the prior weekly plan, Google Calendar, Obsidian tasks, GitHub issues, and repository state. Use for morning, today planning, or tomorrow planning.
---

# Morning brief

## Codex execution profile

Use `gpt-5.6-terra` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_morning` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Keep the delegated child available across planning phases. When it asks the user to prioritize tasks or approve exact changes, the parent must relay that prompt. After the user answers, continue the same child with `followup_task`; do not spawn a replacement child. The initial delegation counts as the one routing action, while follow-ups resume the same workflow state.

---

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

After the user confirms priorities, end with a compact `Confirmed plan` containing:

- One sentence for the day's theme.
- Only the outcomes the user intends to pursue, each with a completion condition.
- A complete planned-effort allocation for research, administration, and teaching that sums to the target day's available working time. Derive a reasonable allocation from the chosen priorities and calendar; present it as part of the confirmed plan so the user can correct it.
- Relevant constraints such as working hours, lunch, calendar commitments, or health stop conditions.

Do not write this plan into the daily note. Keep it in the session so a later daily-report recap can compare it with execution. Omit inactive and waiting projects unless they materially constrain the day.
