# Global Claude Code Settings

## 出力スタイル

- 囲み数字・丸付き文字（①②③、❶❷❸ など）を使わない。Macのターミナルで表示が崩れて読みにくい。番号は `1.` `2.` `3.` の半角数字で書く
- 同様に ㈱・㊤ などの囲み文字・機種依存文字も避ける

## Obsidian Vault

Vault path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/main`（`~/vault` シンボリックリンクからもアクセス可。未作成なら `ln -sfn "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main" "$HOME/vault"`）

Folder structure:
- `daily/` — daily notes (`YYYY-MM-DD.md`)
- `weekly/` — weekly notes (`weekly-YYYY-MM-DD.md`)
- `courses/registry.md` — 科目マスタ（course_id・科目名・別名・クラス・lecture_dir の対応表）。**科目を参照するときの入口**
- `courses/{course_id}/sessions/` — 授業セッションノート（`YYYY-MM-DD_科目名.md`）。年度はディレクトリでなくファイル名の日付で表す
- `courses/{course_id}/qa/` — 授業Q&A（1問1ファイル）
- `courses/{course_id}/_meta.md` — 科目定義（topics と lecture_folder のマッピング）
- `meetings/` — meeting notes (`YYYY-MM-DD_タイトル.md`)
- `projects/` — project notes（ファイル名は **kebab-case 英語**、例 `spread1000-application.md`）。**`.md` をフラットに置き、サブディレクトリを作らない**（`archive/` を除く）。解析レポート・文献レビュー・照会文書等はリポジトリ側（`docs/`・`outputs/reports/`）に置く
- `notes/` — misc notes, workflow docs, ideas
- `notes/goals.md` — 長期目標・方針（/morningで毎朝表示）
- `tasks.md` — タスク一元管理（vaultルート直下）
- `dashboard.md` — タスクダッシュボード（vaultルート直下）

## ノート・タスク管理の使い分け

| ツール | 役割 |
|--------|------|
| **Obsidian Tasks** | 実行管理（期日・チェック）。各ノートに `- [ ]` チェックボックスとして配置 |
| **Project note** (`projects/`) | **管理**レイヤ。プロジェクト間の見通し（状態・優先順位・リンク・意思決定の記録） |
| **リポジトリの `project-status.yaml`** | **実行**レイヤ。gitプロジェクトの状態の**正本**（status・phase・next_task_id・concern）。`CLAUDE.md` の生成ブロックはその表示 |
| **Meeting note** (`meetings/`) | 会議の文脈・決定事項の記録 |

### プロジェクトの状態はリポジトリが正本（gitプロジェクトのみ）

作業する場所に記録が残るようにするための分担（vault は Ubuntu 機から参照できない）。

- **正本はリポジトリ直下の `project-status.yaml`**（`schema_version` `project_id` `status` `phase`
  `next_task_id` `concern` `updated` のみ）
- `CLAUDE.md` の `<!-- BEGIN GENERATED PROJECT STATUS -->` 〜 `<!-- END GENERATED PROJECT STATUS -->` は
  **生成ブロック**。見出しとラベルは英語（`## Current Status` / `**Phase**` / `**Next task**` /
  `**Concern**` / `**Updated**`）で、値とタスク本文は日本語のままでよい。**手で編集しない**
- vault の frontmatter（`current_phase` / `next_task_id` / `next_action` / `concern` / `last_touched`）も**生成物**。手で書かない
- 書き込みは `~/work/projects/admin/scripts/academic_ops.py`（`project migrate` / `project render` /
  `close-session`）か `close-project-session` スキル経由。ファイルを直接編集しない
- README にフェーズ欄を置かない（更新頻度が違い、必ず腐って誤情報になる）
- 状態だけの更新は `chore: 現在地更新` として**単独でコミットし、離席時に push** する
- `local_path` を持たないプロジェクトノート（会議駆動・未クローン）は従来どおり frontmatter が状態の正本。
  `next_task_id` を必ず持たせる

**移行中**（2026-08-10〜）: `project-status.yaml` があるリポが新方式、無いリポは旧方式の手書き `## 現在地`
（`**現フェーズ**:` `**次の一手**:` `**懸念**:` `**更新**:`）のまま。読み手は当面この日本語ラベルも受理する。
旧方式のリポを移すのは `academic_ops.py project migrate --repo ... --phase ... --apply` を1回
（現在地に状態4項目以外が書いてあると失敗するので、先に作業ログ等へ退避する）。未移行は
`audit` では warning 止まりで、error にはならない。

yaml のスキーマ・audit の整合規則・`project_mirror.py` / `project_radar.py`（互換CLI として存続）の仕様は
`~/work/projects/admin/CLAUDE.md`「## プロジェクト状態の制御（academic_ops.py）」が正本。
**プロジェクト状態まわりのスクリプトを変更する前に必ず読む。**

記録の置き場と失効の管理（何をどこに書くか・結果が出たら台帳を更新する）は
`~/dotfiles/claude/.claude/record-management-policy.md` が正本。**2026-09-25 まで移行期間。**

