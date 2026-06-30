# Quarto Manuscript Rendering Patterns

Use this pattern for Quarto manuscript projects that must produce both PDF and DOCX while keeping the manuscript easy for agents to edit.

## Goal

- Keep manuscript prose separate from rendering code.
- Treat PDF/LaTeX output as the typographic source of truth when it looks better.
- For DOCX, embed PNG images generated from the same LaTeX/gt table instead of maintaining a separate flextable version.
- Keep generated files in predictable locations so they can be overwritten safely.

## Directory Layout

Use this layout under the manuscript directory.

```text
main.qmd
sections/
  00-abstract.qmd
  01-introduction.qmd
  02-materials-methods.qmd
  03-results.qmd
tables/
  derived/      # pipeline-generated analysis CSVs; do not hand-edit
  render/       # table rendering partials included by manuscript sections
  generated/    # PNGs generated for DOCX; safe to overwrite
  *.csv         # small hand-maintained source tables, when needed
figures/
refs.bib
```

## Include Pattern

Keep `main.qmd` mostly YAML plus section includes.

```markdown
{{< include sections/02-materials-methods.qmd >}}
```

Keep section files prose-first. When a table appears, include a table partial instead of placing long R code in the section.

```markdown
{{< include tables/render/table1-lidar-specs.qmd >}}
```

## Table Rendering Pattern

Put each table's label, caption, data loading, formatting, and PDF/DOCX branch in `tables/render/table*.qmd`.

```r
#| label: tbl-example
#| tbl-cap: "Example table caption."
#| echo: false
#| message: false
#| out-width: "100%"

library(gt)
library(here)

source(here("scripts/publication/manuscript_table_helpers.R"))

gt_tbl <- data |>
  gt()

if (knitr::is_latex_output()) {
  gt_tbl
} else {
  png_path <- here("outputs/papers/manuscript/tables/generated/table1.png")
  knitr::include_graphics(gt_to_png(gt_tbl, out_file = png_path))
}
```

Rules:

- Use `gt`/LaTeX as the single table definition when PDF output is better.
- Do not maintain a separate `flextable` version unless editable DOCX tables are explicitly required.
- Put common LaTeX-to-PNG code in a helper script, not in each table partial.
- Write DOCX-only PNGs to `tables/generated/`.

## Helper Responsibilities

A shared helper such as `scripts/publication/manuscript_table_helpers.R` may provide:

- `gt_to_png()`
- LaTeX table extraction from `gt::as_latex()`
- standalone LaTeX compilation with `tinytex::pdflatex()`
- PNG conversion with ImageMagick
- vertical combination of multiple table PNGs

## File Ownership

- `sections/*.qmd`: manuscript prose and short includes only.
- `tables/render/*.qmd`: table rendering code.
- `tables/derived/*`: generated analytical summaries; do not hand-edit.
- `tables/generated/*`: generated render artifacts; safe to overwrite.
- `main.pdf` and `main.docx`: render outputs.

## Verification

After changing rendering structure, run both formats.

```bash
R_PROFILE=/path/to/project/.Rprofile quarto render outputs/papers/manuscript/main.qmd --to pdf
R_PROFILE=/path/to/project/.Rprofile quarto render outputs/papers/manuscript/main.qmd --to docx
```

Then check:

- PDF render succeeds and still uses LaTeX tables.
- DOCX render succeeds and embeds PNG tables.
- `identify tables/generated/*.png` shows non-empty images with plausible dimensions.
- Open or inspect generated PNGs when table titles, spanners, or multi-table layouts changed.
- `git diff --stat` does not show unrelated churn.
