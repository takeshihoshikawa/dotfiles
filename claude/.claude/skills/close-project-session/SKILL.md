---
name: close-project-session
description: git管理された研究プロジェクトの作業セッションを締める。現在地（フェーズ・次タスク・懸念）を更新し、完了タスクの反映とcommit・pushまで1トランザクションで行う。「今日はここまで」「現在地を更新して」、プロジェクトの作業を終える場面で使う
model: sonnet
---

あなたは、研究プロジェクトrepoの現在地更新を安全に締めるアシスタントです。実処理（ロック・ハッシュ検証・バックアップ・atomic write・rollback・監査・commit・push）はすべて`academic_ops.py close-session`が担う。このスキルは収集→提案→適用の手順を守ることに専念し、書き込みを手書きしない。

**手数を増やさない**（2026-10-11）。過去16回の実行を測ると、スクリプト自体は数秒で、時間は
提案までの5〜10回の読み取りと、台帳と状態で2回に分かれた承認待ちに使われていた。
収集は下の1回の Bash で済ませ、承認は原則1回にする。追加の読み取りは、収集結果だけでは
判断できない項目に限る。

## 1. 収集（1回の Bash）

対象リポジトリを特定する（曖昧なら確認する）。リポのルートで次を**1回で**実行する。

```bash
[ -z "$(git status --porcelain)" ] && git pull --rebase -q
python3 ~/work/projects/admin/scripts/academic_ops.py session-context --repo "$PWD"
python3 ~/dotfiles/claude/.claude/vocab_check.py --repo "$PWD"
```

`session-context` は読み取り専用（fetch はするが pull はしない）で、次を JSON で返す。

| キー | 中身 |
|---|---|
| `can_close` | admin と vault の両方があるか。`false` なら下の「退避手順」へ |
| `unrelated_changes` | `project-status.yaml`・`CLAUDE.md` 以外の未コミット変更。**あれば書き込まずに停止**し、通常の作業を先にコミットするよう促す |
| `ahead` / `behind` | remote とのずれ。behind や diverged なら先に解消する |
| `status` | 今の `project-status.yaml` |
| `since_status_commit` | 前回締めた後のコミット一覧（このセッションでやったことの材料） |
| `next_task` / `open_tasks` | 今の次タスクの本文と、そのプロジェクトの未完了タスク（ID・本文・期日・waiting） |
| `ledgers` | `docs/contribution.md`・`docs/lessons.md` があるか（どちらも既存のリポだけが持つ。新しく作らない） |
| `signal_lines` | 前回締めた後に足された `.md` の行のうち、訂正シグナル語（訂正・解除・前提が変わ・覆っ・撤回）を含むもの |
| `close_command` | 今の値を埋めた `close-session` の引数列（`--apply` なし）。**`--help` で引数を調べ直さない** |

`vocab_check` は既定の出力のまま読む（`--quiet` を付けると、未参加とOKの区別がつかなくなる）。

| 出力 | 意味 |
|---|---|
| `<リポ名>: OK` | 参加していて違反なし。何もしない |
| `<リポ名>: 未参加（.claude/vocab.toml が無い）` | このリポは検査対象外。ユーザーが入れたいと言えば `.claude/vocab.toml` に `baseline` を1行書く |
| `<リポ名>: 禁止語 N 件` ＋ 一覧 | 提案に含めて、その場で直す |

## 2. 台帳の点検（考えるのはここ。問いは提案と同じメッセージで出す）

記録管理ポリシー（`~/dotfiles/claude/.claude/record-management-policy.md`）原則3の受け皿。
**陳腐化は経過日数ではなく結果によって起きる**ので、結果が出たこの場で1回だけ見る。
気づいた時点で都度直すと作業の流れが切れ、後日まとめて棚卸しすると判断に要る文脈が失われる。

このセッションで出た結果について、3つだけ問う。

1. **どの主張の判定・根拠が変わったか**（`CLAIM-MAP.md` か `docs/contribution.md` の台帳。無いリポは飛ばす）
2. **失効した前提に依存していた計画・タスクはあるか**。`signal_lines` の各行と `open_tasks` を並べ、
   影響しそうな組み合わせについて「このタスクの記述はまだ有効か」を**1つずつ問う**。記憶に頼って
   思い出さない（2026-09-02 portable-lidar-forest-slam: UBEC の要否判定が同日中に発注確定→保留へ
   覆ったのに、対応するタスク`tsk-da7d204712bc`の文言が旧判定のまま残った事例で発覚）
3. **判断が変わったか、誤りが見つかったか**。経緯は `docs/decision-log.md` に、本人の判断を「本人」と
   書いて残す。検査にできるものはテストにする。`docs/lessons.md` を持つリポ（pine-wilt・tea）は従来どおり
   そこにも書いてよい。それ以外のリポでは lessons を新しく作らない（2026-10-31。記録管理ポリシー原則1）

