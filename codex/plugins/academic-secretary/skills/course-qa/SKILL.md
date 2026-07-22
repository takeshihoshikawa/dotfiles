---
name: course-qa
description: Draft concise answers to student course questions, restore questions from Obsidian, save approved one-question files, and optionally build a verified distribution PDF. Use for course Q&A, student questions, answer review, or prior-Q&A retrieval.
---

# Course Q&A

Read [the shared contract](../../references/secretary-contract.md) and, when writing outputs, [the output format](references/output-format.md).

## Establish scope

Default to the full flow: approve answers, save Obsidian files, then generate the PDF. Explicit user scope overrides it:

- Preview, validation, or simulated completion: write nothing.
- Answer only: stop after the approved response.
- No PDF: save approved Obsidian files but do not create or update a PDF.

State the scope once. After a no-save or no-PDF instruction, do not ask to perform that write again.

## Select the course and questions

1. Find the three newest session notes dated today or earlier under `~/vault/courses/*/sessions/` whose `owner:` matches global `AGENTS.md`. Ask the user to select when the course is not already clear.
2. Read `course_id`, `course`, `topic`, `topic_id`, and `class` from the selected session.
3. If the user asks to restore questions, search the selected session, matching `qa/*.md`, and related daily notes. Recover `q:` values and bodies rather than asking the user to retype. Ask only when multiple plausible sets remain.
4. Search the selected course’s prior Q&A by keywords, widening to all courses only when useful. Reuse consistent facts, terminology, and links.

## Draft answers

- Lead with the answer and use concise plain-form Japanese, normally one to three paragraphs.
- Add context or examples only when they improve understanding.
- Separate facts from interpretation or opinion.
- Clarify an ambiguous question by stating the assumed intent and offering a refined question.
- Verify current, niche, or consequential facts with authoritative sources. Record source titles and direct URLs. Existing course notes alone require no external source entry.

Present all answers together. Revise until approved; never save an unapproved answer.

## Write approved outputs

Follow [the output format](references/output-format.md). Determine the distribution date from the next relevant session, or use today when none exists.

For PDF generation, use the installed PDF workflow and the existing pandoc/xelatex environment. Render and visually verify the result. Do not overwrite an already-returned PDF when the user requested review only.
