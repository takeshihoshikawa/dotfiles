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

## Japanese Fonts (XeLaTeX)

Applies to any Quarto target that goes through XeLaTeX — manuscripts and beamer decks alike.
Two traps compound, and both are silent: the document renders, it just renders wrong.

**Trap 1 — a family name lets the engine pick the faces.** `mainfont: "Hiragino Sans"` names a
family with ten weights (W0–W9). XeLaTeX picked **W0 (ExtraLight)** as Regular and **W5** as Bold,
so body text was a hairline and "bold" was barely heavier. Name the faces explicitly.

**Trap 2 — pandoc shrinks the CJK bold.** The template emits
`\defaultfontfeatures{Scale=MatchLowercase}` followed by
`\defaultfontfeatures[\rmfamily]{Scale=1}`. The second line exempts the Latin main font; the
CJK font set by `\setCJKmainfont` is not `\rmfamily`, so it keeps `MatchLowercase` and the
**bold face is scaled down ~3%** to match the regular face's x-height. Naming W3/W6 alone does not
fix this — emphasised text still renders smaller than the body around it. `Scale=1` is required.

```yaml
format:
  beamer:              # or pdf
    pdf-engine: xelatex
    mainfont: "Hiragino Sans W3"
    mainfontoptions:
      - BoldFont=Hiragino Sans W6
    CJKmainfont: "Hiragino Sans W3"
    CJKoptions:
      - BoldFont=Hiragino Sans W6
      - Scale=1        # without this the CJK bold is ~3% smaller than the body
```

Set `mainfont` too, not only `CJKmainfont` — digits and Latin runs inside Japanese prose come
from the roman font, and a deck typically embeds only two or three faces in total.

**Changing faces changes metrics.** Re-run the overflow check afterwards. Beamer discards
content that overflows a frame **without an error**, so a slide that fit before can silently lose
its last line.

**Do not put a bare size command on its own line** under `markdown+hard_line_breaks`. A line
holding only `\small` gets a `\\` appended and fails with `LaTeX Error: There's no line here to
end.` Inline `\small ... \normalsize` compiles, but any source-to-PDF text comparison will report
the line as missing, because the control sequences are in the source and not in the PDF.

Verify mechanically rather than by eye — the difference is a few percent:

```bash
pdffonts out.pdf          # expect the named faces; the unintended weight must be gone
```

Regular and bold must then share the same `Tf` size. Pick a page with ordinary body prose —
a title or section page carries only headings.

```bash
uv run --with pypdf python - <<'EOF'
import collections, re, pypdf
PAGE = 5                       # 0-based; choose a page with body text
p = pypdf.PdfReader("out.pdf").pages[PAGE]
faces = {k: str(v.get_object().get("/BaseFont")) for k, v in p["/Resources"]["/Font"].items()}
stream = p.get_contents().get_data().decode("latin-1")
print(collections.Counter(
    (faces["/" + m[0]].split("+")[-1], m[1])
    for m in re.findall(r"/(F\d+)\s+([\d.]+)\s+Tf", stream)))
EOF
```

An italic fallback may remain: Japanese faces have no italic, so constructs that ask for one
(beamer's `quotation`, for example) fall back to another weight. Harmless, but it explains a
stray face in `pdffonts`.

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
- For Japanese output, `pdffonts` shows the intended faces and regular/bold share a `Tf` size.
