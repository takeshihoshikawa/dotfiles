# フェーズ: 立ち上げ

プロジェクトを新規に作る・既存ディレクトリを標準構成へ引き上げるときの手順。
ディレクトリ構造そのものは `~/dotfiles/claude/.claude/research-project-conventions.md` が正本。

## 自動立ち上げ（init.sh）

`~/dotfiles/claude/.claude/research/template/init.sh` で標準構成を scaffold する。詳細は同ディレクトリの
`README.md`。

**テンプレは本規約と同じ dotfiles にある**（2026-07-29 に `~/work/templates/research-project` から
subtree で移設）。規約を変えたらテンプレも同じコミットで直す。別リポだった頃は追随に別コミットが
必要で、片方だけ更新されて腐る事故が起きていた。

| サブコマンド | 役割 |
|---|---|
| `adopt` | プロジェクトディレクトリ作成 or 既存補完。CLAUDE.md・README.md・.gitignore・空ディレクトリ・git 初期化 |
| `add-proposal` | `proposals/{YEAR}-{GRANT_TYPE}/{drafts,様式,figures,refs,budget,output,submitted}/` を追加 |
| `add-papis-lib` | papis ライブラリを **`~/Documents/papis/{name}/` に**作成 + `~/Library/Application Support/papis/config` に登録（`papis-conventions.md`） |
| `add-obsidian-note` | Vault `projects/{name}.md` を生成 |

### 設計方針（変更するときはここを壊さないこと）

- **非破壊**: 既存ファイル・既存ディレクトリは絶対に上書きしない（`cp -n` 相当）
- **冪等**: 何回実行しても安全
- **部分実行可**: `--name` 以外はすべて省略可能。未指定変数は `{{VAR}}` プレースホルダのまま残り、
  後から別サブコマンドで埋められる
- **中途引き継ぎ対応**: ChatGPT・Obsidian・FS で構想を先行構築した状態のディレクトリにも、
  不足分のみ補完できる

### 典型例

```sh
# 空状態からのフル scaffold
~/dotfiles/claude/.claude/research/template/init.sh adopt --name forest-thermal-normalization --representative "星川 健史"
~/dotfiles/claude/.claude/research/template/init.sh add-proposal --name forest-thermal-normalization --year 2027 --grant-type 学術変革B
~/dotfiles/claude/.claude/research/template/init.sh add-papis-lib --name forest-thermal-normalization
~/dotfiles/claude/.claude/research/template/init.sh add-obsidian-note --name forest-thermal-normalization --phase "申請書執筆"
# 最後に project migrate で project-status.yaml と CLAUDE.md の生成ブロックを作る（下記「プロジェクト CLAUDE.md の最低構成」）

# 構想メモを持つ既存ディレクトリへの補完（既存 CLAUDE.md・00-構想.md 等は保護される）
~/dotfiles/claude/.claude/research/template/init.sh adopt --name my-existing-project
```

> [!note] `add-papis-lib` の取り消しは手作業
> 登録したライブラリを config から外したいときは `~/Library/Application Support/papis/config` を
> 手で編集する（自動削除サブコマンドは未実装）。

## GitHub remote

| 状況 | 推奨 |
|------|------|
| **申請書・論文を含む**（提出物がリポジトリに入る） | GitHub private repo（**必須**） |
| 長期プロジェクト・複数端末・複数人 | GitHub private repo（個人アカウント） |
| 単発・短期・ローカル完結 | ローカル git のみ |

ローカルの `~/work/projects/` は作業領域＝キャッシュであり、**repo の正本は GitHub 側**。
「ローカル git で十分」と判断するのは単発・短期に限る。

提出物を repo で完結させる方針にした結果、**提出版の唯一の正本がリポジトリ**になった。
申請書を含むプロジェクトでローカル git のみにすると、提出物のバックアップが 1 台にしか無くなる。

## プロジェクト CLAUDE.md の最低構成

- プロジェクト概要（1 段落）
- **状態の生成ブロック**（`<!-- BEGIN GENERATED PROJECT STATUS -->` 〜 `<!-- END GENERATED PROJECT STATUS -->`、
  中身は `## Current Status` / `**Phase**` / `**Next task**` / `**Concern**` / `**Updated**`）
  — 正本はリポジトリ直下の `project-status.yaml` で、このブロックはその生成物。**手で書かない**
