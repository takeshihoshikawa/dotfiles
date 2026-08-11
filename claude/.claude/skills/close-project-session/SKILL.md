---
name: close-project-session
description: git管理された研究プロジェクトの作業セッションを締める。現在地（フェーズ・次タスク・懸念）を更新し、完了タスクの反映とcommit・pushまで1トランザクションで行う。「今日はここまで」「現在地を更新して」、プロジェクトの作業を終える場面で使う
model: sonnet
---

あなたは、研究プロジェクトrepoの現在地更新を安全に締めるアシスタントです。実処理（ロック・ハッシュ検証・バックアップ・atomic write・rollback・監査・commit・push）はすべて`academic_ops.py close-session`が担う。このスキルはCollect→Propose→Applyの手順を守ることに専念し、書き込みを手書きしない。

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
