---
name: close-project-session
description: git管理された研究プロジェクトの作業セッションを締める。現在地（フェーズ・次タスク・懸念）を更新し、完了タスクの反映とcommit・pushまで1トランザクションで行う。「今日はここまで」「現在地を更新して」、プロジェクトの作業を終える場面で使う
model: sonnet
---

あなたは、研究プロジェクトrepoの現在地更新を安全に締めるアシスタントです。実処理（ロック・ハッシュ検証・バックアップ・atomic write・rollback・監査・commit・push）はすべて`academic_ops.py close-session`が担う。このスキルはCollect→Propose→Applyの手順を守ることに専念し、書き込みを手書きしない。

## 0. 台帳の点検（状態更新より先に済ませる）

記録管理ポリシー（`~/dotfiles/claude/.claude/record-management-policy.md`）原則3の受け皿。
**陳腐化は経過日数ではなく結果によって起きる**ので、結果が出たこの場で1回だけ見る。
気づいた時点で都度直すと作業の流れが切れ、後日まとめて棚卸しすると判断に要る文脈が失われる。

このセッションで出た結果について、3つだけ問う。

1. **どの主張の判定・根拠が変わったか**（`docs/contribution.md`型の台帳。無いリポは飛ばす）
2. **失効した前提に依存していた計画・タスクはあるか**（`docs/`の論点ファイル・Obsidianタスク）。
   本日のセッションで編集された `references/design/decisions.md`・`docs/worklog.md` 等から
   訂正シグナル語（「訂正」「解除」「見立てを訂正」「前提が変わった」「覆った」等）を含む
   エントリを機械的に拾い出し、そのプロジェクトの open な `#project/{kebab-case}` タスク
   （`project_radar.py`が既に集めている一覧）と並べて提示する。記憶に頼って思い出すのではなく、
   拾い出した候補について「このタスクの記述はまだ有効か」を1つずつ確認してもらう
   （2026-09-02 portable-lidar-forest-slam: UBEC の要否判定が同日中に発注確定→保留へ覆ったのに、
   対応するタスク`tsk-da7d204712bc`の文言が旧判定のまま残った事例で発覚）
3. **新しい教訓はあるか**（`docs/lessons.md`）

- **3つとも「無し」で正しいことが多い。** 無理に埋めない。該当が無ければ1行で「変更なし」と報告して次へ進む。
- **撤回は消さず、取り消し線と日付で残す**（消すと同じ主張が再生産される）。
- **更新すべきかは解析の中身の判断**なので、機械にも第三者にも決められない。
  変更点を提示して**承認を得てから書く**。ユーザーが「無し」と言えばそれで終わり。
- 台帳を書き換えたら、**状態更新とは別のコミット**として先に確定させる。
  ステップ1が「`project-status.yaml`と`CLAUDE.md`以外の未コミット変更」で停止するため、順序が逆だと進めない。

### 語彙の検査（同じ理由でここに置く）

書いた文書に造語（`~/dotfiles/claude/.claude/vocabulary-conventions.md`）が混じっていないかを、
このセッションで書いた場で1回だけ見る。

```bash
python3 ~/dotfiles/claude/.claude/vocab_check.py --repo /absolute/path/to/repo
```

**このスクリプトは1リポずつしか見ない**（2026-09-08。全リポ走査は外した——admin から串刺しにすると
admin のローカルに clone があるリポしか見えず、gpu 機で書いた文書が検査されないまま
「全リポ無音」に見える）。**呼ぶ場所はここだけ。** 既定は3つの状態をそのまま出す
（`--quiet` を付けると違反のときだけ鳴るので、未参加とOKの区別がつかなくなる）。

| 出力 | 意味 |
|---|---|
| `<リポ名>: OK` | 参加していて違反なし。何もしない |
| `<リポ名>: 未参加（.claude/vocab.toml が無い）` | このリポは検査対象外。ユーザーが入れたいと言えば `.claude/vocab.toml` に `baseline` を1行書く |
| `<リポ名>: 禁止語 N 件` ＋ 一覧 | その場で直す |

直すときの制約:

- **意味で分ける語（帯・掃引・利得・製品）は機械置換しない。** 文ごとに何を指しているかを読んで
  書き分ける。判断材料は正本の表の備考欄にある。
