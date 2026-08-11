# 配布用PDF生成（course-qa ステップ8）

今回分の質問をまとめて1枚のPDFにする。pandoc + xelatex + ヒラギノ角ゴシックを使う。

## 8-1. ビルドディレクトリ準備

ヒラギノは `/System/Library/Fonts/` にありfontconfig名で直接引けるため、ファイルコピー不要。

```bash
BUILD=/tmp/course-qa-build
mkdir -p "$BUILD"
```

## 8-2. Markdownソースを生成

`$BUILD/qa.md` を Bash の heredoc で作成する（Write ツールはファイル未読時に使えないため）。
ヘッダーYAMLは以下を**そのまま**使い、`fancyhead[L]` の日付だけ対象日（`YYYY/MM/DD`）に置き換える。

```yaml
---
fontsize: 11pt
mainfont: "Hiragino Kaku Gothic ProN W3"
CJKmainfont: "Hiragino Kaku Gothic ProN W3"
CJKoptions:
  - BoldFont=Hiragino Kaku Gothic ProN W6
linestretch: 1.4
geometry: "a4paper, top=25mm, bottom=25mm, left=25mm, right=25mm"
header-includes:
  - \xeCJKsetup{CJKecglue={}}
  - \usepackage{fancyhdr}
  - \pagestyle{fancy}
  - \fancyhf{}
  - \fancyhead[L]{{配布日 YYYY/MM/DD}}
  - \renewcommand{\headrulewidth}{0pt}
---
```

本文の構成:

```markdown
# {科目} Q&A

**{質問1}**

{回答1}

**{質問2}**

{回答2}
```

- 質問は `**太字**`、回答はその直後の段落
- 複数段落の回答は空行で区切る
- 参考リンクは箇条書きで「タイトル（行末に半角スペース2つで改行）＋ `<URL>`」とし、
  タイトルとURLを併記する:

```markdown
- サステナビリティレポート｜住友林業  
  <https://sfc.jp/information/sustainability/>
```

## 8-3. PDF生成

出力先は**配布日（次回授業）のセッションノートのトピック**に対応する講義フォルダ。

1. 配布日のセッションノートから `topic_id` を取得し、`_meta.md` の `topics[].lecture_folder` で
   対応フォルダ名を引く
2. 出力先: `~/Documents/lecture/{lecture_dir}/{lecture_folder}/QA{YYYYMMDD}.pdf`

```bash
cd /tmp/course-qa-build && pandoc qa.md -o ~/Documents/lecture/{lecture_dir}/{lecture_folder}/QA{YYYYMMDD}.pdf --pdf-engine=xelatex
```

出力ファイル名は `QA{YYYYMMDD}.pdf`（例 `QA20260618.pdf`）。生成後、Read で目視確認し、
フォント・折り返し・日付ヘッダー・URL併記が正しいか確かめる。

**`_meta.md` に `topics:` が無い科目では出力先を解決できない。** その場合はユーザーに
出力先を尋ねる（`topics:` の追加を促してもよい）。

## なぜこの構成か

- **ヒラギノで和欧文を統一**: 和文と英数字を別フォントにするとサイズバランスが崩れる。
  `mainfont` と `CJKmainfont` の両方にヒラギノを指定して統一する。本文 W3・太字 W6
- **`\xeCJKsetup{CJKecglue={}}`**: これがないと日本語と英数字の間に余分なスペースが入る
- **lualatex より xelatex**: どちらでも組めるが、xelatex + xeCJK のこの構成が安定
