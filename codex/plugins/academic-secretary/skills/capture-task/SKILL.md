---
name: capture-task
description: Capture a thought, reminder, or action as one executable Obsidian task. Use when the user says to remember, capture, add, or jot down a task and wants minimal interruption.
---

# Capture task

## Codex execution profile

Use `gpt-5.6-terra` with `low` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this `SKILL.md` before acting. The child must identify itself as the `academic_capture` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

---

Read [the shared contract](../../references/secretary-contract.md), then complete the capture in one response.

1. Convert the input into one concrete action. If it is larger than half a day, narrow it to the next executable step. If it is an idea, state what to investigate and where the result should be recorded.
2. Preserve a due date or priority only when the user supplied it. Do not invent either.
3. Unless the user names another approved location, append to the vault-root `tasks.md`; its final `## inbox` section receives plain appends.
4. Create the task through the control CLI so a stable ID and safe write are guaranteed. Preview first; if it matches the user's request, apply it in the same run unless the user requested preview-only:

```bash
python3 ~/work/projects/admin/scripts/academic_ops.py task create \
  "{task text}" [--project PROJECT] [--due YYYY-MM-DD] [--priority LEVEL]
python3 ~/work/projects/admin/scripts/academic_ops.py task create \
  "{task text}" [same options] --apply
```

For a meeting-originated task, pass `--file meetings/{note}.md`. Never hand-write or invent a task ID.

If the user asks for a preview or says not to save, show the proposed line without writing.

Respond with one line: `✓ 「{saved text}」→ inbox（ID自動付与済み）`.
