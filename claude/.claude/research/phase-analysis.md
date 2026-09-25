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

### ツールの既定出力先

**ライブラリが自分で決めた場所へ書くものは、明示的に `results/` へ向け直す。**
上の表は「自分で置き場を選ぶとき」の規則だが、書き先を決めるのが自分とは限らない。
既定のまま走らせると、そのライブラリが選んだ場所——多くはリポジトリのルート——に落ちる。

- 実例: pine-wilt-shizuoka の `lightning_logs/`（PyTorch Lightning の既定）がルート直下に
  でき、`.gitignore` に無いまま**追跡下に入っていた**（2026-09-10 に発見）。
- **Hydra は特に危ない**——既定の出力先が `./outputs/` で、**標準構成の追跡下 `outputs/` と
  衝突する**。落ちた場所が「正しそうに見える」ので、置き場を間違えたことに気づけない。
  `hydra.run.dir` を `results/` 配下へ向ける。
- 保険として skeleton の `.gitignore` に既定名を入れてあるが、**向け直しが本筋**で、
  gitignore は向け忘れが追跡下へ入るのを止めるだけ。

計算機を分けて走らせる場合（実行機で回して手元で図を作る等）は、この向け直しが
**実行機が追跡ファイルを書かないための前提**になる。スクリプトの書き先だけ直しても、
ツールの既定出力先が残っていれば同じことが起きる。

### 実行機（gpu-remote）ではコードを書かない

**gpu-remote の clone では、追跡ファイルも未追跡の設定ファイルも作らない・直さない。**
コードと設定は Mac でコミットして push し、gpu-remote では `git checkout --detach <sha>` で
入れ替えるだけにする。書いてよいのはジョブの出力（`results/` など追跡外）だけ。

- 未追跡の設定ファイルは checkout を止めないので事故に見えないが、それで出した結果は
  **どのコードから出たかを origin から答えられない**——detached checkout を選んだ理由そのものが崩れる。
- 実例: forest-instance-annotation で FF3D の推論設定3本（`custom_configs/*_la03.py`）が
  gpu-remote 上で直接作られ、Mac にも origin にも無いまま使われた（2026-09-24。25日に発見）。
- 試しに1本だけ回したい設定も、Mac で `scripts/experiments/` か `config/` に置いてコミットしてから運ぶ。

決めた経緯と detached checkout の実測は `~/work/projects/admin/docs/execution-routing.md`
（2026-09-10「決めたこと」）が正本。

## 環境管理

- 依存パッケージの管理（**R は renv・Python は uv・システムへ直接入れない**）の正本は
  `data-analysis-coding-conventions` スキルの「環境管理」
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
