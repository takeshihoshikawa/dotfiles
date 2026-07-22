---
name: capture-task
description: Capture a thought, reminder, or action as one executable Obsidian task. Use when the user says to remember, capture, add, or jot down a task and wants minimal interruption.
---

# Capture task

Read [the shared contract](../../references/secretary-contract.md), then complete the capture in one response.

1. Convert the input into one concrete action. If it is larger than half a day, narrow it to the next executable step. If it is an idea, state what to investigate and where the result should be recorded.
2. Preserve a due date or priority only when the user supplied it. Do not invent either.
3. Unless the user names another approved location, append to the vault-root `tasks.md`; its final `## inbox` section receives plain appends.
4. Start Obsidian only if needed, then run:

```bash
pgrep -x Obsidian >/dev/null || { open -a Obsidian; sleep 2; }
obsidian append file="tasks" content="- [ ] {task text}"
```

If the user asks for a preview or says not to save, show the proposed line without writing.

Respond with one line: `✓ 「{saved text}」→ inbox`.