- ディレクトリ構成（実体に合わせて記述。標準から外れた部分だけ書けばよい）
- 実行方法（コードがある場合）
- Obsidian プロジェクトノートへのリンク、papis ライブラリ名（使う場合）
- コーディング規約への参照（標準と違うことをする場合）

**README にフェーズ欄を置かない**（更新頻度が違い、必ず腐って誤情報になる）。

生成ブロックは `init.sh` では作られない。立ち上げ時に一度だけ次を実行して `project-status.yaml` と
ブロックを作る（テンプレの空の `## 現在地` 見出しがブロックに置き換わる）。以後の更新は
`close-project-session` スキル（`academic_ops.py close-session`）に任せる。

```sh
# 先に add-obsidian-note を済ませておく（vault の projects/{name}.md が無いと失敗する）
python3 ~/work/projects/admin/scripts/academic_ops.py project migrate \
  --repo ~/work/projects/{name} --status waiting --phase "申請書執筆"          # preview
python3 ~/work/projects/admin/scripts/academic_ops.py project migrate \
  --repo ~/work/projects/{name} --status waiting --phase "申請書執筆" --apply
```

`--status active` は**実在する未完了タスクの `--next-task-id` を要求する**。着手タスクを
`tasks.md` に立てる前は `waiting` で作り、タスクができてから `close-session` で `active` へ移す。

状態まわりの規約本体（英語ラベル・手書き禁止・移行中の旧 `## 現在地` の扱い）はグローバル
`CLAUDE.md`「### プロジェクトの状態はリポジトリが正本」を参照。

**書かないもの**と記録全般の置き場は `~/dotfiles/claude/.claude/record-management-policy.md` が正本。

## Obsidian プロジェクトノート

`projects/{kebab-case名}.md` を `templates/project-note-template.md` から作成する
（`init.sh add-obsidian-note` が生成）。「関連リソース」に作業ディレクトリ・GitHub repo・
papis ライブラリのパスを記載し、Obsidian と Claude Code の両側から相互参照可能にする。

**frontmatter の `local_path` を必ず入れる**。`academic_ops.py` はこれの有無で生成対象を判別する
（無いノートは会議駆動として frontmatter 自体が状態の正本になり、機械は触らない）。

## データ同期スクリプトの配置

コード・原稿より大きい生データ・中間生成物・結果は git 管理外とし、`scripts/utilities/` に
2 本のスクリプトを揃える。`init.sh adopt` が雛形
（`~/dotfiles/claude/.claude/research/template/skeleton/scripts/utilities/*.template`）をプロジェクト名・
環境変数プレフィックス置換済みで自動配置する。配置後、`sync_raw()` 内のデータセット対応行を
各プロジェクトで記述する。

| スクリプト | 役割 | 使う場面 |
|---|---|---|
| `sync_with_nas.sh` | ローカル ⟷ NAS を rsync で直接同期 | NAS にアクセスできる作業機。**正本**への読み書き |
| `sync_with_s3.sh` | ローカル ⟷ S3 を `aws s3 sync` で同期 | EC2 など NAS に直接アクセスできない環境向けの一時的な受け渡しのみ |

**共通の設計**（tree-species-classification・forest-instance-annotation で実装済み。
新規プロジェクトはこれを踏襲する）:

- 両スクリプトとも `[check|push|pull] [ターゲット...] [--dryrun] [--delete] ...` の共通 CLI 形状
- `check`（デフォルト）はドライラン。実データを動かす前に必ず確認できる
- **`push raw` はデフォルトで拒否**（`TSC_ALLOW_RAW_PUSH=true` のようなプロジェクト固有の
  環境変数で明示的に許可しない限り）。raw は共有・不変データのため誤上書きを防ぐ
- スクリプト冒頭で `PROJECT_ROOT` を `BASH_SOURCE` から解決し、どこから実行しても安全に動く
- `.DS_Store`・`.gitkeep` は同期除外
- 転送は **SSH 経由の rsync**。CIFS/SMB マウントは使わない（mtime が保持されず差分判定が壊れる）
- ヘッダーコメントに「S3 の `pull` は NAS より古い・欠けている場合がある」という警告と、
  **そのプロジェクト自身の実際の監査結果**を書く。他プロジェクトの監査結果を転用しない
  （事実が食い違う可能性がある）

同期の運用ルール本体は `~/dotfiles/claude/.claude/data-management-policy.md` が正本。
