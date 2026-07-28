# フェーズ: 立ち上げ

プロジェクトを新規に作る・既存ディレクトリを標準構成へ引き上げるときの手順。
ディレクトリ構造そのものは `../research-project-conventions.md` が正本。

## 自動立ち上げ（init.sh）

`~/work/templates/research-project/init.sh` で標準構成を scaffold する。テンプレ自体も git 管理
されており、改善は同レポで commit していく。詳細は `~/work/templates/research-project/README.md`。

| サブコマンド | 役割 |
|---|---|
| `adopt` | プロジェクトディレクトリ作成 or 既存補完。CLAUDE.md・README.md・.gitignore・空ディレクトリ・git 初期化 |
| `add-proposal` | `proposals/{YEAR}-{GRANT_TYPE}/{drafts,様式,figures,refs,budget,output}/` を追加 |
| `add-papis-lib` | papis ライブラリディレクトリ作成 + `~/Library/Application Support/papis/config` に登録 |
| `add-obsidian-note` | Vault `projects/{name}.md` を生成 |
| `add-archive` | `~/Documents/grant/{YYYYMMDD}_{種別}_{略称}/` を作成 |

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
~/work/templates/research-project/init.sh adopt --name forest-thermal-normalization --representative "星川 健史"
~/work/templates/research-project/init.sh add-proposal --name forest-thermal-normalization --year 2027 --grant-type 学術変革B
~/work/templates/research-project/init.sh add-papis-lib --name forest-thermal-normalization
~/work/templates/research-project/init.sh add-obsidian-note --name forest-thermal-normalization --phase "申請書執筆"
~/work/templates/research-project/init.sh add-archive --name forest-thermal-normalization --archive-date 20270601 --short 森林熱画像 --grant-type 学術変革B

# 構想メモを持つ既存ディレクトリへの補完（既存 CLAUDE.md・00-構想.md 等は保護される）
~/work/templates/research-project/init.sh adopt --name my-existing-project
```

> [!note] `add-papis-lib` の取り消しは手作業
> 登録したライブラリを config から外したいときは `~/Library/Application Support/papis/config` を
> 手で編集する（自動削除サブコマンドは未実装）。

## GitHub remote

| 状況 | 推奨 |
|------|------|
| 長期プロジェクト・複数端末・複数人 | GitHub private repo（個人アカウント） |
| 単発・短期・ローカル完結 | ローカル git のみ |

ローカルの `~/work/projects/` は作業領域＝キャッシュであり、**repo の正本は GitHub 側**。
「ローカル git で十分」と判断するのは単発・短期に限る。

## プロジェクト CLAUDE.md の最低構成

- プロジェクト概要（1 段落）
- **`## 現在地`**（`**現フェーズ**:` `**次の一手**:` `**懸念**:` `**更新**:`）
  — gitプロジェクトの現在地の正本。vault の frontmatter へは `project_mirror.py` が転記する
- ディレクトリ構成（実体に合わせて記述。標準から外れた部分だけ書けばよい）
- 実行方法（コードがある場合）
- Obsidian プロジェクトノートと提出アーカイブへのリンク
- コーディング規約への参照（標準と違うことをする場合）

**README にフェーズ欄を置かない**（更新頻度が違い、必ず腐って誤情報になる）。

## Obsidian プロジェクトノート

`projects/{kebab-case名}.md` を `templates/project-note-template.md` から作成する
（`init.sh add-obsidian-note` が生成）。「関連リソース」に作業ディレクトリと提出アーカイブの
パスを記載し、Obsidian と Claude Code の両側から相互参照可能にする。

**frontmatter の `local_path` を必ず入れる**。`project_mirror.py` はこれの有無で転記対象を判別する。

## データ同期スクリプトの配置

コード・原稿より大きい生データ・中間生成物・結果は git 管理外とし、`scripts/utilities/` に
2 本のスクリプトを揃える。`init.sh adopt` が雛形
（`~/work/templates/research-project/skeleton/scripts/utilities/*.template`）をプロジェクト名・
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

同期の運用ルール本体は `../data-management-policy.md` が正本。
