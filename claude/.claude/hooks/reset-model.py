#!/usr/bin/env python3
"""セッション終了時に settings.json の model キーを削除する（SessionEnd フック）。

狙いは2つ。

1. モデル指定をセッション限りにする。Claude Code には fast mode の
   `fastModePerSessionOptIn` に相当する設定が model には無いため、
   `/model` での切り替えは settings.json に永続化されてしまう。
   終了時に消せば、次回セッションは常に既定モデルから始まる。

2. dotfiles が汚れるのを防ぐ。`~/.claude` は dotfiles への stow
   シンボリックリンクなので、`/model` を使うたびに追跡対象ファイルが
   変更され、2台で別々に書き換わって衝突する（2026-08-07 に実際に発生）。
   コミット済みの状態を「model キー無し」に統一し、終了時にそこへ戻す。

model キーが無いときは**ファイルを書き換えない**。書き換えると整形が
揺れて、結局リポジトリが汚れるため。
"""

import datetime
import json
import pathlib
import sys

path = pathlib.Path.home() / ".claude" / "settings.json"
log = pathlib.Path.home() / ".cache" / "claude-reset-model.log"


def record(message: str) -> None:
    """フックが発火したこと自体を残す。無音だと動作確認ができないため。"""
    try:
        log.parent.mkdir(parents=True, exist_ok=True)
        stamp = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        with log.open("a") as f:
            f.write(f"{stamp} {message}\n")
    except OSError:
        pass

try:
    settings = json.loads(path.read_text())
except (OSError, json.JSONDecodeError):
    record("skip: settings.json を読めない")
    sys.exit(0)  # フックで設定を壊さない。読めなければ何もしない

removed = settings.pop("model", None)
if removed is None:
    record("noop: model キーなし")
    sys.exit(0)

path.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
record(f"removed: model={removed}")
