# Obsidian ワークフロー

## Vault

Vault: `~/vault`（実体: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/main` へのシンボリックリンク）

未作成なら `ln -sfn "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main" "$HOME/vault"` で作成する。Read/Edit/rg 等の直接アクセスは長い iCloud パスでなく `~/vault/...` を使う。

`additionalDirectories` でホームから起動したまま vault 全体に読み書きできる。CWD は常にホーム。

## 役割分担

| 操作 | 担当 |
|------|------|
| 本文を読む・要約・下書き・本文を編集 | 通常のファイルアクセス（Read / Edit / Grep / Glob）でよい |
| 移動・リネーム・削除・テンプレ作成・daily・properties・tag 操作 | **必ず `obsidian` CLI 経由**（wikilink 保護） |

vault 内で `mv` / `rm` / `rmdir` を直接使わない（PreToolUse hook でブロックされる）。

## 前提

- `obsidian` は起動中の Obsidian アプリを操作するリモコン。未起動でも自動起動するが、完了を待つ。
- **未起動対策**: `open -a Obsidian 2>/dev/null; sleep 2 &&` を先頭に置くと確実。
- 引数は `key=value` 形式。不安なら `obsidian help <command>` で確認。
- 学習カットオフ以降にコマンドが追加されている可能性あり。`obsidian help` で一覧確認してから使う。

## 基本コマンド

```bash
obsidian daily                                           # 今日の daily note を開く
obsidian daily:append content="..."                      # daily note に追記
obsidian daily:read                                      # daily note を読む
obsidian read file="ノート名"                             # 指定ノートを読む
obsidian search query="検索語"                            # vault 全文検索
obsidian create path="folder/note.md" content="..."      # ノート作成（path= でフォルダ含む）
obsidian create path="folder/note.md" template=テンプレ名 # テンプレから作成
obsidian files sort=modified limit=5                     # 更新順ノート一覧
obsidian move file="ノート名" to="移動先フォルダ/"         # 移動/リネーム（リンク自動修正）
obsidian delete file="ノート名"                           # 削除
obsidian property:set file="ノート名" name="key" value="val"  # プロパティ設定
obsidian tags counts                                     # タグと頻度
```

`file=` / `name=` はwikilink形式（ファイル名のみ、スラッシュ不可）。パスを含む場合は `path=`。

## タスク管理

### 追加

`append` は末尾追記のみ。追加先が決まっていれば事前のファイル確認不要。追加先はCLAUDE.mdの「タスク追加先」を参照。

```bash
open -a Obsidian 2>/dev/null; sleep 2 && \
obsidian append file="tasks" content="- [ ] タスク [due:: YYYY-MM-DD] [priority:: low]"
```

### 一覧（`obsidian tasks` 複数形）

```bash
obsidian tasks todo                          # 未完タスク（テキスト）
obsidian tasks todo verbose                  # ファイル別グループ + 行番号
obsidian tasks todo format=json              # JSON配列（各要素 status/text/file/line。file はvaultルート相対、text は"- [ ]"込み）
obsidian tasks done                          # 完了タスク
obsidian tasks total                         # 件数のみ
obsidian tasks daily todo                    # 今日のdailyノートのみ
obsidian tasks path="tasks.md" todo          # 特定ファイル（vaultルート相対、フォルダ不可）
obsidian tasks file="tasks" todo             # 特定ファイル（ファイル名のみ）
obsidian tasks active todo                   # 現在Obsidianで開いているファイル
```

templates/ と courses/ はチェックボックス不使用（普通のリスト）。

定型スキル（morning / weekly-review / daily-report）は未完/完了タスクの取得に `obsidian tasks todo|done format=json`（vault全体・`meetings/` 配下の `#project/` タスクも拾う）を使い、due/priority/#waiting/#project の絞り込みは取得後の text 処理で行う。`rg` は Obsidian 未起動・フォーマット変更時のフォールバック。

キーワード・期日検索は `rg` を使う。**フルパス渡しだとglobが効かない**ため `cd` してから実行：

```bash
VAULT=~/vault   # 実体は iCloud 上の vault へのシンボリックリンク
(cd "$VAULT" && rg "\- \[ \]" -g '!templates/**' | rg "キーワード")
(cd "$VAULT" && rg -n "\- \[ \] .*due:: YYYY-MM-DD" -g '!templates/**')
```

### 完了（`obsidian task` 単数形）

`tasks` のJSON出力の `file` フィールドをそのまま `path=` や `ref=` に使える。

```bash
obsidian task path="tasks.md" line=10 done     # 完了
obsidian task path="tasks.md" line=10 toggle   # トグル
obsidian task ref="tasks.md:10" done           # ref形式（path:line）も可
```

`file=`（ファイル名のみ）と `path=`（vaultルート相対、フォルダ不可）の違いはタスク一覧と同様。

## 定型ワークフローとの分担

daily-report / check-in / morning のような繰り返し処理は各スキル内に obsidian コマンドを直書きする。本ルールは ad-hoc な作業向け。
