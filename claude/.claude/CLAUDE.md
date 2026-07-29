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
| **リポジトリの `CLAUDE.md`「## 現在地」** | **実行**レイヤ。gitプロジェクトの現在地の**正本**（現フェーズ・次の一手・懸念） |
| **Meeting note** (`meetings/`) | 会議の文脈・決定事項の記録 |

### プロジェクトの「現在地」はリポジトリが正本（gitプロジェクトのみ）

作業する場所に記録が残るようにするための分担（vault は Ubuntu 機から参照できない）。

- **人が書くのはリポジトリの `CLAUDE.md`「## 現在地」ただ1箇所**（`**現フェーズ**:` `**次の一手**:` `**懸念**:` `**更新**:`）
- vault の frontmatter（`current_phase` / `next_action` / `concern` / `last_touched`）は
  `~/work/projects/admin/scripts/project_mirror.py` が転記する**生成物**。手で書かない
- README にフェーズ欄を置かない（更新頻度が違い、必ず腐って誤情報になる）
- 現在地を更新したら `chore: 現在地更新` として**単独でコミットし、離席時に push** する

転記の対象判別（`local_path` の有無）・陳腐化ガード等の仕様は `~/work/projects/admin/CLAUDE.md`
「## プロジェクト状態の集約」が正本。**`project_mirror.py` / `project_radar.py` を変更する前に必ず読む。**

タスク管理は2系統：

| 系統 | 場所 | 記法 |
|------|------|------|
| **プロジェクトtask** | `tasks.md`（計画起点）または `meetings/`（会議起点）。転記しない | `- [ ] 内容 #project/{kebab-case} [due:: YYYY-MM-DD] [priority:: medium]` |
| **非プロジェクトtask** | `tasks.md`（inbox/admin/teaching） | `- [ ] 内容 [due:: YYYY-MM-DD] [priority:: medium]` |

**プロジェクトノート（`projects/`）にはチェックボックスを置かない。** 実行管理は `tasks.md` に任せる。
gitプロジェクトでは**現在地（現フェーズ・次の一手・懸念）も本文に書かない**（上記の通りリポジトリが正本）。
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
- 打ち合わせ後の手順（meeting note → project note → リポジトリの「## 現在地」）は
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

@data-analysis-coding-conventions.md

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
相性が悪い）。提出物（.docx, .pdf）のみ iCloud `~/Documents/grant/` にコピーしてアーカイブする。

場所の使い分け・標準ディレクトリ構造・命名規約・EC2 の使い方・.gitignore 雛形・完了時の扱いは
`~/dotfiles/claude/.claude/research-project-conventions.md` が正本。
**新規研究プロジェクトを作る・既存の構造を変えるときは必ず読む。**

フェーズ固有の規約は `~/dotfiles/claude/.claude/research/` にある。**これから行う作業に該当する
ものを必ず読む**（複数フェーズが並行することもある）:

| ファイル | 読むとき |
|---|---|
| `research/phase-setup.md` | プロジェクトを立ち上げる・`init.sh` を使う |
| `research/phase-proposal.md` | 申請書を書く・提出物を作る |
| `research/phase-analysis.md` | 解析スクリプトを書く・`scripts/` `config/` `results/` を触る |
| `research/phase-publication.md` | 論文原稿・投稿用図表を作る |

## Obsidian vault の取り扱い

Vault: `~/vault`（実体は iCloud 上の vault へのシンボリックリンク）。CWD は常にホーム。

| 操作 | 担当 |
|------|------|
| 本文を読む・要約・下書き・本文を編集 | 通常のファイルアクセス（Read / Edit / Grep / Glob）でよい |
| 移動・リネーム・削除・テンプレ作成・daily・properties・tag 操作 | **必ず `obsidian` CLI 経由**（wikilink 保護） |

**vault 内で `mv` / `rm` / `rmdir` を直接使わない**（PreToolUse hook でブロックされる）。
`obsidian` は起動中の Obsidian アプリのリモコン。未起動時のみ起動する
（`pgrep -x Obsidian >/dev/null || { open -a Obsidian; sleep 2; }`）。

コマンドリファレンス（`obsidian` CLI の各コマンド、タスクの追加・一覧・完了、`rg` フォールバック、
更新順ノート一覧）と、打ち合わせ後の記録手順は
`~/dotfiles/claude/.claude/obsidian-workflow.md` が正本。
**vault を操作する・会議録やプロジェクトノートを書くときは必ず読む。** 学習カットオフ以降に
コマンドが増えている可能性があるため `obsidian help` でも確認する。

## Quarto 原稿レンダリングパターン

PDF と DOCX の両方を出す Quarto 原稿プロジェクトの構成・テーブルレンダリング（gt/LaTeX を単一定義とし
DOCX には PNG を埋め込む）・検証手順は `~/dotfiles/claude/.claude/quarto-manuscript-rendering-patterns.md`
が正本。**Quarto 原稿のレンダリング構成を作る・変えるときは必ず読む。**
