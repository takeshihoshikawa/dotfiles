# Data Management Policy

研究データの**保存・同期・ストレージ運用**のルールを定める正本。

プロジェクトのディレクトリ構造・解析ワークフローは Obsidian vault の `notes/research-project-setup.md`・`notes/research-project-workflow.md` を参照。2026-07 の NAS-SSoT 移行の経緯・調査記録は vault の `notes/storage-migration-plan.md`（凍結済み）、残作業は `notes/storage-migration-backlog.md` を参照。

## 基本方針

- `raw` は変更しない一次データ
- 再生成コストの高い中間生成物は積極的に保存する
- `interim` は消失しても問題ないデータのみを置く一時領域
- `processed` は再利用可能な安定データを長期保存する
- `outputs` は外部共有・GIS配布用の最終データ成果物（論文図表・発表資料等はプロジェクトの `outputs/` へ）

---

## 設計原則

- データの正本（Single Source of Truth）は常に1か所のみとする。
- ローカル作業領域はキャッシュであり、永続保管場所ではない。
- 再生成コスト（計算時間・人手・取得困難性）が高いデータは積極的に保存する。
- 人手による成果物（アノテーション・手修正等）は途中段階でも保存対象とする。
- データ管理ポリシーはストレージ非依存とし、NAS・S3等の実装は運用で決定する。

---

## ストレージの役割

### 永続ストレージ（Single Source of Truth）

研究データの正本を保管するストレージ。

現在の運用では QNAP NAS（SMB マウント `/Volumes/Public`）を永続ストレージとする。

AWS EC2等のクラウド環境を利用する場合は、必要なデータのみS3へ同期し、解析終了後に永続ストレージへ反映する。**S3 は EC2 利用時の受け渡し専用であり、正本として扱わない**（過去に「S3 is authoritative」という前提がコードに残り、古いデータを復元しかけた事例あり。詳細は vaultの `notes/storage-migration-plan.md` Phase 5）。

> [!warning] バックアップの現状リスク（既知・未解消）
> NAS は RAID 構成だが**単一拠点**であり、火災・盗難・広域災害に対しては単一障害点（3-2-1 ルール未達）。
> オフサイトバックアップ（重要 raw の S3 Glacier Deep Archive 等）の導入は検討タスクとして `tasks.md` に登録済み。

---

### ローカル作業領域

解析サーバーやワークステーション上の高速ストレージ。

永続ストレージから必要なデータをコピーして解析を行う。

永続ストレージへ同期済みであれば削除してよい。

---

### Git

ソースコード・論文原稿・設定ファイルなどを管理する。

大容量データは保存しない。

---

## 同期ルール

| データ | 同期方向 | 永続保存 |
|---------|----------|----------|
| raw | 永続ストレージ → ローカル | ○ |
| interim | 同期しない | × |
| processed | ローカル → 永続ストレージ | ○ |
| outputs | ローカル → 永続ストレージ | ○ |

raw のうち「正本が配布元側にある re-fetchable raw」（条件は上記「raw」節参照）は例外として NAS 同期を免除できる。

AWS利用時は、S3を永続ストレージとの受け渡し用として利用する。

同期は各プロジェクトの `scripts/utilities/sync_with_nas.sh`・`sync_with_s3.sh` で行う（標準パターンは vaultの `notes/research-project-setup.md` の「データ同期スクリプト」を参照。`check` デフォルト・`push raw` 拒否等の安全設計を含む）。

---

## ディレクトリ構成

### 永続ストレージ（NAS `/Volumes/Public`）

```text
Public/
├── raw/
│   └── yyyymmdd_region_name/     # 真の生データのみ（計測後に内容が変化しないもの）
├── projects/
│   └── {kebab-case名}/           # プロジェクト単位の解析データ（フラット形）
│       ├── processed/
│       ├── results/
│       └── outputs/
└── archive/
    └── {完了プロジェクト等}/
```

