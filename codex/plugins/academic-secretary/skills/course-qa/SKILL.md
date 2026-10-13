---
name: course-qa
description: Process cumulative minute papers for participation grading and student Q&A using the courses repository workflow. Use for course questions, answer review, scan grading, or prior-Q&A retrieval.
---

# Course Q&A

## Shared teaching workflow

The authoritative entrypoint is `~/work/projects/courses/.agents/skills/course-qa/SKILL.md`. Read it, its shared contract, and its workflow before execution or delegation. The courses workflow governs scanning, grading, approvals, Obsidian Q&A, and handouts in Claude Code, ChatGPT Work, and Codex.

Do not maintain an independent Q&A or PDF workflow here. Approved Q&A lives in the Vault; handouts are exported with the existing courses helper to `QA_YYYYMMDD.qmd` in the distribution session's folder and listed in its existing 印刷.yml. Never fall back to the old standalone PDF output in iCloud.

If the courses checkout or referenced files are missing, report that prerequisite and stop the affected workflow rather than reconstructing it from memory. Teaching writes belong in a local courses project. Read-only question retrieval can run from admin.

## Codex execution profile

Use `gpt-5.6-terra` with `medium` reasoning effort. When subagent execution is available and this request has not already been routed, delegate the complete workflow exactly once with `fork_turns="none"`, that model and effort, and instructions to read this entrypoint and the courses entrypoint. The child must identify itself as the `academic_course_qa` profile.

If already running as that profile or subagent execution is unavailable, execute locally. Do not recursively delegate or launch a nested CLI process solely to switch models. The parent must not repeat completed child work.

Pass the user's selected course, class, dates, scan path, questions, execution scope, exclusions, prior decisions, and approvals to the child. Keep that child across approval phases; relay its question to the user, then resume it with `followup_task` carrying the user's response. Do not replace it or let an approval get lost. Explicit no-save, no-grading, or no-handout scope applies to all phases, including scan copies and task writes.