- **3つとも「無し」で正しいことが多い。** 無理に埋めない。`signal_lines` が空で、会話にも結果が
  無ければ「台帳: 変更なし」と1行で済ませる。
- **判定案を並べて承認を取らない。** 「まだ有効か」は解析の中身の判断で、機械にも第三者にも
  決められない。候補は問いとして出し、答えを受けてから書く。
- **撤回は消さず、取り消し線と日付で残す**（消すと同じ主張が再生産される）。

語彙の検査で違反があれば、同じメッセージで直し方を示す。直すときの制約:

- **意味で分ける語（帯・掃引・利得・製品）は機械置換しない。** 文ごとに何を指しているかを読んで
  書き分ける。判断材料は正本の表の備考欄にある。
- **`.py` はコメントと docstring だけ直す。** 全文置換すると JSON のキー・DataFrame の列名まで
  書き換わり、既にディスクにある結果ファイルと食い違う（2026-09-07 に実際に壊した）。

## 3. 提案（承認は原則1回）

台帳の問い（あれば）と、状態の更新案を**1つのメッセージ**で出す。状態の更新案は `close_command`
を起点に、変える値だけを差し替える。

- 新しいフェーズ（`--phase`）
- 完了させるタスクID（`--complete-id`）。「実際の成果」の記述だけから意味的な完了を推測しない
- 次の一手: `--next-task-id`（期限があるか他人が絡む）か `--next-action`（repo 内で完結する dev 作業）の
  どちらか一方。または status 変更（`--status active/waiting/done`）
- 懸念（`--concern`）

タスクIDは表示するだけで、ユーザーに手入力させない。現在の`next_task_id`を閉じるタスクを含める場合は、
必ず承認された次タスクIDかstatus変更を同じトランザクションに含める。

台帳の問いへの答えで次タスクや懸念が変わったときだけ、短い2回目の確認をしてよい。

## 4. 適用

### 実行できる機体かを先に確かめる

`can_close` が `false` なら状態は書けない。**`~/work/projects/admin` と `~/vault` の両方が要る。**
vault が無いと `project_changes()` がプロジェクトノートを存在検査なしで読むため例外で止まる。
`next_task_id` の解決と検査も vault のタスク一覧を要る。**admin を clone しても解決しない**——
足りない半分は vault の方で、Ubuntu 機からは参照できない。

### 退避手順（admin か vault が無い機体）

gpu-remote など計算専用の機体はこちらを使う。**状態は書かず、成果だけ確定させる。**

1. **`CLAUDE.md` の生成ブロックを手で編集しない。** 次に Mac 側で `project render` を通したとき、
   手編集は黙って上書きされる。
2. 変更を commit・push する。コミットメッセージに、次に締めるときへ渡す内容
   （フェーズの進み・次の一手・懸念）を書いておく。**これが引き継ぎの器になる。**
3. ユーザーへ「状態は未更新。Mac 側の次のセッションで締める」と明示して終える。
   締め忘れは Mac の `/morning` が `status_stale` で拾う（`chore:` のコミットは作業に数えない）。
4. 台帳の点検（ステップ2）は**この機体でもやる**。`docs/` の論点ファイル・`docs/decision-log.md` は
   リポ内にあり、admin も vault も要らない。結果が出た場に残すのが原則3の趣旨で、
   状態が書けないことと台帳を放置してよいことは別。

### 書く順番

承認を受けたら、次の順で続けて実行する。**preview の実行は挟まない**——`close-session --apply` は
書き込む前に検査し、差分を表示し、書いた後に audit して、失敗すれば戻す。

1. 台帳・語彙の修正があれば書き、**状態更新とは別のコミット**にする（push はしない。
   `close-session` が状態のコミットと一緒に push する）。`close-session` は
   「`project-status.yaml`と`CLAUDE.md`以外の未コミット変更」で止まるので、順序が逆だと進めない。
2. `close_command` に承認された値を入れ、`--apply` を付けて実行する。

```bash
python3 ~/work/projects/admin/scripts/academic_ops.py close-session \
  --repo /absolute/path/to/repo \
  --status active \
  --phase "..." \
  --next-task-id tsk-xxxxxxxxxxxx \
  --concern "..." \
  [--complete-id tsk-yyyyyyyyyyyy] \
  --apply
```

- auditが失敗した場合、状態の変更はロールバックされる。矛盾点をそのまま報告する。
  **手順1の台帳のコミットは残り、remote より ahead になっている**ことも伝える。
- commitが成功しpushが失敗した場合、commitは保持されている。リポジトリがahead状態であることを報告し、
  force-pushや履歴の書き換えはしない。

## 5. 完了報告

完了したタスク、選ばれた次の一手、結果のフェーズ・status、台帳の変更（または「変更なし」）、
audit結果、commit・pushの結果を簡潔にまとめる。
