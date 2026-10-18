---
name: morning
description: Build and confirm a compact morning plan from goals, the latest daily note, the target week's plan, Google Calendar, Obsidian tasks, GitHub issues, and repository state. Use for morning planning, today or tomorrow planning, or starting a day-long work session that will end with a daily report.
---

# Morning

## Codex execution profile

Use `gpt-6.1-sol` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_morning` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Keep the delegated child available across planning phases. When it asks the user to prioritize tasks or approve exact changes, the parent must relay that prompt. After the user answers, continue the same child with `followup_task`; do not spawn a replacement child.

## Shared workflow

At the start of every run, resolve and read the shared files in this order:

1. When `~/dotfiles/codex/plugins/academic-secretary/references/secretary-contract.md` and `~/dotfiles/codex/plugins/academic-secretary/references/morning-workflow.md` exist, read those canonical files in full. They are the latest procedures.
2. Otherwise, read [the bundled shared contract](../../references/secretary-contract.md) and [the bundled complete workflow](../../references/morning-workflow.md).

Use the resolved workflow as authoritative for collection, dialogue, saved sections, and approval points in Claude Code, ChatGPT Work, and Codex. Pass the exact resolved paths to any delegated child and require the child to read both files before acting. Do not follow a version-pinned cache path from an earlier message, automation prompt, or memory when the canonical files are available.

This entrypoint contains only the execution profile and session handoff. Do not duplicate or maintain a separate workflow here. Natural-language requests use the same workflow as explicit skill selection.
