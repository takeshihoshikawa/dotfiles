# Global Codex Settings

## Obsidian Vault

Vault path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/main` (`~/vault` is also available as a symlink; if missing, create it with `ln -sfn "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main" "$HOME/vault"`).

Folder structure:
- `daily/` - daily notes (`YYYY-MM-DD.md`)
- `weekly/` - weekly notes (`weekly-YYYY-MM-DD.md`)
- `courses/registry.md` - course registry and `course_id` entry point
- `courses/{course_id}/_meta.md` - course definition, topics, and lecture-folder mappings
- `courses/{course_id}/sessions/` - session notes (`YYYY-MM-DD_科目名.md`)
- `courses/{course_id}/qa/` - accumulated course Q&A files
- `meetings/` - meeting notes (`YYYY-MM-DD_タイトル.md`)
- `projects/` - project notes. Keep kebab-case `.md` files flat; use only `projects/archive/` as a subdirectory. Put reports and analyses in the corresponding git repository.
- `notes/` - misc notes, workflow docs, ideas
- `sources/` - imported or external source material; literature PDFs and metadata are managed with papis
- `notes/goals.md` - long-term goals and direction
- `tasks.md` - centralized task list at the vault root

## Notes And Tasks

Use Obsidian Tasks for execution management. Project notes are a management layer and must not contain task checkboxes.

| Type | Location | Format |
|------|----------|--------|
| Project task | `tasks.md` when planning-originated; meeting note when meeting-originated | `- [ ] 内容 #project/{kebab-case} [due:: YYYY-MM-DD] [priority:: medium]` |
| Non-project task | `tasks.md` | `- [ ] 内容 [due:: YYYY-MM-DD] [priority:: medium]` |

`#project/{kebab-case}` must match the corresponding `projects/{kebab-case}.md` filename.

For project task search, use `rg "#project/X" tasks.md meetings` from the vault root. For task extraction, prefer `obsidian tasks todo format=json` over ad hoc parsing when the CLI is available; use `rg` only as a fallback.

Append uncategorized tasks to vault-root `tasks.md`; `## inbox` must remain the final section so appends land there. Insert classified tasks directly into the appropriate section.

| Section | Use |
|---------|-----|
| `## projects` | Planning-originated project tasks with a matching `#project/{kebab-case}` tag. |
| `## inbox` | Default. Use this when classification is unclear. |
| `## admin` | University administration, institutional procedures, mandatory training, make-up class procedures. |
| `## teaching` | Classes, student support, grading, teaching preparation, student projects. |

Classification rule: institution or office driven -> `admin`; class or student driven -> `teaching`; unclear -> `inbox`.

Keep `## inbox` as the final section in `tasks.md` so appended tasks naturally land in inbox.

Meeting-originated tasks remain in the meeting note and are not copied to `tasks.md`. Project notes aggregate tasks through their dashboard and must not receive duplicate checkboxes.

Templates:
- `templates/meeting-agenda-template.md`
- `templates/project-note-template.md`

Workflow reference:
- `notes/meeting-project-workflow.md`

## User

Course owner name: 星川 (used in the `owner` frontmatter field under `courses/`).

Working hours: 8:00-16:45, Monday-Friday. Lunch break: 11:30-13:00.

## Git Repository Rules

Because the same repositories may be edited from both a work PC and a home PC, always check remote divergence before edit/commit workflows.

1. Run `git status` first.
2. If clean, run `git pull --rebase`.
3. If dirty, run `git fetch`, inspect divergence, and decide how to preserve existing changes before pulling.
4. On branches without upstream, run `git fetch` and judge divergence manually.
5. Read-only sessions may skip this.

If conflicts happen, do not force push. Resolve with rebase. Decide which machine is authoritative case by case.

## Data Analysis Coding Conventions

See `~/dotfiles/claude/.claude/data-analysis-coding-conventions.md`.

## Research Project Conventions

New research projects combine four locations:

| Purpose | Location |
|---------|----------|
| Working source and git repository | `~/work/projects/{kebab-case-name}/` outside iCloud |
| Submitted artifact archive | `~/Documents/grant/{YYYYMMDD}_{type}_{short-name}/` in iCloud |
| Obsidian project note | Vault `projects/{kebab-case-name}.md` |
| Large data | Outside git, such as external HDD or S3 |

iCloud does not work well with git metadata or agent-local directories. Keep source repositories under `~/work/projects/`; copy only submitted `.docx` and `.pdf` artifacts to `~/Documents/grant/`.

Standard repository structure:

```text
~/work/projects/{name}/
├── CLAUDE.md
├── AGENTS.md
├── README.md
├── .gitignore
├── proposals/{YYYY}-{type}/
│   ├── drafts/
│   ├── 様式/
│   ├── figures/
│   ├── refs/
│   ├── budget/
│   └── output/
├── data/
├── src/
├── notebooks/
├── reports/
└── papers/
```

Workflow:
1. Application writing: treat `proposals/{YYYY}-{type}/drafts/*.md` as the source of truth, generate `.docx` with pandoc, then copy submitted artifacts to `~/Documents/grant/...`.
2. After acceptance: use `data/`, `src/`, and `notebooks/` for research work, and `reports/` and `papers/` for deliverables.
3. GitHub remote: use a private repository for long-lived, multi-device, or eventually shared projects.

`.gitignore` template:

```gitignore
.DS_Store
data/raw/
data/processed/
*.las
*.laz
*.ply
*.pcd
proposals/**/output/
~$*
.venv/
__pycache__/
.Rhistory
.RData
.Rproj.user/
renv/library/
.claude/local/
```

## Obsidian Vault Handling

See `~/dotfiles/claude/.claude/obsidian-workflow.md`.