タスク管理は2系統：

| 系統 | 場所 | 記法 |
|------|------|------|
| **プロジェクトtask** | `tasks.md`（計画起点）または `meetings/`（会議起点）。転記しない | `- [ ] 内容 #project/{kebab-case} [due:: YYYY-MM-DD] [priority:: medium]` |
| **非プロジェクトtask** | `tasks.md`（inbox/admin/teaching） | `- [ ] 内容 [due:: YYYY-MM-DD] [priority:: medium]` |

**プロジェクトノート（`projects/`）にはチェックボックスを置かない。** 実行管理は `tasks.md` に任せる。
gitプロジェクトでは**状態（フェーズ・次タスク・懸念）も本文に書かない**（上記の通りリポジトリが正本）。
プロジェクトノートに残すのは、概要・仮説・関係者・意思決定の記録・ログ・meeting note へのリンクなど、
プロジェクト間で効く文脈に限る。

`#project/{kebab-case}` のプロジェクト名は `projects/{kebab-case}.md` のファイル名と一致させる。  
Claude Code は `rg "#project/X" tasks.md meetings` で横断検索（plugin非依存）。  
定型スキル（morning / weekly-review / daily-report）はタスク取得に `obsidian tasks todo format=json`（vault全体・`meetings/` 含む。各要素 `{status, text, file, line}`、`file` はvaultルート相対）を使い、`rg` はフォールバック。  

タスクの追加先：すべて `tasks.md`（`obsidian append file="tasks"`）

| セクション | 用途 |
|-----------|------|
| `## projects` | `#project/X` タグ付きタスク（計画起点）。meetingノート起点はそちらに残す |
| `## admin` | 大学事務・制度系（義務研修・補講・学内手続き） |
| `## teaching` | 授業・学生対応（授業準備・採点・物品購入・学生PJ） |
| `## inbox` | **デフォルト**。分類に迷ったら。週次レビューで移動 |

判断：「PJタスク（計画起点）」→ projects、「事務局・制度が起点」→ admin、「授業・学生が起点」→ teaching、「迷ったら」→ inbox

注意：`obsidian append` はファイル末尾に追記するため、appendしたタスクは週次レビューで適切なセクションに移動する。  
**tasks.mdのセクション順ルール：`## inbox` を常にファイル末尾に置く。** appendした新規タスクが自動的にinboxに入るようにするため。  
**`## projects` へのタスク追加は `obsidian append` を使わず、Edit で当該セクションに直接書き込む。**（append は inbox 末尾にしか入らないため）

- Meeting noteのアクションアイテムは「決定した事実」の記録（担当者・アクション・期限）。ステータス管理はしない
- Project noteはチェックボックス禁止。タスク重複の温床になるため
- テンプレート: `templates/meeting-agenda-template.md`、`templates/project-note-template.md`
- 打ち合わせ後の手順（meeting note → project note → リポジトリの状態更新）は
  `~/dotfiles/claude/.claude/obsidian-workflow.md`「打ち合わせ → プロジェクト → タスク」を参照

## User

Course owner name: 星川（coursesディレクトリのフロントマター `owner` フィールドで使用）

勤務時間: 8:00–16:45（月〜金）、昼休み 11:30–13:00

## Git リポでの作業ルール

職場 PC と自宅 PC の 2 台で同じリポジトリを並行操作することがあるため、編集・コミット系の作業を始める前に必ず remote の divergence を確認する。

1. まず `git status` で作業ツリーをチェック
2. Clean なら `git pull --rebase`
3. Dirty なら `git fetch` で状況確認 → 既存変更を活かす方針（commit / stash）を決めてから pull
4. Upstream 未設定ブランチでは `git fetch` のみで divergence を判定
5. 読み取り専用セッションでは省略可

衝突が起きた場合は force push せず rebase で解消。両端末のどちらが authoritative かを個別判断する。

## データ分析コーディング規約

データ分析プロジェクト（R/Python）のコーディング規約は `data-analysis-coding-conventions` スキルを参照（scripts/ や src/ を書くときに自動で読み込まれる）。

## データ管理ポリシー

研究データの置き場所は 4 層で判断する。

| 層 | 定義 | 永続保存 |
|----|------|----------|
| `raw` | 計測・取得した一次データ。**変更禁止（immutable）** | ○ |
| `interim` | 一時作業領域。**消失しても問題ないものだけ**置く | × |
| `processed` | 再利用する安定データ。再生成に時間・計算資源・人手がかかるものは品質確認前でも置く | ○ |
| `outputs` | 外部共有・GIS配布用の最終データ成果物 | ○ |

- **迷ったら `processed` に保存する。** 手修正・アノテーション途中データを `interim` に置かない
- 間引き・正規化等の処理を経たデータは raw ではない（`processed` に属する）
- **正本（Single Source of Truth）は常に1か所**。ローカル作業領域はキャッシュであり永続保管場所ではない
- 永続ストレージは QNAP NAS。**S3 は EC2 利用時の受け渡し専用で、正本として扱わない**
  （例外: 公開用バケット `takeshi-research-public` は S3 が正本）
