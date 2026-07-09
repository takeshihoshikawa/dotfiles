# データ分析コーディング規約

## コメント

- コードから自明なことは書かない
- **なぜ**その処理をするかを書く（what ではなく why）

## 関数化

- 2回以上使う処理、または10行以上の複雑な処理は関数化する
- 可視化・出力コードは再利用しない場合は関数化しない

## プロジェクトをまたぐ再利用

- 同じロジックを2つ目・3つ目のプロジェクトで独立に書きそうになったら、技術層（センサー・ツール固有で目的非依存な部分）だけを共有リポジトリへ抽出することを検討する
- 1プロジェクトでしか使っていないコードを、将来使うかもしれないからと先回りして共有化しない（上記「関数化」と同じ閾値をプロジェクト間にも適用する）
- 判断基準・実装の型（コミット固定・言語ごとのリポジトリ分割・provenance.md・凍結の作法）は `~/dotfiles/claude/.claude/cross-project-technology-layer.md` を参照（vaultはUbuntu機から参照できないためdotfiles側に置く）

## ファイル構成

研究プロジェクトの完全な標準構造は Obsidian vault の `notes/research-project-setup.md` が正本。本規約に関わる骨格は以下。

```
project/
├── data/
│   ├── raw/          # 読み取り専用・変更禁止
│   ├── interim/      # 一時領域（消えてよいもののみ）
│   ├── processed/    # 加工済み・再利用する安定データ
│   └── outputs/      # 外部共有用データ成果物
├── scripts/
│   ├── pipeline/     # 安定版パイプライン（番号付き・順番あり）
│   ├── experiments/  # 探索的解析・試行錯誤（完成後 pipeline へ昇格）
│   ├── publication/  # 論文・投稿用の最終出力（表・図）
│   └── utilities/    # sync・変換・検証等の補助
└── src/              # 再利用可能な関数（R / Python）
```

旧分類 `explore/`→`experiments/`、`paper/`→`publication/`（2026-07-07 統一）。既存プロジェクトのディレクトリは遡及リネームしない。

## スクリプト命名

- `pipeline/` 内は番号付きで実行順を明示：`01_preprocess.R`、`02_model.R`
- `experiments/`・`publication/`・`utilities/` 内は内容で命名：`point_statistics.R`、`build_fig1.R`

## パス管理

- 絶対パスを使わない
- プロジェクトルートからの相対パスで統一
  - R：`here::here()` を使用
  - Python：`pathlib.Path` を使用

## 再現性

- 乱数シードを必ず固定する
  - R：`set.seed()`
  - Python：`random.seed()` / `np.random.seed()`
- 生データ（`data/raw/`）は変更禁止。加工後は `data/{interim,processed}/` に保存

## 環境管理

- R：`renv` で依存パッケージを記録
- Python：`uv` で依存パッケージを記録

## AIエージェントとの協働

### コード設計

- 1スクリプト200行を目安にする（コンテキストウィンドウの節約）
- グローバル変数を使わない。関数の入出力を明示する
- 副作用を分離する：データ読み込み・処理・書き出しをそれぞれ関数として分ける

### ドキュメント

- `src/` 内の関数にはドキュメントを必ず書く
  - R：`roxygen2`（`@param`、`@return`）
  - Python：型ヒント＋docstring
- コメントの「なぜ」を徹底する（AIは背景情報なしにコードを生成するため特に重要）
- 命名規則を統一する：変数名・ファイル名は snake_case

### テスト

- `src/` 内のコア関数はテストを書く
  - R：`testthat`
  - Python：`pytest`
- AIが生成したコードは必ずテストで検証してからマージする

### プロジェクト指示ファイル

- プロジェクトルートに `CLAUDE.md` を置き、この規約の要点とプロジェクト固有の指示を記述する