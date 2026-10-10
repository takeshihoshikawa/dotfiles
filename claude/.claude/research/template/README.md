# research-project template

研究プロジェクト（科研費・受託研究・自主研究）の立ち上げを自動化するテンプレート。

## 設計方針

- **非破壊**: 既存ファイル・既存ディレクトリは絶対に上書きしない
- **冪等**: 何回実行しても安全
- **部分実行可**: `--name` 以外はすべて省略可能。未指定の変数は `{{VAR}}` プレースホルダのまま残り、後で別サブコマンドで埋められる
- **中途引き継ぎ対応**: ChatGPT・Obsidian・ファイルシステムで先行構築した構想メモのあるディレクトリに対しても、不足分のみ補完する

## 使い方

### 典型例: 空状態からのフル scaffold

```sh
# 1. プロジェクトディレクトリと基本骨格を作成
~/dotfiles/claude/.claude/research/template/init.sh adopt \
  --name forest-thermal-normalization \
  --representative "星川 健史" \
  --project-name "亜熱帯林の熱画像正規化に関する研究"

# 2. 申請書サブツリーを追加
~/dotfiles/claude/.claude/research/template/init.sh add-proposal \
  --name forest-thermal-normalization \
  --year 2027 \
  --grant-type 学術変革B

# 3. Papis 文献ライブラリを登録
~/dotfiles/claude/.claude/research/template/init.sh add-papis-lib \
  --name forest-thermal-normalization

# 4. GitHub private repo に push（申請書を含むなら必須。提出版の正本がここだけになる）
cd ~/work/projects/forest-thermal-normalization
gh repo create --private forest-thermal-normalization --source=. --remote=origin --push

# 5. Obsidian プロジェクトノートを生成（origin の URL が github_url に入る。local_path は常に入る）
~/dotfiles/claude/.claude/research/template/init.sh add-obsidian-note \
  --name forest-thermal-normalization \
  --representative "星川 健史" \
  --affiliation "静岡県立農林環境専門職大学短期大学部"

# 6. project-status.yaml と CLAUDE.md の状態ブロックを作る（waiting で作る。phase-setup.md）
python3 ~/work/projects/admin/scripts/academic_ops.py project migrate \
  --repo ~/work/projects/forest-thermal-normalization --status waiting --phase "申請書執筆" --apply
```

### 典型例: ChatGPT/Obsidian で先行構築した構想を引き継ぐ

```sh
# 構想メモ・自作 CLAUDE.md を既に置いたディレクトリで実行しても、既存ファイルは保護される
~/dotfiles/claude/.claude/research/template/init.sh adopt --name my-existing-project
# → 不足していた .gitignore, README.md, data/, src/ などのみ追加
# → 自作 CLAUDE.md は上書きされない
```

## サブコマンド

| サブコマンド | 役割 |
|---|---|
| `adopt` | プロジェクトディレクトリ作成 or 既存補完。CLAUDE.md・README.md・.gitignore・空ディレクトリ・git 初期化（`main` ブランチ） |
| `add-proposal` | `proposals/{YEAR}-{GRANT_TYPE}/{drafts,様式,figures,refs,budget,output,submitted}/` を追加 |
| `add-papis-lib` | Papis ライブラリを `~/Documents/papis/{name}/`（**リポジトリ外**）に作成 + `~/Library/Application Support/papis/config` に登録 |
| `add-obsidian-note` | Vault `projects/{name}.md` を生成（`local_path` は常に、`github_url` は `--github-url` か origin から埋める） |

`init.sh --help` で詳細オプション確認。

## テンプレート自身の育て方

このディレクトリは **dotfiles リポジトリの一部**（2026-07-29 に subtree で取り込み。以前は
`~/work/templates/research-project` の独立 repo だった）。

**規約を変えたらテンプレも同じコミットで直す。** 別リポだった頃は追随に別コミットが必要で、
片方だけ更新されて腐る事故が起きていた。

### 新しい雛形ファイルを追加するとき

1. `skeleton/` に新規ファイルを追加（必要なら `.template` 拡張子をつけて `{{VAR}}` プレースホルダを使う）
2. `init.sh` の `cmd_adopt` または該当サブコマンドに、その雛形をコピーする 1 行を追加
3. テストプロジェクトで `init.sh adopt` を再実行して動作確認

### `.template` の規約

- `.template` 拡張子のファイル: コピー時に拡張子を剥がして変数置換を適用
- 拡張子なし: そのままコピー（変数置換なし）

## ディレクトリ構成

```
~/dotfiles/claude/.claude/research/template/
├── README.md                    # このファイル
├── init.sh                      # 立ち上げスクリプト本体
├── skeleton/                    # adopt が使うトップレベル雛形
│   ├── CLAUDE.md.template
│   ├── README.md.template
│   ├── .gitignore
│   ├── scripts/utilities/sync_with_{nas,s3}.sh.template  # NAS/S3 同期スクリプト雛形
│   └── data/{raw,interim,processed,outputs}/、src/、notebooks/、
│       scripts/{pipeline,experiments,publication,utilities}/、
│       config/{datasets,models,paths}/、results/、
│       outputs/{papers,presentations,reports}/、docs/（.gitkeep 付き）
├── proposal-skeleton/           # add-proposal が使う雛形
│   └── proposals/{{YEAR}}-{{GRANT_TYPE}}/{drafts,様式,figures,refs,budget,output,submitted}/
└── obsidian-project-note.md.template   # add-obsidian-note が使う
```

### `obsidian-project-note.md.template` と vault のテンプレの関係

vault の `templates/project-note-template.md`（Obsidian から手で作るときに使う）と節・frontmatter の
キーを揃えている。違いは次の2点で、どちらも init.sh が作るのが **git プロジェクトのノートに限られる**
ことから来る（vault 側は `local_path` の無い会議駆動のノートにも使う）。

- `local_path` を最初から埋める（`academic_ops.py` の生成対象になる）
- `status` を `waiting` にする（未完了タスクができるまで `active` にしない。`phase-setup.md`）

片方の frontmatter のキーや節を変えたら、もう片方も揃える。

frontmatter に `{{VAR}}` を置かない。値が無いときプレースホルダが残り、YAML として読めなくなる
（`{{` はフローマッピングの開始）。後から分かる値は空の `key:` にしておき、init.sh が埋める。

## 関連

- グローバル `~/.claude/CLAUDE.md`「研究プロジェクト規約」
- `~/dotfiles/claude/.claude/research-project-conventions.md` — 構造の正本
- `~/dotfiles/claude/.claude/research/phase-setup.md` — 立ち上げフェーズの手順（init.sh の使い方はこちら）