- 削除は非破壊が原則。**ストレージを消す前に、参照している側のコードを grep する**

上記以外（NAS のディレクトリ構成、raw の README 必須項目、CIFS/rsync の落とし穴、
sync スクリプトの標準パターン、削除・保持ルールの詳細、S3 の運用と課金、移行の経緯）は
`~/dotfiles/claude/.claude/data-management-policy.md` が正本。
**NAS/S3 の同期・掃除・raw の受け入れをする前に必ず読む。**

## 文献管理

文献（論文PDF・書誌情報）は papis で管理する。設定: `~/Library/Application Support/papis/config`。

**papis ライブラリはリポジトリの外**（iCloud `~/Documents/papis/{kb|project}/`）。出版社版 PDF を
含むため、リポジトリに入れるとコード公開時に著作物の再配布になる。リポジトリに入るのは papis から
生成した `refs.bib` だけで、**直接編集しない**。

ライブラリの置き方・`refs.bib` の生成と追跡・場所の解決（`src/{pkg}/refs.py`）・引用点検スクリプトの型は
`~/dotfiles/claude/.claude/papis-conventions.md` が正本。
**文献ライブラリを作る・`refs.bib` を触る・引用点検をするときは必ず読む。**

## 研究プロジェクト規約

作業領域（ソース・git）は `~/work/projects/{kebab-case名}/`（**非 iCloud**。iCloud と git/.claude/ は
相性が悪い）。**提出物もリポジトリで完結させる**（`proposals/{YYYY}-{種別}/submitted/` に git 追跡。
2026-07-29 変更。以前の `~/Documents/grant/` は残すが、新規の提出物はそちらへ置かない）。

場所の使い分け・標準ディレクトリ構造・命名規約・EC2 の使い方・.gitignore 雛形・完了時の扱いは
`~/dotfiles/claude/.claude/research-project-conventions.md` が正本。
**新規研究プロジェクトを作る・既存の構造を変えるときは必ず読む。**

フェーズ固有の規約は `~/dotfiles/claude/.claude/` にある（下表のパスはここからの相対）。
**これから行う作業に該当するものを必ず読む**（複数フェーズが並行することもある）:

| ファイル | 読むとき |
|---|---|
| `research/phase-setup.md` | プロジェクトを立ち上げる・`init.sh` を使う |
| `research/phase-proposal.md` | 申請書を書く・提出物を作る |
| `research/phase-analysis.md` | 解析スクリプトを書く・`scripts/` `config/` `results/` を触る |
| `research/phase-publication.md` | 論文原稿・投稿用図表を作る |
| `manuscript-submission-check.md` | **投稿前チェック・監査をする**（8項目の観点表。項目7・8は原稿の外＝文献の本文・解析スクリプトに当たらないと終わらない） |

## Obsidian vault の取り扱い

Vault: `~/vault`（実体は iCloud 上の vault へのシンボリックリンク）。CWD は常にホーム。

| 操作 | 担当 |
|------|------|
| 本文を読む・要約・下書き・本文を編集 | 通常のファイルアクセス（Read / Edit / Grep / Glob）でよい |
| 移動・リネーム・削除・テンプレ作成・daily・properties・tag 操作 | **必ず `obsidian` CLI 経由**（wikilink 保護） |

**vault 内で `mv` / `rm` / `rmdir` を直接使わない**（wikilink が壊れる）。
以前は PreToolUse hook がブロックしていたが 2026-08-06 に廃止したため、**自動では止まらない**。
`obsidian` は起動中の Obsidian アプリのリモコン。未起動時のみ起動する
（`pgrep -x Obsidian >/dev/null || { open -a Obsidian; sleep 2; }`）。

コマンドリファレンス（`obsidian` CLI の各コマンド、タスクの追加・一覧・完了、`rg` フォールバック、
更新順ノート一覧）と、打ち合わせ後の記録手順は
`~/dotfiles/claude/.claude/obsidian-workflow.md` が正本。
**vault を操作する・会議録やプロジェクトノートを書くときは必ず読む。** 学習カットオフ以降に
コマンドが増えている可能性があるため `obsidian help` でも確認する。

## Quarto レンダリングパターン（原稿・スライド）

PDF と DOCX の両方を出す Quarto 原稿プロジェクトの構成・テーブルレンダリング（gt/LaTeX を単一定義とし
DOCX には PNG を埋め込む）・**日本語フォント（XeLaTeX）**・検証手順は
`~/dotfiles/claude/.claude/quarto-manuscript-rendering-patterns.md` が正本。
**Quarto のレンダリング構成を作る・変えるときは必ず読む——原稿だけでなく beamer スライドも。**
**日本語フォントの節は XeLaTeX を通る出力すべてに効く**（既定のままだと本文が極細 W0 で組まれ、
太字が本文より小さくなる。目では気づけないので `pdffonts` と Tf サイズで機械検査する）。
