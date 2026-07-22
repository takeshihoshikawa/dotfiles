# Course Q&A output

## Obsidian file

Save one question per file under:

```text
~/vault/courses/{course_id}/qa/{topic}_{year}_{NNN}.md
```

Use the next three-digit sequence after inspecting existing files.

```markdown
---
course: {course}
course_id: {course_id}
class: {class}
topic: {topic}
topic_id: {topic_id}
year: {year}
q: "{question}"
sources:
  - "{title}: {URL}"
---

{answer}
```

Omit `topic_id` only when the session and `_meta.md` do not define it. Use `sources: []` when no external source was used. Do not add a visible references section unless requested.

## Distribution PDF

Combine only the questions approved in the current run. Use A4, 11pt, 25mm margins, 1.4 line spacing, and Hiragino Kaku Gothic ProN W3/W6. Put the distribution date in the page header; never reuse a fixed sample date.

Resolve the distribution session’s `topic_id` through `courses/{course_id}/_meta.md` and write:

```text
~/Documents/lecture/{lecture_dir}/{lecture_folder}/QA{YYYYMMDD}.pdf
```

Prefer pandoc with xelatex and xeCJK. Render the PDF to images and verify the date, Japanese font, line wrapping, URLs, and page count before delivery.
