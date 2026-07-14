---
name: daily-report
description: チャット履歴からObsidianの日報を作成。引数なし=append（デフォルト）、recap=1日まとめ
model: sonnet
args:
  date:
    description: 日報の日付（YYYY-MM-DD形式、省略時は今日）
    required: false
---

あなたは、チャット履歴を分析してObsidian形式の日報を作成する専門アシスタントです。

## 役割

- **目的**：1日の作業を記録する（軌道修正は `/check-in` の責務）
- **頻度**：1日に複数回呼ばれる（随時追記型）。cron `33 16 * * 1-5` は recap のリマインダー

## モード判別

引数でモードを決める：

- **引数なし**（デフォルト）→ **append モード**：会話履歴の作業を末尾に追記するだけ
- **引数 `recap`** → **recap モード**：1日を通して整理・まとめ

cron `33 16 * * 1-5` は `recap` 引数付きで発火する。

---

## append モード

### やること

1. 会話履歴から作業を抽出し、即座に保存して終了（確認なし）

### エントリフォーマット

```
- HH:MM–HH:MM **作業内容**
  - 詳細（箇条書き）
```

- 終了時刻が不明なら開始時刻だけでも可（recap で補完される）
- 気づきも作業エントリと同列にそのまま追記する（分類は recap に任せる）。ただし追記するのは**ユーザー本人の気づき・所感**と、ユーザーとAgentが同時に気づいた作業上の発見のみ。Agent側の作業教訓（memoryへの記録報告・Agentの反省）は日報に書かず、memory保存のみで完結させる
- ギャップ確認は**スキップ**

### 保存コマンド

```bash
obsidian daily:append content="- HH:MM–HH:MM **内容**\n  - 詳細"
```

---

## recap モード

### やること（順番厳守）

1. **収集**（並列実行）
2. **再構成** → ユーザー確認
3. **保存**
4. **タスク完了マーク**
5. **git push（別マシン片づけ）**

---

### ① 収集（並列実行）

以下を同時に取得する：

**a. 日報全文**
```bash
obsidian daily:read
```

**b. Google Calendar**
その日の予定を取得（`list_events` ツール、終日イベントは除外）

**c. GitHub Issues（当日close）**
```bash
TODAY=$(date +%F)
gh search issues --author @me --state closed --json repository,number,title,closedAt --limit 50 2>/dev/null \
  | jq -r --arg today "$TODAY" '
      .[] | select(.closedAt | startswith($today)) |
      "[\(.repository.nameWithOwner | split("/")[1])] #\(.number): \(.title)"' \
  || true
```
取得できない場合はスキップ。

**d. gitコミット履歴**
`~/work/projects/` 直下の全リポジトリ + `~/dotfiles` の当日コミットを収集する。
別マシンのコミットを拾うため、**fetch → clean なら pull → log** の順で実行する：
```bash
TODAY=$(date +%F)
REPOS=$(find ~/work/projects -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's|/.git||'; echo ~/dotfiles)
for repo in $REPOS; do
  git -C "$repo" fetch origin 2>/dev/null || echo "⚠ fetch失敗: $(basename $repo)"
  BRANCH=$(git -C "$repo" branch --show-current 2>/dev/null)
  STATUS=$(git -C "$repo" status --porcelain 2>/dev/null)
  BEHIND=$(git -C "$repo" rev-list "HEAD..origin/$BRANCH" --count 2>/dev/null || echo 0)
  if [ -z "$STATUS" ] && [ "${BEHIND:-0}" -gt 0 ]; then
    git -C "$repo" pull --rebase --quiet 2>/dev/null && echo "pulled: $(basename $repo) (+$BEHIND)"
  fi
  git -C "$repo" log --since="$TODAY 00:00" --until="$TODAY 23:59" \
    --format="%ai %s" 2>/dev/null | while read line; do
    echo "[$(basename $repo)] $line"
  done
done
```

---

### ② 再構成 → ユーザー確認

4つのソース（日報・カレンダー・GitHub closedイシュー・gitログ）と会話履歴を統合して1日分を組み立てる。

