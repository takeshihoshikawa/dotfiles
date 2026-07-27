---
name: morning
description: Build and confirm a compact morning plan from goals, the latest daily note, the prior weekly plan, Google Calendar, Obsidian tasks, GitHub issues, and repository state. Use for morning planning, today or tomorrow planning, or starting a day-long work session that will end with daily-report recap.
---

# Morning

## Codex execution profile

Use `gpt-5.6-terra` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_morning` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Keep the delegated child available across planning phases. When it asks the user to prioritize tasks or approve exact changes, the parent must relay that prompt. After the user answers, continue the same child with `followup_task`; do not spawn a replacement child.

---

Read [the shared contract](../../references/secretary-contract.md). Interpret “tomorrow” explicitly; otherwise target today.

## Workflow contract

Create the day's plan in the current session. Do not write the morning plan into the daily note. The later `daily-report recap` is responsible for combining the confirmed plan, the user's subsequent work updates, and external evidence into the final daily note after approval.

After confirming the plan, keep this task as the user's lightweight work log. For later free-form updates:

- Preserve explicit work, times or durations, decisions, observations, status changes, and carryovers as recap evidence.
- Reply with a short acknowledgment unless the user asks for analysis or an action.
- Do not append to the daily note unless the user explicitly requests durable logging.
- Do not ask the user to repeat facts available from git or GitHub.

## Collect

Run independent reads in parallel where possible.

1. Resolve `../../scripts/repo_snapshot.py` relative to this skill and run it with `--fetch --pull-safe --format json`. Report only pulls, failures, dirty repositories, and divergence.
2. After safe pulls finish, run `project_mirror.py` and `project_radar.py` from `~/work/projects/admin/scripts/`. Show only warnings.
3. Read `~/vault/notes/goals.md` and the newest daily note strictly before the target date.
4. Find the Monday of the target week, subtract seven days, and read `~/vault/weekly/weekly-{previous Monday}.md`. Extract the target weekday from `## 来週の計画` and `## 来週の重点`. Weekly filenames represent the reviewed week.
5. Use connected Google Calendar data for the target date and following date in Asia/Tokyo. Do not attempt Outlook or Teams.
6. Get unfinished tasks with `obsidian tasks todo format=json`; fall back to `rg` only if unavailable. Exclude `#waiting`. Separate overdue, due on the target date, and undated next candidates.
7. Retrieve open GitHub issues when available, but do not treat an issue as today's task without supporting context.

## Propose

Present only decision-relevant evidence:

1. Goal and weekly-plan context.
2. Previous work and explicit carryovers.
3. Target-day and following-day calendar constraints.
4. Overdue, due-today, and up to ten plausible next-task candidates.
5. Important repository warnings.

Recommend priorities and ask the user to confirm or revise them. Do not change task dates, completion, priority, or calendar events until the user approves the exact changes. Batch approved changes and report them briefly.

## Confirm

End planning with one compact `Confirmed plan` containing:

- One sentence for the day's theme.
- Up to three intended outcomes, each with a completion condition.
- A complete planned-effort allocation for research, administration, and teaching that sums to the target day's available working time.
- Relevant constraints such as working hours, lunch, calendar commitments, dependencies, or health stop conditions.
- A short “not today” line only when it prevents likely distraction.

This confirmed plan is the plan source for `daily-report recap`. Keep it in the session; do not duplicate it in Obsidian. Tell the user they can continue posting brief work updates in the same task and later say `daily-report recap`.
