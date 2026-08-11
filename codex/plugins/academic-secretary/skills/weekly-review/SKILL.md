---
name: weekly-review
description: Conduct a staged weekly review covering evidence-based reflection, current project screening, task proposals, and next-week planning. Use for weekly review, last-week review, task cleanup, or planning the coming week.
---

# Weekly review

## Codex execution profile

Use `gpt-5.6-terra` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_weekly_review` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

---

Read [the shared contract](../../references/secretary-contract.md). Proceed in phases and obtain approval before every write.

## Resolve the period

- Explicit `0`, “this week,” `-1`, or “last week” always wins.
- If omitted, use the previous week on Monday–Wednesday and the current week on Thursday–Sunday.
- The reflection evidence window is Monday 00:00 through Sunday 23:59:59 in Asia/Tokyo. Never count later progress as a target-week accomplishment.

## Phase 1: collect silently

Collect in parallel:

- Daily notes within the evidence window; these are the primary record. Extract:
    - `## 計画と結果`, including project, morning role, outcome status, and allocation assessment.
    - The user's activity intervals and delegated outcomes under `## やったこと`.
    - Actual research, administration, and teaching time from `## エフォート配分`.
    - `## 気づき` and `## 次への引継ぎ`.
- The target week's `## 週の計画`, including expected outcomes, project priorities, and the weekly effort budget.
- Completed Obsidian tasks only when their completion date is demonstrably inside the window.
- Current unfinished and `#waiting` tasks.
- `~/vault/notes/goals.md`.
- Open GitHub issues as current planning context.
- Connected Google Calendar events for the next two weeks, including the Japanese-holiday calendar when available.
- Assigned course sessions under `courses/{course_id}/sessions/` for the next two weeks.
- Current `active` and `waiting` project metadata and non-chore last commits.

Current project state is planning context, not retrospective evidence. A project that advanced after the review window must not be reported as having advanced during that week.

## Phase 2: reflect

Compare every expected outcome in the weekly plan with the evidence. Use only `達成`, `一部達成`, `未着手`, `変更`, or `想定以上` as the outcome status. Treat `外部待ち` as a reason or project state, not an outcome status.

Group the daily `## 計画と結果` rows by project. Compare their morning roles and allocation assessments with the weekly project priorities to determine whether the main focus held, planned limits were respected, and changes were intentional. Do not reconstruct missing project allocation from free-form narrative.

For effort allocation:

- Use the target week's `## 週の計画` effort budget as the planned values.
- Sum only the daily actual values under `## エフォート配分` as the actual values.
- Calculate each difference as actual minus weekly budget.
- Do not sum daily planned values or daily differences; they are daily self-check fields only.
- State the covered dates and preserve missing or unmeasured time instead of inferring it.

Summarize achievements, misses, and reasons under education, research, and administration. Then include explicit cross-cutting observations. Ask the user for corrections, a one-line feeling about the week, and a one-line connection to `goals.md`.

## Phase 3: organize work

Run `academic_ops.py audit --format json`, then show the next two weeks of calendar and teaching commitments, current inbox tasks, `#waiting` items, and open GitHub issues. Explicitly screen stale open tasks, active projects without a valid next task, waiting projects pointing to non-waiting work, and done projects with open tasks. Propose only actionable tasks for next week; do not auto-fix semantic contradictions.

Ask which proposed tasks to adopt. Apply approved tasks to the locations defined by global `AGENTS.md`; do not duplicate meeting-originated tasks or add checkboxes to project notes.

Check whether one or two `研究コアブロック` events already exist next week. Suggest 08:00–10:30 weekday slots that avoid holidays and conflicts. Create events only after approval.

## Phase 4: plan

Build a weekday plan from calendar commitments and approved tasks. Ask for the single most important focus and incorporate it as `## 来週の重点`.

## Phase 5: save

Show the final report and ask whether to save it. Save as:

```text
~/vault/weekly/weekly-{reviewed-week Monday YYYY-MM-DD}.md
```

The reflection must include:

- `### 計画との比較`: expected outcome, result, and the shared five-value outcome status.
- `### プロジェクト配分`: project, weekly role, grouped daily allocation/delegated outcome, and assessment.
- `### エフォート配分`: category, weekly budget, summed daily actual, and actual-minus-budget difference.
- The covered dates and any missing or unmeasured time next to the effort table.

Also include the user’s weekly statement, goal connection, next-week plan, and next-week focus. Respect preview-only or no-save scope without asking again.