- `projects/{name}/` 直下は **`data/` 層を挟まないフラット形**を標準とする（`processed/`・`results/`・`outputs/`）。
- **例外**: プロジェクト固有の raw（トップレベル `raw/` に置けない事情があるもの。例: compare-lidar の ishikiri 正規化済み点群＝S3 由来の正本で、`original_z` 属性を持つ派生形）は `projects/{name}/raw/` に置いてよい。例外である理由を当該プロジェクトの README 等に記録する。
- プロジェクト名は作業ディレクトリ・GitHub repo と同じ **kebab-case**（vaultの `notes/research-project-setup.md` の命名規約）。
- 旧構成（`data/raw/`・`data/project/`・`results/`・`tools/`）からの仕分けは vaultの `notes/storage-migration-backlog.md` で管理する。

### archive/ の定義

長期保管のみを目的とし、日常の解析からは参照しないデータを置く。

- **完了プロジェクト**: 報告書・論文提出済みで再開予定がないもの（例: `archive/search-stem/`）
- **記録メディア**: 現地調査写真・動画等（`archive/photos/`、`archive/videos/`）

`projects/` → `archive/` への移行基準: プロジェクトが「完全完了」（vaultの `notes/research-project-setup.md` の完了プロジェクト基準と同じ）になった時点で、Obsidian プロジェクトノートのアーカイブと合わせて NAS 側も移動する。移動は非破壊（NAS 内 `mv`）で行い、移動先を Obsidian プロジェクトノートに記録する。

### プロジェクト（ローカル作業領域）

```text
{project_name}/
  data/
    raw/
    interim/
    processed/
    outputs/
```

プロジェクト全体の構造（`scripts/`・`config/`・`results/` 等を含む）はvaultの `notes/research-project-setup.md` が正本。

`raw` は永続ストレージからプロジェクト単位でコピーして使用する。

シンボリックリンクは使用しない。

---

## 各ディレクトリの定義

### raw

計測・取得した元データ。

変更しない immutable データとして扱う。

例

- UAV LiDAR 生点群
- TLS・ALS 元LAS
- UAV画像
- 衛星原データ
- 現地調査CSV
- GNSSログ

> [!note] 間引き・正規化等の処理を経たデータは raw ではない
> 間引き（thinning）バリエーション・高さ正規化済み点群などの派生データは `processed` に属する。
> NAS の `raw/` に混入させない（2026-07 移行時に akiha の間引き 360 ファイルを `projects/` 側へ再分類した経緯あり）。

#### 正本が配布元側にある raw（re-fetchable raw）

JAXA・NIED・GSJ・AMGSD 等、公的機関・組織が恒久的に配布しているデータは raw ではあるが、正本が手元ではなく配布元側にある。この場合バックアップすべきは**バイト列ではなく再取得レシピ**（取得元 URL・バージョンやメッシュコード等の識別子・自動取得スクリプトまたは手動取得手順の記録）である。

条件を満たせば、ローカルの生データコピーは NAS `raw/` への同期義務を免除し、プロジェクト内の作業キャッシュ（例: `data/external/`）に置いてよい。

> [!warning] 免除の条件（すべて満たすこと）
> - 配布元の URL・バージョン（版番号・取得日等）がプロジェクトのドキュメントに記録されている
> - 再取得手順が再現可能（自動スクリプト、または再取得に必要なパラメータを明記した手動手順）
> - 配布元が恒久的な公的・組織的アーカイブである（自分だけが持つ現地調査データ等は対象外、通常の raw 扱い）
>
> いずれかを満たさない場合（例: ダウンロード URL 未記録、手順も スクリプトもない）は、通常の raw と同様に NAS へバックアップする。
>
> 経緯: satellite-thermal プロジェクトで `data/external/` を「再取得可能だからバックアップ不要」として運用していたところ、点検で NIED 地すべりデータの取得元 URL・再取得手順が未記録なことが判明した（JAXA LULC は URL・バージョンとも記録済みで免除条件を満たしていた）。この非対称に気づいたことが本項追加のきっかけ。

---

### interim

一時作業領域。

**消失しても問題ないデータのみ置く。**

例

- 一時tile
- デバッグ出力
- scratch
- 試験的解析

> [!warning]
>
> 手修正・アノテーション途中データは `interim` に置かない。
> 再生成コストの高い処理結果（LiDAR360 での手動処理等）も `interim` ではなく `processed` に置く。
> `interim` は NAS へ同期しない。NAS に置く価値があると感じた時点で、それは `processed` である。

