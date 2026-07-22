---
name: my-courses
description: List upcoming course sessions owned by the user from the Obsidian course registry and session notes. Use when the user asks about upcoming classes, teaching schedule, or assigned courses.
---

# My courses

This skill is read-only. Default to five sessions unless the user gives another count.

1. Read the course owner name from global `AGENTS.md`.
2. Search `~/vault/courses/*/sessions/YYYY-MM-DD_*.md` for dates today or later and matching `owner:`. Sort ascending and keep the requested count.
3. Read each selected note. Extract `date`, `course`, `class`, `topic`, `prepared`, and a compact summary of the body when present.
4. Show the results chronologically. Mention missing preparation metadata without inventing a status.

Use the actual `courses/{course_id}/sessions/` structure. Do not search legacy academic-year directories.
