---
name: daily-report
description: Append work to an Obsidian daily note or produce an evidence-based end-of-day recap. Use for daily report, work log, recap, or reconstructing a specified date from existing notes, conversation, calendar, GitHub, and git history.
---

# Daily report

Read [the shared contract](../../references/secretary-contract.md). Default to append mode and today. Honor an explicit mode, date, preview-only request, or no-save request.

## Evidence order

1. Existing `~/vault/daily/{date}.md` and explicit user statements.
2. Current conversation and other same-day notes.
3. Calendar events, closed GitHub issues, and git commits as corroborating evidence.

A commit proves its repository, timestamp, and subject. It does not prove the full work interval or unrecorded details. Leave an end time absent unless another event supports it. Do not invent “lessons learned” from work facts alone.

## Append mode

1. Read the target daily note and ensure frontmatter plus `## やったこと` exists.
2. Extract only work and explicit observations from the current conversation.
3. Append immediately unless the user requested preview-only. For today, `obsidian daily:append` is allowed only when no later `## 気づき` section would capture the entry. Otherwise insert into `## やったこと` with a targeted file edit.

Use:

```markdown
- HH:MM–HH:MM **作業内容**
    - 詳細
```

Use four-space child indentation. A start time alone is valid.

## Recap mode

Collect in parallel:

- The existing target daily note.
- Google Calendar events for the target date in Asia/Tokyo, excluding all-day events unless they materially describe work.
- Closed GitHub issues whose close time falls on the target date in Asia/Tokyo.
- Repository state and commits using `../../scripts/repo_snapshot.py` resolved relative to this `SKILL.md`, with arguments `--fetch --pull-safe --date {YYYY-MM-DD} --format json`.

Rebuild the day chronologically, merge duplicates, normalize formatting, and preserve uncertainty. Summarize only explicit user observations under `## 気づき`.

Show the complete draft before replacing the file. Save only after approval. After saving, identify possible completed Obsidian tasks and ask before marking them done. Do not create new tasks.

Repository publication is outside this skill. If needed, offer `$sync-repos`; do not automatically commit or push every repository.

## Final format

```markdown
---
date: YYYY-MM-DD
tags:
  - daily
---

## やったこと

- HH:MM–HH:MM **作業内容**
    - 詳細

## 気づき

- 明示された気づき
```