---

### processed

解析・学習・下流処理で再利用する安定データ。

長期保存対象。

再生成に時間・計算資源・人手が必要なデータは、品質確認前でも `processed` に保存する。

例

- Ground classification済み点群
- Normalized point cloud
- CHM
- Segmentation結果
- Rasterized features
- Plot metrics
- 学習用特徴量
- 前処理済みGeoTIFF
- 学習済みモデル
- 手修正・アノテーションデータ

**迷ったら `processed` に保存する。**

---

### outputs

人に見せる最終成果物。

例

- 最終GeoTIFF
- 配布CSV
- GIS成果物

論文図表・PDF・発表資料・報告書はプロジェクトリポジトリの `outputs/` に保存する。

---

## 命名規則とメタデータ

### raw ディレクトリ名

```text
yyyymmdd_region_name
```

例

```text
20260526_koboriya
```

### raw データセットの README（必須）

`raw/yyyymmdd_region_name/` 直下に `README.md` を置き、最低限以下を記録する（新規データセットは取得時に作成。既存 67 件への遡及整備は vaultの `notes/storage-migration-backlog.md` の仕分け作業と合わせて実施）。

- 取得日・場所（地名、可能なら緯度経度または図郭）
- 計測機材・センサー（例: VUX-1LR、機体、飛行高度）
- 座標系（EPSG）・標高基準（絶対標高か地上高か）
- データ形式・点密度等の概要
- 取得者・委託元・利用条件（あれば）
- 関連プロジェクト（`projects/{name}` へのポインタ）

背景: 2026-07 移行時、Z 値が絶対標高か正規化済みかがヘッダー検証をするまで判別できなかった（vaultの `notes/storage-migration-plan.md` 4.2(b-2)）。README があれば防げた。

---

## 削除・保持ルール

移行・整理でデータを削除する場合は以下に従う（2026-07 移行で確立した運用の一般化）。

1. **非破壊が原則**: コピー・移動は「元を残したまま」行い、上書きしない。
2. **検証してから完了とみなす**: コピー後にファイル数・合計サイズ（必要ならサンプルチェックサム）で一致を確認する。
3. **猶予期間**: 削除候補は正本の確定・検証後も 1〜2 週間保持し、削除の都度個別確認のうえ実施する。一括削除はしない。
4. **タスク化によるゾンビ化防止**: 猶予期間に入った削除候補は、その時点で `tasks.md` に `[due:: 猶予期間終了日]`＋`#storage-migration` タグ付きタスク（対象パス・理由・確認方法を明記）を作成する。「後で消す」とノートに書くだけで終わらせない。
5. **生データの正本判定は更新日時で即断しない**: raw は「新しい方が正本」とは限らない（更新日時はコピー時刻に過ぎない）。件数・サイズ突合＋サンプリング内容確認を必須とする。アクティブな作業データは更新日時の明確な差（1週間以上）があれば新しい方を正本候補としてよい。

---

## 運用例

### 通常運用（NAS）

```text
NAS
    ↓
raw をコピー
    ↓
ローカル解析
    ↓
processed / outputs をNASへ同期
```

### AWS EC2利用時

```text
NAS
    ↓
S3
    ↓
EC2
    ↓
S3
    ↓
NAS
```

S3は永続ストレージではなく、クラウド解析時の受け渡し領域として利用する。

### 実装パターン（sync スクリプト）

各プロジェクトの `scripts/utilities/` に `sync_with_nas.sh`（NAS直接同期）・`sync_with_s3.sh`（S3経由・EC2向け）を揃える標準パターンをvaultの `notes/research-project-setup.md` に記載（2026-07-07確定、tree-species-classification・forest-instance-annotationで実装済み）。

---

## 関連

- vaultの `notes/research-project-setup.md` — プロジェクト構造・セットアップ・sync スクリプト標準
- vaultの `notes/research-project-workflow.md` — 解析・論文執筆フェーズの運用
- vaultの `notes/storage-migration-plan.md` — 2026-07 NAS-SSoT 移行の記録（凍結）
- vaultの `notes/storage-migration-backlog.md` — 移行の残作業バックログ
