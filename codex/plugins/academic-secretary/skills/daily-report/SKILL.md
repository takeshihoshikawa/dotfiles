---
name: daily-report
description: Produce an evidence-based end-of-day report in an Obsidian daily note. Use for a daily report, end-of-day recap, or reconstructing a specified date from existing notes, conversation, calendar, GitHub, and git history.
---

# Daily report

## Codex execution profile

Use `gpt-5.6-sol` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_daily_report` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Keep the delegated child available across workflow phases. When it returns a time-gap question, draft approval request, or task-completion question, the parent must relay that prompt to the user. After the user answers, continue the same child with `followup_task`; do not spawn a replacement child. The initial delegation counts as the one routing action, while follow-ups resume the same workflow state.

Before delegating with `fork_turns="none"`, the parent must summarize the target date's relevant session context into the child task:

- The confirmed morning plan, including intended outcomes, completion conditions, planned effort, and constraints.
- Every user-reported work item and explicit time or duration.
- Explicit user observations, status changes, and carryovers.
- Any uncertainty the parent could not resolve from the session.

This session handoff is required because the child does not inherit conversation history. Ordinary work updates in the same session must be included through this handoff; do not require the user to record them separately in the daily note.

---

Read [the shared contract](../../references/secretary-contract.md). Default to today. Honor an explicit date, preview-only request, or no-save request.

## Evidence order

1. Existing `~/vault/daily/{date}.md` and explicit user statements.
2. Current conversation and other same-day notes.
3. Calendar events, closed GitHub issues, and git commits as corroborating evidence.

A commit proves its repository, timestamp, and subject. It does not prove the full work interval or unrecorded details. Leave an end time absent unless another event supports it. Do not invent “lessons learned” from work facts alone.

## Workflow

Collect in parallel:

- The existing target daily note.
- The session handoff supplied by the parent.
- Google Calendar events for the target date in Asia/Tokyo, excluding all-day events unless they materially describe work.
- Closed GitHub issues whose close time falls on the target date in Asia/Tokyo.
- Repository state and commits using `~/work/projects/admin/scripts/repo_snapshot.py --fetch --pull-safe --date {YYYY-MM-DD} --format json`.

Rebuild the day chronologically, merge duplicates, normalize formatting, and preserve uncertainty.

### Plan comparison

- Treat the confirmed morning plan as the plan source. If none exists, omit the comparison rather than reconstructing an elaborate plan after the fact.
- Pair each planned outcome directly with its project, morning role, execution result, outcome status, and allocation assessment in one compact table.
- Use only `達成`, `一部達成`, `未着手`, `変更`, or `想定以上` as the outcome status. `外部待ち` is a reason or project state, not an outcome status; record it in the result/reason text.
- Use `計画どおり`, `意図的変更`, or `意図しない流入` as the allocation assessment.
- Add material unplanned work only when it affected the day. Use `計画外` as its morning role and state whether it was an intentional change or unintended inflow.
- Do not repeat the same facts in separate project-allocation or narrative comparison sections.
- Omit inactive and waiting project inventories.

### Time reconciliation

Use this evidence order:

1. Explicit user times or durations.
2. Adjacent work reports, fixed calendar events, the recap time, and the user's normal working hours.
3. Reasonable inference from the surrounding activity.

Apply these rules:

- Use the user's normal working hours of 08:00-16:45 and lunch of 11:30-13:00 unless the day's evidence says otherwise.
- Infer a plausible end time from the next activity or normal workday boundary when that is the natural reading.
- Absorb or omit unresolved gaps shorter than 30 minutes without asking.
- Before drafting, ask one batched question covering every unresolved gap of 30 minutes or longer. Include the surrounding entries and any likely inference.
- Do not leave `時間未計測` or `算出不可` in the final effort table when the user can resolve the gap.
- Treat normal working hours as timeline boundaries, not proof of actual effort. Do not fill unsupported work solely to reach a full day.
- Reconcile research, administration, and teaching effort with the total actual working time. Use 7 hours 15 minutes as the reconciliation target only when the user confirms a normal full day or the evidence covers the day after lunch is excluded.
- If the user cannot resolve a material gap after being asked, preserve that uncertainty explicitly instead of inventing an exact total.
- If the morning plan has no planned-effort allocation, use `未設定` for planned values and `—` for differences rather than inventing zeroes.
- Exclude delegated or agent processing time from the user's effort.

### Concision

- Keep delegated results to at most three compact bullets and separate them from the user's timeline.
- Summarize only explicit user observations under `## 気づき`.
- Put only unresolved work and concrete next actions under `## 次への引継ぎ`.

Show the complete draft before replacing the file. Save only after approval. After saving, identify possible completed Obsidian tasks by stable task ID. In the same approval unit, propose each completion, the replacement `next_task_id` for any project whose current next task is being completed, and the resulting project phase/status/concern. After approval, use `academic_ops.py task complete` for ordinary tasks or the `close-project-session` workflow for a current project next task. Do not create new tasks.

Repository publication is outside this skill. If needed, offer `$sync-repos`; do not automatically commit or push every repository.

## Final format

```markdown
---
date: YYYY-MM-DD
tags:
  - daily
---

## 計画と結果

**主題**：朝に確定した主題

| プロジェクト | 朝の役割 | 期待成果 | 実行・成果／理由 | 判定 | 配分評価 |
|---|---|---|---|---|---|
| project-id | 本人の主軸・期限対応・維持・待機・計画外 | 完了条件を含む計画 | 実際の成果または未達理由 | 達成・一部達成・未着手・変更・想定以上 | 計画どおり・意図的変更・意図しない流入 |

## やったこと

- HH:MM–HH:MM **作業内容**
    - 詳細

### 委任した成果

- 本人のエフォートに含めない主要成果

## エフォート配分

| 区分 | 予定 | 実績 | 差 |
|---|---:|---:|---:|
| 研究 | 計画値または未設定 | 実績 | 差または— |
| 事務 | 計画値または未設定 | 実績 | 差または— |
| 教育 | 計画値または未設定 | 実績 | 差または— |

- 予定と差は日次セルフチェック専用。週次レビューは実績だけを合計する。

## 気づき

- 明示された気づき

## 次への引継ぎ

- 未解決事項または具体的な次の一手
```
