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

## Shared workflow

Before execution or delegation, read [the shared contract](../../references/secretary-contract.md) and [the complete workflow](../../references/daily-report-workflow.md). The shared workflow is authoritative for collection, dialogue, saved sections, and approval points in Claude Code, ChatGPT Work, and Codex. Pass its path to any delegated child and require the child to read it.

This entrypoint contains only the execution profile and session handoff. Do not duplicate or maintain a separate workflow here. Natural-language requests use the same workflow as explicit skill selection.
