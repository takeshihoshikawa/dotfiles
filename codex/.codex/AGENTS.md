# Global Codex Settings

## Obsidian Vault

Vault path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/main` (`~/vault` is also available as a symlink; if missing, create it with `ln -sfn "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main" "$HOME/vault"`).

Folder structure:
- `daily/` - daily notes (`YYYY-MM-DD.md`)
- `weekly/` - weekly notes (`weekly-YYYY-MM-DD.md`)
- `courses/{年度}/` - course notes (`YYYY-MM-DD_科目名.md`; academic year starts in April)
- `meetings/` - meeting notes (`YYYY-MM-DD_タイトル.md`)
- `projects/` - project notes. Filenames are kebab-case English, for example `spread1000-application.md`. Research projects may use `projects/{project-name}/` subdirectories for reports and analysis notes.
- `notes/` - misc notes, workflow docs, ideas
- `references/literature/` - literature notes named by citekey
- `notes/goals.md` - long-term goals and direction

## Notes And Tasks

Use Obsidian Tasks for execution management. Put tasks where they arise instead of copying them into a separate task system.

| Type | Location | Format |
|------|----------|--------|
| Project task | Meeting or project note where the task arose | `- [ ] 内容 #project/{kebab-case} [due:: YYYY-MM-DD] [priority:: medium]` |
| Non-project task | `notes/tasks.md` | `- [ ] 内容 [due:: YYYY-MM-DD] [priority:: medium]` |

`#project/{kebab-case}` must match the corresponding `projects/{kebab-case}.md` filename.

For project task search, use `rg "#project/X" projects meetings` from the vault root. For task extraction, prefer `obsidian tasks todo format=json` over ad hoc parsing when the CLI is available; use `rg` only as a fallback.

Append non-project tasks to `notes/tasks.md`.

| Section | Use |
|---------|-----|
| `## inbox` | Default. Use this when classification is unclear. |
| `## admin` | University administration, institutional procedures, mandatory training, make-up class procedures. |
| `## teaching` | Classes, student support, grading, teaching preparation, student projects. |

Classification rule: institution or office driven -> `admin`; class or student driven -> `teaching`; unclear -> `inbox`.

Keep `## inbox` as the final section in `notes/tasks.md` so appended tasks naturally land in inbox.

Meeting note action items are records of decisions, owners, actions, and deadlines. They are not a separate status-management system.

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