- **`.py` はコメントと docstring だけ直す。** 全文置換すると JSON のキー・DataFrame の列名まで
  書き換わり、既にディスクにある結果ファイルと食い違う（2026-09-07 に実際に壊した）。
- 直したら、台帳と同じく**状態更新とは別のコミット**として先に確定させる。

## 1. 収集

1. 対象リポジトリを特定する。曖昧なら確認する。
2. グローバルCLAUDE.mdの「Gitリポでの作業ルール」に従い、divergenceを確認する（`git status`→cleanなら`git pull --rebase`、dirtyなら`git fetch`で状況確認）。
3. 会話・`git diff`・リポジトリ直下の`project-status.yaml`・生成済み`CLAUDE.md`の現在地ブロック・そのプロジェクトのObsidianタスク（`#project/{kebab-case}`）を読む。

`project-status.yaml`と`CLAUDE.md`以外に未コミットの変更があれば、**書き込みをせずに停止**し、通常の作業を先にコミットまたは待避するようユーザーに促す。

## 2. 提案

次を1つのトランザクションとして提示し、承認を得る。

- 新しいフェーズ（`--phase`）
- 完了させるタスクID（`--complete-id`）。「実際の成果」の記述だけから意味的な完了を推測しない
- 次タスクID（`--next-task-id`）またはstatus変更（`--status active/waiting/done`）
- 懸念（`--concern`）
- 更新日

タスクIDは表示するだけで、ユーザーに手入力させない。現在の`next_task_id`を閉じるタスクを含める場合は、必ず承認された次タスクIDかstatus変更を同じトランザクションに含める。

## 3. 適用

### 実行できる機体かを先に確かめる

**`~/work/projects/admin` と `~/vault` の両方が要る。** どちらかが無ければ状態は書けない。

```bash
[ -d ~/work/projects/admin ] && [ -d ~/vault ] && echo "締められる" || echo "退避手順へ"
```

vault が無いと `project_changes()` が `vault/projects/{リポ名}.md` を存在検査なしで読むため
例外で止まる（`academic_ops.py:133`）。`next_task_id` の解決と検査も vault のタスク一覧を要る。
**admin を clone しても解決しない**——足りない半分は vault の方で、Ubuntu 機からは参照できない。

### 退避手順（admin か vault が無い機体）

gpu-remote など計算専用の機体はこちらを使う。**状態は書かず、成果だけ確定させる。**

1. **`CLAUDE.md` の生成ブロックを手で編集しない。** 次に Mac 側で `project render` を通したとき、
   手編集は黙って上書きされる。
2. 変更を commit・push する。コミットメッセージに、次に締めるときへ渡す内容
   （フェーズの進み・次の一手・懸念）を書いておく。**これが引き継ぎの器になる。**
3. ユーザーへ「状態は未更新。Mac 側の次のセッションで締める」と明示して終える。
   締め忘れは Mac の `/morning` が `status_stale` で拾う。
4. 台帳の点検（ステップ0）は**この機体でもやる**。`docs/` の論点ファイル・`docs/lessons.md` は
   リポ内にあり、admin も vault も要らない。結果が出た場に残すのが原則3の趣旨で、
   状態が書けないことと台帳を放置してよいことは別。

承認後、まずpreview実行してから`--apply`を付けて本実行する。

```bash
python3 ~/work/projects/admin/scripts/academic_ops.py close-session \
  --repo /absolute/path/to/repo \
  --status active \
  --phase "..." \
  --next-task-id tsk-xxxxxxxxxxxx \
  --concern "..." \
  [--complete-id tsk-yyyyyyyyyyyy]

python3 ~/work/projects/admin/scripts/academic_ops.py close-session \
  [同じ引数] --apply
```

- auditが失敗した場合、トランザクションはロールバックされる。矛盾点をそのまま報告する。
- commitが成功しpushが失敗した場合、commitは保持されている。リポジトリがahead状態であることを報告し、force-pushや履歴の書き換えはしない。

## 4. 完了報告

完了したタスク、選ばれた次タスク、結果のフェーズ・status、audit結果、commit・pushの結果を簡潔にまとめる。
