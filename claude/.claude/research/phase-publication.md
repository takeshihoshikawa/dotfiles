# フェーズ: 執筆・投稿

論文原稿・投稿用図表を作り、投稿するまでの手順。
解析側（`results/` → `scripts/publication/`）の責務は `phase-analysis.md` が正本。

## 置き場所

| | 内容 |
|---|---|
| `outputs/papers/` | 論文ドラフト・投稿原稿（Quarto プロジェクト一式） |
| `outputs/presentations/` | 発表資料 |
| `outputs/reports/` | 中間・最終報告書 |

原稿は git 管理する。図表は `scripts/publication/` から生成し、**手で置かない**。

## 文献

papis ライブラリは**リポジトリの外**（iCloud `~/Documents/papis/{project}/`）。リポジトリに入るのは
生成した `outputs/papers/{原稿名}/refs.bib` だけで、直接編集しない。申請書フェーズと扱いは同じで、
出力先だけが違う。引用点検スクリプト（`citation_claim_audit.py` 等）の型も含め
`~/dotfiles/claude/.claude/papis-conventions.md` が正本。**投稿前チェックの前に読む。**

## Quarto を使う

論文執筆は Quarto を推奨する。解析結果を直接参照することで、

- 数値の転記ミス
- 図の差し替え漏れ
- 再解析時の不整合

を防げる。PDF と DOCX の両方を出す構成（原稿は prose 中心、テーブルは gt/LaTeX を単一定義とし
DOCX には PNG を埋め込む）の作り方・検証手順は `~/dotfiles/claude/.claude/quarto-manuscript-rendering-patterns.md` が正本。
**Quarto 原稿のレンダリング構成を作る・変えるときはそちらを読む。**

## 投稿前チェック

最終品質確認の観点表は `~/dotfiles/claude/.claude/manuscript-submission-check.md`（8項目・依頼前チェック・出力形式）。
**投稿前チェックをするときは必ず読む。**

特に注意する点:

- 項目 1〜6 は原稿を読めば終わるが、**項目 7・8 は原稿の外（文献の本文・解析スクリプト）に
  当たらないと終わらない**。依頼前に入力を揃える。ここを省くと、通ったように見えて何も
  検証されていない結果になる
- 引用は書誌の形式チェックで終わらせない。**題名 → 要旨 → 本文 PDF の3段階**で、主張との対応を
  照合する（項目7）
- AI には研究内容・結果を変更させず、修正すべき点の抽出と提案のみを行わせる

## 共著者とのやりとり

共著者コメント待ちで並行作業も無い状態になったら、vault のプロジェクトノートの `status` を
`waiting` にする（`~/dotfiles/claude/.claude/research-project-conventions.md`「完了プロジェクトの扱い」参照）。

## 投稿後・受理後

- 投稿版・受理版は `outputs/papers/` に残す
- 論文が出たら vault の `curriculum-vitae.md` の業績欄を更新する
- 再開予定が無くなった時点で、プロジェクトノートを `projects/archive/` へ、NAS 側を `archive/` へ移す
