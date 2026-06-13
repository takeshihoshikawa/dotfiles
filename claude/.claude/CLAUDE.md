# Global Claude Code Settings

## Obsidian Vault

Vault path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/main`（`~/vault` シンボリックリンクからもアクセス可。未作成なら `ln -sfn "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main" "$HOME/vault"`）

Folder structure:
- `daily/` — daily notes (`YYYY-MM-DD.md`)
- `weekly/` — weekly notes (`weekly-YYYY-MM-DD.md`)
- `courses/{年度}/` — course notes (`YYYY-MM-DD_科目名.md`、年度は4月始まり翌年3月終わり)
- `meetings/` — meeting notes (`YYYY-MM-DD_タイトル.md`)
- `projects/` — project notes（ファイル名は **kebab-case 英語**、例 `spread1000-application.md`。研究プロジェクトの場合は `projects/{プロジェクト名}/` サブディレクトリを作成し、解析レポート等を格納）
- `notes/` — misc notes, workflow docs, ideas
- `references/literature/` — 文献ノート（ファイル名はcitekey）
- `notes/goals.md` — 長期目標・方針（/morningで毎朝表示）

## ノート・タスク管理の使い分け

| ツール | 役割 |
|--------|------|
| **Obsidian Tasks** | 実行管理（期日・チェック）。各ノートに `- [ ]` チェックボックスとして配置 |
| **Project note** (`projects/`) | 全体把握。どこまでやったかの確認 |
| **Meeting note** (`meetings/`) | 会議の文脈・決定事項の記録 |

タスク管理は2系統：

| 系統 | 場所 | 記法 |
|------|------|------|
| **プロジェクトtask** | `notes/tasks.md`（計画起点）または `meetings/`（会議起点）。転記しない | `- [ ] 内容 #project/{kebab-case} [due:: YYYY-MM-DD] [priority:: medium]` |
| **非プロジェクトtask** | `notes/tasks.md`（inbox/admin/teaching） | `- [ ] 内容 [due:: YYYY-MM-DD] [priority:: medium]` |

`#project/{kebab-case}` のプロジェクト名は `projects/{kebab-case}.md` のファイル名と一致させる。  
Claude Code は `rg "#project/X" notes/tasks.md meetings` で横断検索（plugin非依存）。  
定型スキル（morning / weekly-review / daily-report）はタスク取得に `obsidian tasks todo format=json`（vault全体・`meetings/` 含む。各要素 `{status, text, file, line}`、`file` はvaultルート相対）を使い、`rg` はフォールバック。  

タスクの追加先：すべて `notes/tasks.md`（`obsidian append file="tasks"`）

| セクション | 用途 |
|-----------|------|
| `## projects` | `#project/X` タグ付きタスク（計画起点）。meetingノート起点はそちらに残す |
| `## admin` | 大学事務・制度系（義務研修・補講・学内手続き） |
| `## teaching` | 授業・学生対応（授業準備・採点・物品購入・学生PJ） |
| `## inbox` | **デフォルト**。分類に迷ったら。週次レビューで移動 |

判断：「PJタスク（計画起点）」→ projects、「事務局・制度が起点」→ admin、「授業・学生が起点」→ teaching、「迷ったら」→ inbox

注意：`obsidian append` はファイル末尾に追記するため、appendしたタスクは週次レビューで適切なセクションに移動する。  
**tasks.mdのセクション順ルール：`## inbox` を常にファイル末尾に置く。** appendした新規タスクが自動的にinboxに入るようにするため。

- Meeting noteのアクションアイテムは「決定した事実」の記録（担当者・アクション・期限）。ステータス管理はしない
- テンプレート: `templates/meeting-agenda-template.md`、`templates/project-note-template.md`
- 詳細: `notes/meeting-project-workflow.md`

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

## 研究プロジェクト規約

新規研究プロジェクトは以下 4 点を組み合わせて構成する。詳細・判断基準は Obsidian Vault の `notes/research-project-setup.md` を参照。

### 場所の使い分け

| 性質 | 場所 |
|------|------|
| 作業領域（ソース、git） | `~/work/projects/{kebab-case名}/`（**非 iCloud**） |
| 提出物アーカイブ | `~/Documents/grant/{YYYYMMDD}_{種別}_{略称}/`（iCloud） |
| Obsidian プロジェクトノート | Vault の `projects/{kebab-case名}.md` |
| データ実体（巨大） | git 管理外（外部 HDD・S3 等） |

**iCloud と git/.claude/ は相性が悪い**ため、ソースは必ず `~/work/projects/` に置く。提出物（.docx, .pdf）のみ iCloud `Documents/grant/` にコピーしてアーカイブする。

### 計算リソース（EC2）

- 重い処理は EC2 を一時起動 → 結果を S3 に sync → **terminate**（永続させない／ホームは破棄前提）
- 接続は Tailscale 経由・ユーザー `ubuntu`（パブリックIPは不可）、GitHub push は `ssh -A`

### 標準ディレクトリ構造

```
~/work/projects/{name}/
├── CLAUDE.md
├── README.md
├── .gitignore
├── proposals/{YYYY}-{種別}/    # 申請書フェーズ（drafts/*.md, 様式/, figures/, refs/, budget/, output/）
├── data/                       # gitignore（実体は外部）
├── src/                        # 解析コード
├── notebooks/                  # 探索的実験
├── reports/                    # 中間・最終報告（採択後）
└── papers/                     # 論文ドラフト（将来）
```

### ワークフロー

1. **申請書執筆**: `proposals/{YYYY}-{種別}/drafts/*.md` を真のソースとし、pandoc で .docx 生成 → 提出版を `~/Documents/grant/...` にコピー
2. **採択後**: `data/`・`src/`・`notebooks/` で本研究、`reports/`・`papers/` で成果物
3. **GitHub remote**: 長期/多端末/将来の共有が見込まれるプロジェクトは private repo を推奨

### .gitignore 雛形


```
.DS_Store
data/raw/
data/processed/
*.las
*.laz
*.ply
*.pcd
proposals/**/output/
~$*
.venv/
__pycache__/
.Rhistory
.RData
.Rproj.user/
renv/library/
.claude/local/
```

## Obsidian vault の取り扱い

@obsidian-workflow.md
