---
name: morning
description: Build and confirm a compact morning plan from goals, the latest daily note, the target week's plan, Google Calendar, Obsidian tasks, GitHub issues, and repository state. Use for morning planning, today or tomorrow planning, or starting a day-long work session that will end with a daily report.
---

# Morning

## Codex execution profile

Use `gpt-5.6-terra` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_morning` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Keep the delegated child available across planning phases. When it asks the user to prioritize tasks or approve exact changes, the parent must relay that prompt. After the user answers, continue the same child with `followup_task`; do not spawn a replacement child.

## Shared workflow

Before execution or delegation, read [the shared contract](../../references/secretary-contract.md) and [the complete workflow](../../references/morning-workflow.md). The shared workflow is authoritative for collection, dialogue, saved sections, and approval points in Claude Code, ChatGPT Work, and Codex. Pass its path to any delegated child and require the child to read it.

This entrypoint contains only the execution profile and session handoff. Do not duplicate or maintain a separate workflow here. Natural-language requests use the same workflow as explicit skill selection.
