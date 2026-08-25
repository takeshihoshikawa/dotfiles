# フェーズ: 解析

解析スクリプトを書く・`scripts/` `config/` `results/` を触るときの責務定義。
ディレクトリ構造そのものは `~/dotfiles/claude/.claude/research-project-conventions.md`、データの保存・同期は
`~/dotfiles/claude/.claude/data-management-policy.md`、コードの書き方は `~/dotfiles/claude/.claude/data-analysis-coding-conventions.md` が正本。

本ファイルが定義するのは**「何をどこに置き、どう成果物へつなぐか」**。

## 最重要原則

**公開成果物を GUI だけで作らない。**

```
results
      ↓
scripts/publication/
      ↓
outputs
```

この再現可能なパイプラインを維持することを最優先とする。LiDAR360・ArcGIS Pro 等での手作業が
避けられない場合は、その工程と設定を `docs/` に記録し、後段は必ずスクリプト化する。

## scripts/ の責務

### pipeline/

論文・成果物で使用する**安定版**パイプライン。番号順に実行できる構成にする。

```
01_preprocess.R
02_train.R
03_predict.R
04_evaluate.R
```

### experiments/

探索的解析・試行錯誤（仮説検証・debug・パラメータ探索）。完成後は `pipeline/` へ昇格する。
試行錯誤を隠さないための領域であり、消さなくてよい。

### publication/

投稿用の図表・最終成果物の生成専用。

```
build_fig1.R
build_fig2.R
build_tables.R
build_all.R
```

GUI による手作業を最小化し、再生成可能な状態を維持する。

### utilities/

同期・変換・検証等の補助（`sync_with_nas.sh`・`sync_with_s3.sh`・フォーマット変換等）。

## config/ の役割

解析条件をコードから分離し、査読対応・再解析時の再現性を確保する。

| ディレクトリ | 内容 |
|---|---|
| `datasets/` | 使用データセット・train/test split・除外条件・グリッドサイズ等 |
| `models/` | モデル定義・ハイパーパラメータ |
| `paths/` | 環境依存パス。**スクリプト中に絶対パスを書かない**（R: `here::here()`、Python: `pathlib.Path`） |

## results と outputs

| | 内容 |
|---|---|
| **results/** | 解析そのものから生成される成果。中間成果・評価結果・学習済みモデル・デバッグ図 |
| **outputs/** | 公開・提出・共有する最終成果物。投稿論文・発表資料・報告書・配布図面 |

`data/outputs/` はデータとしての成果物（配布 CSV・GeoTIFF 等）で、これとは別物
（`~/dotfiles/claude/.claude/data-management-policy.md` 参照）。

## 環境管理

- R: `renv` で依存パッケージを記録
- Python: `uv`（`pyproject.toml`）で依存パッケージを記録
- 乱数シードを必ず固定する（`set.seed()` / `random.seed()`・`np.random.seed()`）

## プロジェクト CLAUDE.md に書くこと

解析フェーズに入ったら、そのプロジェクトの `CLAUDE.md` に最低限これを書く:

- pipeline は安定版のみ、experiments は試行錯誤用、publication は最終成果物生成専用
- 解析条件は `config/datasets/` に定義する
- publication 成果物は `scripts/publication/` から生成する
- データ保存・同期は data-management-policy に従う
- そのプロジェクト固有の逸脱（標準構成と違う点）とその理由

**CLAUDE.md に書かないもの**（作業ログ・未着手の検討事項・所見・懸念の逐次追記）と
記録全般の置き場は `~/dotfiles/claude/.claude/record-management-policy.md` が正本。

## 再利用の判断

同じロジックを 2 つ目・3 つ目のプロジェクトで独立に書きそうになったら、技術層
（センサー・ツール固有で目的非依存な部分）だけを共有リポジトリへ抽出することを検討する。
1 プロジェクトでしか使っていないコードを、将来使うかもしれないからと先回りして共有化しない。
判断基準・実装の型は `~/dotfiles/claude/.claude/cross-project-technology-layer.md`。