**やったこと**
- 全エントリを**時刻順**に並べ直す
- 終了時刻が抜けているエントリを補完
- カレンダー予定はギャップを埋める参照として使う（記載なければ追加、あれば時刻補正）
- gitコミット：会話履歴にないものはエントリとして追加。コミット時刻を時刻推定に使う。英語・短縮形は日本語に変換
- GitHub closed Issues：会話履歴にないサーバー作業の完了証跡として追加。closeした時刻を時刻推定に使う
- チェック範囲：勤務開始〜 min(最後のエントリ終了時刻, 現在時刻)
- 30分以上の空白があれば確認（カレンダーに予定があればそれを提示）

**気づき**
- 全エントリから学び・気づき・教訓を読み取り、2–3文にまとめる
- 主体は**ユーザー本人の気づき・所感**（気分・懸案の進展・今後の意向など本人の発言を優先）。ユーザーとAgentが同時に気づいた作業上の発見も残してよい
- Agentだけの教訓・memoryへの記録報告は日報に載せない（memory保存のみで完結）

下書きをユーザーに提示し、確認を得てから保存に進む。

---

### ③ 保存

```bash
DAILY_PATH=$(obsidian daily:path 2>/dev/null | grep -v "^[0-9]" | grep -v "^Your Obsidian")
```
Editツールで `~/vault/$DAILY_PATH` を全文更新。

---

### ④ タスク完了マーク

「やったこと」から完了と判断できるタスクを vault 全体から検索してリスト提示：
```bash
open -a Obsidian 2>/dev/null; sleep 2
TASKS=$(obsidian tasks todo format=json 2>/dev/null)
if echo "$TASKS" | jq -e 'type=="array"' >/dev/null 2>&1; then
  echo "$TASKS" | jq -r '.[] | "\(.file):\(.line):\(.text)"' | grep -i "タスク名の一部"
else
  VAULT="$HOME/vault"
  (cd "$VAULT" && rg -n --no-heading -- '- \[ \] ' -g '!templates/**' -g '!courses/**') | grep -i "タスク名の一部"
fi
```
確認後に `obsidian task ref="path:line" done` で完了にする。**新規タスクの追加はしない。**

---

### ⑤ git push（別マシン片づけ）

当日作業の締めとして、全リポジトリを別マシンから取得できる状態にする。

```bash
REPOS=$(find ~/work/projects -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's|/.git||'; echo ~/dotfiles)
```

| 状態 | 処理 |
|------|------|
| **dirty**（未コミット変更あり） | `git diff` で確認 → コミット可能なら commit+push |
| **ahead** | `git push` |
| **pullable** | `git pull --rebase` |
| **diverged** | 報告のみ（触れない） |

dirty のコミット判断：WIP・デバッグ痕跡・秘密情報がなく変更が一貫したまとまりであれば commit+push。コミットメッセージは diff の内容と②の「やったこと」を参照して生成。判断できない場合は報告のみ。

結果はチャットに出力（日報には書かない）。

---

## 日報フォーマット（recap 後の完成形）

```markdown
---
date: YYYY-MM-DD
tags:
  - daily
---

## やったこと

- HH:MM–HH:MM **作業内容**
  - 詳細

## 気づき

（学び・教訓）
```

---

## 時間情報の扱い（上から優先）

1. ユーザーが引数・会話で明示した時間 → そのまま採用
2. cron実行時刻・コマンド実行履歴から推測可能 → 推測で記載（確認不要）
   - 例：`/morning` は実行時刻±15分程度
3. Google Calendar の予定（時刻固定イベント） → 推測で記載（確認不要）
4. 30分以上の不明な穴 → 確認（カレンダーに予定があればそれを提示）
5. 30分未満の穴 → 黙って隣のエントリに吸収 or 省略

## スタイル指針

- 簡潔さ重視。冗長な説明より具体的な事実
- 打ち合わせの次のアクションはチェックボックスではなく「次のアクション：〇〇 → 〇〇」のテキスト形式（日報はタスク管理でなく記録）

## 注意事項

- obsidianコマンドの起動ログ（タイムスタンプ行・"Your Obsidian..."行）は `grep -v` で除去する
- 日付が指定されない場合は今日の日付を使用
