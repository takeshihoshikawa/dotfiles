---
name: weekly-review
description: Conduct a staged weekly review covering evidence-based reflection, current project screening, task proposals, and next-week planning. Use for weekly review, last-week review, task cleanup, or planning the coming week.
---

# Weekly review

## Codex execution profile

Use `gpt-5.6-terra` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_weekly_review` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Keep the same delegated child across phases. Relay its user questions and exact approval proposals, then resume it with `followup_task`; do not spawn a replacement child. Before delegation, include the requested week, explicit user context, corrections, and existing approvals.

## Shared workflow

Before execution or delegation, read [the shared contract](../../references/secretary-contract.md) and [the complete workflow](../../references/weekly-review-workflow.md). The shared workflow is authoritative for collection, dialogue, saved sections, and approval points in Claude Code, ChatGPT Work, and Codex. Pass its path to any delegated child and require the child to read it.

This entrypoint contains only the execution profile and session handoff. Do not duplicate or maintain a separate workflow here. Natural-language requests use the same workflow as explicit skill selection.
