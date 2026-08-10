# Global Codex Settings

## Output Style

- Do not use enclosed alphanumerics or machine-dependent characters such as `①`, `❶`, `㈱`, or `㊤`; they can render poorly in macOS terminals.
- Use ordinary ASCII numbering such as `1.`, `2.`, and `3.`.

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
| Project task | `tasks.md` when planning-originated; meeting note when meeting-originated | `- [ ] 内容 #project/{kebab-case} [task_id:: tsk-12桁hex] [due:: YYYY-MM-DD] [priority:: medium]` |
| Non-project task | `tasks.md` | `- [ ] 内容 [task_id:: tsk-12桁hex] [due:: YYYY-MM-DD] [priority:: medium]` |

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

Every official task has a stable ID in the exact format `tsk-` plus 12 lowercase hexadecimal characters. Generate it with `secrets.token_hex(6)` through `~/work/projects/admin/scripts/academic_ops.py`; never invent, reuse, or remove an ID. Completion keeps the ID and adds `[completion:: YYYY-MM-DD]`. Checkboxes in `templates/`, `sources/`, `daily/`, project notes, or `projects/archive/` are not executable tasks and are reported by audit.

Templates:
- `templates/meeting-agenda-template.md`
- `templates/project-note-template.md`

Workflow reference:
- `notes/meeting-project-workflow.md`

## Project Status Source Of Truth

For git-backed projects, the repository's `project-status.yaml` is the source of truth for execution status. Obsidian Tasks remain the separate source of truth for executable task content and completion.

- `project-status.yaml` contains exactly `schema_version`, `project_id`, `status`, `phase`, `next_task_id`, `concern`, and `updated`.
- `project_id` must equal the repository name, project-note filename, and `#project/...` tag. `active` references an open non-waiting task; `waiting` references null or an open `#waiting` task; `done` references null and permits no open tasks.
- `CLAUDE.md` contains an English control-label generated block delimited by `<!-- BEGIN GENERATED PROJECT STATUS -->` and `<!-- END GENERATED PROJECT STATUS -->`, with `Current Status`, `Phase`, `Next task`, `Concern`, and `Updated`. Project-content values and task text may remain Japanese. Do not edit the block manually. Migration readers must continue accepting legacy Japanese labels.
- Do not duplicate the current phase in README files.
- Obsidian project-note frontmatter fields `current_phase`, `next_task_id`, `next_action`, `concern`, `last_touched`, and task counts are generated by `academic_ops.py`; do not edit them manually when the project note has `local_path`.
- Projects without `local_path`, such as meeting-driven projects, continue to use project-note frontmatter as their status source and must add `next_task_id`.
- Run `academic_ops.py audit` before planning from project state. Do not use a project with an integrity violation as the selected next action.
- Commit a status-only update separately as `chore: 現在地更新`, and push it before leaving the work session.

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

## Data Management

See `~/dotfiles/claude/.claude/data-management-policy.md`.

- Keep large research data out of git.
- Treat the designated NAS, external HDD, S3 bucket, or dedicated volume as the data source of truth for each project.
- Do not assume S3 is the authoritative copy when a project designates NAS as the source of truth.

## Literature Management

Manage papers, PDFs, and bibliographic metadata with Papis.

- General library: `kb` at `~/Documents/papis/kb`
- Project library: `{project}/proposals/{year-type}/refs/papis-lib`
- Papis configuration: `~/Library/Application Support/papis/config`

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
├── data/{raw,interim,processed,outputs}/
├── src/
├── notebooks/
├── scripts/{pipeline,experiments,publication,utilities}/
├── config/{datasets,models,paths}/
├── results/
└── outputs/{papers,presentations,reports}/
```

The full and authoritative structure is documented in Vault note `notes/research-project-setup.md`. Do not retroactively rename older projects that use root-level `reports/` or `papers/`, or `scripts/{explore,paper}`; apply the current structure to new projects and major reorganizations.

Workflow:
1. Application writing: treat `proposals/{YYYY}-{type}/drafts/*.md` as the source of truth, generate `.docx` with pandoc, then copy submitted artifacts to `~/Documents/grant/...`.
2. After acceptance: use `data/`, `src/`, `notebooks/`, and `scripts/` for research work; move analysis products through `results/` and `scripts/publication/` into final deliverables under `outputs/`.
3. GitHub remote: use a private repository for long-lived, multi-device, or eventually shared projects.

## EC2 Compute

- Start EC2 instances temporarily for heavy computation, sync required results to S3, and terminate the instances afterward; treat their home directories as disposable.
- Connect through Tailscale as user `ubuntu`; do not use a public IP.
- For GitHub access from EC2, use SSH agent forwarding with `ssh -A`.

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
