# 研究プロジェクト規約

新規研究プロジェクト（科研費・受託研究・自主研究などのコード/原稿作業を伴うもの）の標準構成。
Claude Code 最適化を前提とし、iCloud と git の不整合を回避しつつ、Word 中心の既存資産
（`~/Documents/grant/`）と整合させる。

本ファイルは**フェーズ非依存の構造の正本**。フェーズ固有の手順は `research/` 配下を参照:

| ファイル | 読むとき |
|---|---|
| `research/phase-setup.md` | プロジェクトを立ち上げる・`init.sh` を使う |
| `research/phase-proposal.md` | 申請書を書く・提出物を作る |
| `research/phase-analysis.md` | 解析スクリプトを書く・`scripts/` `config/` `results/` を触る |
| `research/phase-publication.md` | 論文原稿・投稿用図表を作る |

データの保存・同期は `data-management-policy.md`、複数プロジェクトにまたがる技術資産の再利用は
`cross-project-technology-layer.md` が正本。

## 場所の使い分け（4点セット）

| # | 性質 | 場所 | 同期 |
|---|------|------|------|
| 1 | 作業領域（ソース、git） | `~/work/projects/{kebab-case名}/` | git（必要なら GitHub private repo） |
| 2 | 提出物アーカイブ | `~/Documents/grant/{YYYYMMDD}_{種別}_{略称}/` | iCloud |
| 3 | プロジェクトノート（全体把握） | Obsidian Vault `projects/{kebab-case名}.md` | iCloud（Vault そのもの） |
| 4 | データ実体（巨大ファイル） | NAS・外部 HDD・S3 等 | `data-management-policy.md` に従う |

**なぜ作業領域が非 iCloud か**（提出物だけ iCloud に置く理由）:

- iCloud は `.git/` の部分同期で破損する（`index.lock` の半同期、`(Conflicted Copy)` ファイル）
- `.claude/`・`.venv/`・`node_modules/` 等の隠しディレクトリも同期で詰まる
- Word 一時ファイル `~$*.docx` が git に紛れる
- 多端末同期は **GitHub remote** 経由のほうが信頼性が高い

## 計算リソース（EC2）

- 重い処理は EC2 を一時起動 → 結果を S3 に sync → **terminate**（永続させない／ホームは破棄前提）
- 接続は Tailscale 経由・ユーザー `ubuntu`（パブリックIPは不可）、GitHub push は `ssh -A`

## 標準ディレクトリ構造

```
~/work/projects/{name}/
├── CLAUDE.md            # プロジェクト概要・実行方法・規約・「## 現在地」
├── README.md            # 人間向け説明
├── .gitignore
│
├── proposals/           # 申請書フェーズ
│   └── {YYYY}-{種別}/
│       ├── drafts/      # *.md（真のソース）
│       ├── 様式/        # 配布様式（参照のみ）
│       ├── figures/     # 概念図・予備データ図
│       ├── refs/        # refs.bib（papis から生成）・引用メモ。papis 実体はリポジトリ外
│       ├── budget/      # budget.R, budget.xlsx
│       └── output/      # pandoc 生成物（gitignore）
│
├── data/                # gitignore（実体は NAS。data-management-policy.md 参照）
│   ├── raw/             # 読み取り専用・変更禁止
│   ├── interim/         # 一時領域（消えてよいもののみ、NAS 非同期）
│   ├── processed/       # 再利用する安定データ（NAS 同期対象）
│   └── outputs/         # 外部共有・GIS 配布用データ成果物
│
├── src/                 # 再利用可能な関数（R / Python、テスト対象）
├── notebooks/           # 探索的実験
├── scripts/
│   ├── pipeline/        # 安定版パイプライン（番号付き・順番あり）
│   ├── experiments/     # 探索的解析・試行錯誤（完成後 pipeline へ昇格）
│   ├── publication/     # 投稿用図表・最終成果物の生成専用
│   └── utilities/       # sync・変換・検証等の補助
├── config/
│   ├── datasets/        # 解析条件（データセット・split・除外条件）
│   ├── models/          # モデル・ハイパーパラメータ定義
│   └── paths/           # 環境依存パス（スクリプトに絶対パスを書かない）
├── results/             # 解析から生成される成果（metrics・models・figures 等、gitignore 中心）
├── outputs/             # 公開・提出する最終成果物
│   ├── papers/          # 論文ドラフト・投稿原稿
│   ├── presentations/   # 発表資料
│   └── reports/         # 中間・最終報告書
└── docs/                # 設計メモ・データ入出力仕様等
```

各ディレクトリの**責務**（pipeline/experiments/publication の使い分け、results と outputs の関係）は
`research/phase-analysis.md` を参照。小規模プロジェクトでは不要なディレクトリを作らなくてよい
（必要になった時点で追加する）。

**旧構成からの変更（2026-07-07）**: ルート直下の `reports/`・`papers/` は `outputs/reports/`・
`outputs/papers/` に統合。`scripts/` の分類は旧 `pipeline/explore/paper` から
`pipeline/experiments/publication/utilities` に統一した。**既存プロジェクト
（kawane-als-dbh・portable-lidar-forest-slam 等）は遡及リネームしない。** 新規プロジェクトと
大規模改修時のみ新分類を適用する。

## 命名規約

- 作業ディレクトリ・GitHub repo 名: **kebab-case**（例: `cultural-heritage-digital-twin`）。
  repo 名はディレクトリ名と一致させる
- 提出アーカイブ: `{YYYYMMDD}_{種別}_{略称}`（例: `20260601_学術変革B_文化財DT`）。
  日付は応募/締切日。略称は和文短縮（4〜6 文字目安）
- 申請書サブディレクトリ: `proposals/{YYYY}-{種別}/`（例: `proposals/2026-学術変革B/`）
- 変数名・ファイル名: snake_case（`data-analysis-coding-conventions.md`）

## .gitignore 雛形

**正本は `research/template/skeleton/.gitignore`**（`init.sh adopt` が配置するもの）。
ここに写しを置かない。規約とテンプレに同じ内容を 2 か所持つと必ず片方が腐る
（実際、papis 規則・`data/interim/`・`results/` が規約側にだけ無い状態が発生していた）。

既存プロジェクトを標準構成へ引き上げるときも、skeleton の内容を正として差分を当てる。

## いつ分割するか（monorepo → 別 repo）

最初は monorepo で統一する。以下に該当したら別 repo に切り出す:

- 共同研究者と解析コードを共有する必要が出た（→ `{name}-pipeline` 等で別 repo）
- `src/` が公開ライブラリ化できる成熟度に達した（→ PyPI / CRAN）
- データセット自体を公開する（→ Zenodo / git LFS）

## 完了プロジェクトの扱い

| 状態 | 対応 |
|------|------|
| **条件付き完了**（再開の可能性あり） | vault の `projects/` に置いたまま。frontmatter の `status` を更新する |
| **完全完了**（申請書提出・論文投稿済み等で再開予定なし） | `obsidian move` で `projects/archive/` に移動（wikilink 自動修正）。NAS 側も `archive/` へ非破壊 `mv` し、移動先をプロジェクトノートに記録する |

例: `obsidian move file="paper-writing-efficiency" to="projects/archive/"`

`status` の使い分け（`active` / `waiting` / `done`）と `_bases/active-projects.base` の
ビュー定義は `~/work/projects/admin/CLAUDE.md`「## プロジェクト状態の集約」が正本。
