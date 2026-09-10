#!/usr/bin/env python3
"""Detect banned coined vocabulary in newly written documentation, across project repositories.

`~/dotfiles/claude/.claude/vocabulary-conventions.md`（以下「規約」）が語の表と検出の規則の
正本で、**このスクリプトはその実装**。規約は 2026-09-01 に制定され「検出の規則（機械検査を
作るときの仕様）」まで書かれていたが、**実装は 2026-09-08 まで存在しなかった**。その間に
pine-wilt へ 12 行の違反が入り、人が読んで気づくまで残った（L53 の型——仕様があって検査が
無い状態は、その規約の保証が無い状態）。

**なぜ機械で見るか**: 造語は「英単語に漢字1〜2字を当てる」形で作られ（gate→門・sweep→掃引）、
書いた本人には自然に見える。**周囲に合わせて書く指示が掛かると、自分の造語を読んで自分で
強化する再帰ループになる。** 語は表で決まっているので、実在検査と同じく機械で落とせる。

**検査しないもの**: 「その語がこの文脈で本当に読みにくいか」は見ない。表に無い語も見ない
（candidates モードが候補を出すだけで、判定は人がして表に足す）。

## 何を見るか

- **1 回の実行で見るのは 1 リポだけ。** 呼ぶのは `close-project-session`——セッションを締める
  リポで、締めるときに走る。**全リポを走査する機能は 2026-09-08 に外した**（弊害が大きい）:
  admin から他リポを串刺しにすると admin が他リポの事実の正本に近づき、
  さらに **admin のローカルに clone があるリポしか見えない**ので、gpu 機で書いた文書が
  検査されないまま「全リポ無音」に見える。**このスクリプトを dotfiles へ置いたのも同じ理由**で、
  リポの外・どの機械にも配られる場所にある。
- **参加はリポ側が宣言する**——`.claude/vocab.toml` に `baseline = "<ref>"` を置いたリポだけを見る。
  置いていないリポは「未参加」と 1 行返して終わる（違反ゼロ扱いにはしない）。
  タグ `vocab-baseline` はフォールバックとして読む（ファイルを置く前の 2 リポのため）。
- **範囲はその baseline からの追加行だけ**（規約「追加行だけを見る」）。既存の移行前の文書は
  対象外——全文を見ると pine-wilt だけで数千件出て、毎朝鳴る検査は読まれなくなる。
- **拡張子は .md .qmd .tex .py .yaml .yml**。`.R` は入れていない（Python の `tokenize` に相当する
  コメント抽出が要る。必要になったら足す）。
- **.py はコメントと三重引用符の文字列だけ**（規約）。日本語の短い文字列は JSON のキーや
  DataFrame の列名になっていることがあり、置き換えると別のスクリプトが壊れる。
- **md の生成ブロックは見ない。代わりに `.yaml` の正本を見る**（2026-09-08）。
  `CLAUDE.md` の `**Concern**:` は `project-status.yaml` の描画で、md を直しても
  `project render` で戻る。**直せない場所を指す指摘は、無いのと変わらない。**
- **このファイル自身と、規約・移行ノートは対象外**。禁止語を語として並べる場所なので、
  入れると必ず鳴る（受け入れ基準が「無音」である以上、最初から除外に書く）。

## `--render` の前提条件（2026-09-10）

**`--render` は書く前に「手元が最新か」を機械で見る**（`require_in_sync`）。
書き込み先が dirty か、origin に対して behind か、判定できない（upstream 無し・fetch 不可）なら
**書かずに落ちる**。`--force` で外せる。

**なぜ**: 追跡ファイルを一括で書き換えるものは、2台で走らせると人が解けない差分になる。
2026-09 の語彙置換は境界つき 2,243 件・複合語込み 3,000 件超で、両方の機械で走れば
「どちらを丸ごと採るか」しか残らない（実際に事故が起きている）。`--render` の書き込み先は
グローバル `CLAUDE.md` と規約＝**dotfiles にあり全機に配られる**ので、同じ型に属する。

**防ぐのは規律ではなく前提条件**。静かな大惨事を、声を上げる拒否に変えるのが目的で、
admin が vault に対してやっていること（排他ロック・変更前 hash 検査・atomic replace・backup）
と同じ形を、リポのファイルを書き換える側にも伸ばした。

**判定できないことを「問題なし」に畳まない。** upstream が無い・fetch が通らないときは
2台目が先に押していても分からない状態なので、無音で通さず落とす。

## 2 つのモード

- **enforce**（既定）: 表にある語を追加行から探す。**無音が正常**。鳴ったら、
  違反か仕様の誤りかを人が判定する（規約「鳴るなら仕様が間違っている」）。毎日走ってよい。
- **candidates**: 追加行の漢字トークンを頻度順に出す。**出力があるのが正常**なので
  毎日は走らせない。新しい造語を見つけて表に足すための入口。

実行（`~/.claude/` は実ディレクトリで dotfiles の中身は配られていないので、ここを直に指す）:
    python3 ~/dotfiles/claude/.claude/vocab_check.py                  # 今いるリポ
    python3 ~/dotfiles/claude/.claude/vocab_check.py --repo /path/to/repo
    python3 ~/dotfiles/claude/.claude/vocab_check.py --quiet          # 違反が無ければ黙る
    python3 ~/dotfiles/claude/.claude/vocab_check.py --format json
    python3 ~/dotfiles/claude/.claude/vocab_check.py --mode candidates
    python3 ~/dotfiles/claude/.claude/vocab_check.py --render         # 表から生成物を作り直す

終了コード 1 = enforce で違反あり。
"""

from __future__ import annotations

import argparse
import collections
import io
import json
import re
import subprocess
import sys
import tokenize
import tomllib
from pathlib import Path
from typing import Any

BASELINE_TAG = "vocab-baseline"
EXTENSIONS = (".md", ".qmd", ".tex", ".py", ".yaml", ".yml")
PROSE = (".md", ".qmd", ".tex")

# 規約と移行ノートは dotfiles にあるので既定では当たらないが、リポへ写した場合に備える。
# 自分自身と表そのものを必ず外す——docstring と表に禁止語が並ぶため。
EXEMPT_NAMES = ("vocabulary-conventions.md", "vocabulary-migration.md",
                "vocabulary.toml", "vocab_check.py", "test_vocab_check.py")

# **語の表の正本は 1 か所だけ**（2026-09-08）。以前はここに dict で写していたが、
# それは規約の表との二重管理で、**写し忘れれば静かに食い違う**（L52 の型）。
# 表は `~/dotfiles/claude/.claude/vocabulary.toml` が持ち、
# グローバル CLAUDE.md の要約も `vocabulary-conventions.md` の表も**そこから生成する**。
# 自分の隣を見る——リポジトリの置き場所に依存しないので、gpu 機でもそのまま動く。
TABLE = Path(__file__).resolve().parent / "vocabulary.toml"


def load_table(path: Path = TABLE) -> tuple[dict[str, dict[str, Any]], dict[str, str]]:
    """語の表を読む。`rule = "none"` の語は検査に入れない（「層」がこれ）。"""
    if not path.exists():
        raise SystemExit(f"語彙の表が無い: {path}（dotfiles を配ったか確かめる）")
    with path.open("rb") as f:
        doc = tomllib.load(f)
    banned = {w["avoid"]: w for w in doc.get("word", []) if w.get("rule") in ("partial", "bounded")}
    return banned, doc.get("long_vowel", {})


BANNED, LONG_VOWEL = load_table()

KANJI = r"一-鿿"
CJK_TOKEN = re.compile(rf"[{KANJI}]{{2,}}")



BEGIN_SUMMARY = "<!-- BEGIN GENERATED VOCABULARY -->"
END_SUMMARY = "<!-- END GENERATED VOCABULARY -->"
BEGIN_TABLE = "<!-- BEGIN GENERATED VOCABULARY TABLE -->"
END_TABLE = "<!-- END GENERATED VOCABULARY TABLE -->"


def _words() -> list[dict[str, Any]]:
    with TABLE.open("rb") as f:
        return tomllib.load(f).get("word", [])


def render_summary() -> str:
    """グローバル CLAUDE.md 用の短い一覧。**毎セッション読まれるのはこれ**。

    2026-09-08 まで手書きで 8 語しか挙げておらず、表にある 19 語と食い違っていた。
    要約に無い語（掃引）はそのまま使われる——**読まれるのは要約の方**なので、
    ここが表と食い違うと違反は必ず入る。
    """
    ws = _words()
    simple = [w for w in ws if "意味で分ける" not in w["use"]]
    split = [w for w in ws if "意味で分ける" in w["use"]]
    lines = [BEGIN_SUMMARY,
             f"**使わない語（{len(ws)}）。正本は `~/dotfiles/claude/.claude/vocabulary.toml`"
             "——この一覧は生成物なので手で編集しない。**", ""]
    def one(w: dict[str, Any]) -> str:
        # `use` 自身が「下限／ノイズフロア」のようにスラッシュを含むので、語の区切りは中黒にする
        tail = "（語では切れないので検査は掛けない）" if w["rule"] == "none" else ""
        return f"**{w['avoid']}**→{w['use']}{tail}"
    lines.append(" ・ ".join(one(w) for w in simple))
    lines.append("")
    lines.append("**意味で分ける（機械置換しない）**: "
                 + "・".join(f"**{w['avoid']}**（{w['english']}）" for w in split)
                 + "——分け方は表の備考を見る。")
    lv = "・".join(load_table()[1].values())
    lines += ["", f"カタカナの長音は落とす: {lv}（**ユーザーだけ長音あり**）。",
              "迷ったらオライリー日本語版が目安。", END_SUMMARY]
    return "\n".join(lines)


def render_table() -> str:
    """`vocabulary-conventions.md` 用の説明つきの表。"""
    rows = [BEGIN_TABLE, "", "| 使わない | 元 | 使う | 検出 | 備考 |", "|---|---|---|---|---|"]
    for w in _words():
        rule = {"partial": "部分一致", "bounded": "境界つき", "none": "**検査しない**"}[w["rule"]]
        allow = w.get("allow")
        if allow:
            rule += "（除外 " + "・".join(f"`{a}`" for a in allow) + "）"
        note = w.get("note", "").replace("\n", " ")
        rows.append(f"| {w['avoid']} | {w['english'] or '—'} | **{w['use']}** | {rule} | {note} |")
    rows += ["", END_TABLE]
    return "\n".join(rows)


def write_between(path: Path, begin: str, end: str, body: str) -> bool:
    text = path.read_text(encoding="utf-8")
    if begin not in text or end not in text:
        raise SystemExit(f"{path} に生成ブロックのマーカーが無い（{begin}）")
    head, rest = text.split(begin, 1)
    _, tail = rest.split(end, 1)
    new = head + body + tail
    if new == text:
        return False
    path.write_text(new, encoding="utf-8")
    return True

def run_git(root: Path, *args: str) -> str:
    out = subprocess.run(["git", "-C", str(root), *args],
                         capture_output=True, text=True)
    return out.stdout if out.returncode == 0 else ""


def require_in_sync(root: Path, targets: list[Path], force: bool) -> None:
    """追跡ファイルを一括で書き換える前の前提条件。

    **2台で走らせると人が解けない差分になる。** 2026-09 の語彙置換は境界つきで 2,243 件・
    複合語を入れて 3,000 件超あり、両方の機械で走ればどちらを採るかしか選べない。
    `--render` も同じ型——書き込み先（グローバル CLAUDE.md と規約）は dotfiles にあり、
    **どの機械にも配られる**。

    **防ぐのは規律ではなく前提条件**にする。書く前に「手元が最新か」を機械で見て、
    そうでなければ書かずに落ちる。静かな大惨事を、声を上げる拒否に変えるのが目的。

    見るのは2つ:

    - **書き込み先に未コミットの変更が無いこと**。あると生成物と手の編集が混ざり、
      どちらがどちらか後から分けられない。
    - **origin に対して behind でないこと**。behind のまま生成すると、古い表から作った
      内容で新しい生成物を上書きする。これが2台運用で最も起きやすい形。

    `--force` で外せる。外すのは「片方の機械しか使っていないと分かっているとき」だけ。
    """
    if force:
        return
    dirty = [p for p in targets
             if run_git(root, "status", "--porcelain", "--", str(p)).strip()]
    if dirty:
        names = "・".join(p.name for p in dirty)
        raise SystemExit(
            f"書き込み先に未コミットの変更がある（{names}）。\n"
            "  先にコミットするか戻すかしてから再実行する（--force で外せる）。")

    # upstream が無いブランチでは behind を判定できない。判定できないことは黙らせない。
    upstream = run_git(root, "rev-parse", "--abbrev-ref", "@{upstream}").strip()
    if not upstream:
        raise SystemExit(
            "upstream が無いので origin との差を判定できない。\n"
            "  ブランチに upstream を設定するか、--force で外す。")
    try:
        subprocess.run(["git", "-C", str(root), "fetch", "--quiet"],
                       capture_output=True, text=True, timeout=20)
    except (subprocess.TimeoutExpired, OSError):
        raise SystemExit(
            "fetch できないので origin との差を判定できない（ネットワークか認証）。\n"
            "  **2台目が先に押していても分からない状態**なので書かない。--force で外せる。")
    behind = run_git(root, "rev-list", "--count", f"HEAD..{upstream}").strip()
    if behind and behind != "0":
        raise SystemExit(
            f"{upstream} に対して {behind} コミット behind。\n"
            "  古い表から生成して新しい内容を上書きしうる。先に pull する（--force で外せる）。")


REPO_CONFIG = ".claude/vocab.toml"


def opt_in(root: Path) -> tuple[str, str] | None:
    """このリポが検査に参加しているか。参加していれば (baseline の ref, 由来) を返す。

    **参加はリポ側が宣言する**（2026-09-08。`doc_refs.py` の
    「リポ固有の例外はリポ側に置く——admin に集めると admin が他リポの事実の正本になる」と同じ）。
    admin は参加リポの一覧を持たない。

    宣言は `.claude/vocab.toml` の `baseline`（git が解決できる ref なら何でもよい）。
    **タグ `vocab-baseline` はフォールバック**として読む——ファイルを置く前の 2 リポが
    そのまま動くようにするためで、新しく参加するリポはファイルの方を使う
    （タグは「いつ・なぜ」を書けず、diff にも出ない）。
    """
    cfg = root / REPO_CONFIG
    if cfg.exists():
        with cfg.open("rb") as f:
            ref = tomllib.load(f).get("baseline")
        if ref and run_git(root, "rev-parse", "--verify", "--quiet", str(ref)).strip():
            return str(ref), REPO_CONFIG
        if ref:
            raise SystemExit(f"{root.name}: {REPO_CONFIG} の baseline `{ref}` が解決できない")
    if BASELINE_TAG in run_git(root, "tag").split():
        return BASELINE_TAG, f"タグ {BASELINE_TAG}"
    return None


def added_lines(root: Path, baseline: str) -> list[tuple[str, str]]:
    """baseline..HEAD で追加された行を (ファイル, 行) で返す。作業ツリーの未コミット分も含む。"""
    out = []
    for spec in (f"{baseline}..HEAD", "HEAD"):
        diff = run_git(root, "diff", spec, "-U0", "--no-color", "--", *[f"*{e}" for e in EXTENSIONS])
        path = None
        for line in diff.splitlines():
            if line.startswith("+++ b/"):
                path = line[6:]
            elif line.startswith("+") and not line.startswith("+++") and path:
                out.append((path, line[1:]))
    return out


GENERATED = (re.compile(r"<!--\s*BEGIN GENERATED\b"), re.compile(r"<!--\s*END GENERATED\b"))


def generated_block_lines(text: str) -> set[str]:
    """`<!-- BEGIN GENERATED ... -->` 〜 `<!-- END GENERATED ... -->` の中の行。

    **生成ブロックは、そこでは直せない。** `CLAUDE.md` の `**Concern**:` は
    `project-status.yaml` の描画で、md を直しても `project render` で戻る。
    だから **md の生成ブロックは飛ばし、正本の `.yaml` の方を検査する**（2026-09-08）。
    以前は逆で、唯一出ていた指摘が直せない場所を指し、直せる `.yaml` は拡張子の外にあった。
    """
    begin, end = GENERATED
    skip, inside = set(), False
    for line in text.splitlines():
        if begin.search(line):
            inside = True
        if inside:
            skip.add(line.strip())
        if end.search(line):
            inside = False
    return skip - {""}


def python_comment_lines(text: str) -> set[str]:
    """.py のうち検査してよい行——コメントと、三重引用符で始まる文字列だけ（規約）。

    日本語の短い文字列は JSON の出力キー・DataFrame の列名になっていることがあり、
    置き換えると別のスクリプトが読み戻せなくなる。**これは後回しではなく恒久的な対象外。**
    """
    keep: set[str] = set()
    try:
        for tok in tokenize.generate_tokens(io.StringIO(text).readline):
            if tok.type == tokenize.COMMENT:
                keep.add(tok.string)
            elif tok.type == tokenize.STRING and tok.string.lstrip("rbufRBUF")[:3] in ('"""', "'''"):
                keep.update(tok.string.splitlines())
    except (tokenize.TokenError, IndentationError, SyntaxError):
        return set()          # 壊れた断片は見ない（差分の片側だけを渡されることがある）
    return keep


def _spans(line: str, words: list[str]) -> list[tuple[int, int]]:
    """`words` がこの行のどこに出るか。除外語の判定に使う。"""
    return [(m.start(), m.end()) for w in words for m in re.finditer(re.escape(w), line)]


def _inside(m: re.Match[str], spans: list[tuple[int, int]]) -> bool:
    """この一致が、正当な複合語の内側に丸ごと入っているか。

    **「同じ行に除外語があるか」ではなく「この一致がその一部か」を見る**（2026-09-08 に直した）。
    以前は一致の前後 4 文字を見ていたため、正当な複合語が近くにあるだけで本物の違反が消えた
    ——`林床と床効果を比べる` が 0 件、`証拠窓と窓関数を使う` が 0 件になり、
    しかも `床効果は林床でも起きる` は当たる（語順で結果が変わる）状態だった。**見逃しは静かに効く。**
    """
    return any(s <= m.start() and m.end() <= e for s, e in spans)


def hits_in(line: str) -> list[tuple[str, str]]:
    """1 行から (語, 使う語) を拾う。規約の検出規則をそのまま実装する。"""
    found = []
    for word, spec in BANNED.items():
        allow = _spans(line, spec.get("allow", []))
        if spec["rule"] == "partial":
            pattern = re.escape(word)
        else:
            # 境界つき完全一致。前後が漢字でなければ当たる＝漢語の複合語は素通りする
            # （専門・林床・帯域…）。見逃す複合語は語として規約の表に足す。
            pattern = rf"(?<![{KANJI}]){re.escape(word)}(?![{KANJI}])"
        for m in re.finditer(pattern, line):
            if _inside(m, allow):
                continue
            found.append((word, spec["use"]))
            break
    # **長い語から見て、その内側の一致は数えない**（2026-09-08 に直した）。
    # `クラスター` は `ラスター` を含むので、素朴に部分一致を掛けると 1 語で 2 件鳴った。
    # ノイズは毎朝鳴って検査そのものを殺す（`doc_refs.py` の教訓）ので、最長一致を採る。
    taken: list[tuple[int, int]] = []
    for long in sorted(LONG_VOWEL, key=len, reverse=True):
        for m in re.finditer(re.escape(long), line):
            if _inside(m, taken):
                continue
            found.append((long, LONG_VOWEL[long]))
            taken.append((m.start(), m.end()))
            break
    return found


def check_repo(root: Path, mode: str = "enforce") -> dict[str, Any]:
    name = root.name or root.resolve().name
    joined = opt_in(root)
    if joined is None:
        return {"repo": name, "opted_in": False, "hits": []}
    baseline, source = joined

    py_ok: dict[str, set[str]] = {}
    generated: dict[str, set[str]] = {}
    hits, tokens = [], collections.Counter()
    for path, line in added_lines(root, baseline):
        if Path(path).name in EXEMPT_NAMES:
            continue
        if path.endswith(PROSE):
            if path not in generated:
                f = root / path
                generated[path] = generated_block_lines(
                    f.read_text(encoding="utf-8", errors="replace")) if f.exists() else set()
            if line.strip() in generated[path]:
                continue
        if path.endswith(".py"):
            if path not in py_ok:
                f = root / path
                py_ok[path] = python_comment_lines(f.read_text(encoding="utf-8", errors="replace")) \
                    if f.exists() else set()
            if not any(line.strip() and line.strip() in c for c in py_ok[path]):
                continue
        if mode == "candidates":
            tokens.update(t for t in CJK_TOKEN.findall(line) if t not in BANNED)
            continue
        for word, use in hits_in(line):
            hits.append({"file": path, "word": word, "use": use, "line": line.strip()[:110]})
    if mode == "candidates":
        return {"repo": name, "opted_in": True, "baseline": source,
                "candidates": tokens.most_common(40), "hits": []}
    return {"repo": name, "opted_in": True, "baseline": source, "hits": hits}


def git_root(start: Path) -> Path:
    """検査するリポ。**既定は今いるリポ**——このスクリプトは1リポずつ呼ぶ。"""
    out = run_git(start, "rev-parse", "--show-toplevel").strip()
    if not out:
        raise SystemExit(f"git リポジトリの中で実行する（{start}）")
    return Path(out)


def render(it: dict[str, Any], quiet: bool, mode: str) -> str:
    if not it.get("opted_in"):
        return "" if quiet else f"{it['repo']}: 未参加（{REPO_CONFIG} が無い）"
    if mode == "candidates":
        return "\n".join([f"{it['repo']}: 候補 {len(it.get('candidates', []))}"]
                         + [f"    {n:4d}  {tok}" for tok, n in it.get("candidates", [])])
    if not it["hits"]:
        return "" if quiet else f"{it['repo']}: OK"
    out = [f"{it['repo']}: 禁止語 {len(it['hits'])} 件"]
    for h in it["hits"]:
        out.append(f"  {h['file']}: 「{h['word']}」→ {h['use']}")
        out.append(f"      {h['line']}")
    return "\n".join(out)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--repo", type=Path, default=None,
                   help="検査するリポ（既定は今いるリポ）")
    p.add_argument("--mode", choices=("enforce", "candidates"), default="enforce")
    p.add_argument("--format", choices=("summary", "json"), default="summary")
    p.add_argument("--quiet", action="store_true", help="違反が無ければ何も出さない")
    p.add_argument("--render", action="store_true",
                   help="表から生成ブロックを書き直す（グローバル CLAUDE.md と規約の表）")
    p.add_argument("--force", action="store_true",
                   help="--render の前提条件（書き込み先が clean・origin に behind でない）を外す")
    return p.parse_args()


def main() -> int:
    a = parse_args()
    if a.render:
        here = Path(__file__).resolve().parent
        cl, cv = here / "CLAUDE.md", here / "vocabulary-conventions.md"
        require_in_sync(git_root(here), [cl, cv], a.force)
        for path, (begin, end, body) in ((cl, (BEGIN_SUMMARY, END_SUMMARY, render_summary())),
                                         (cv, (BEGIN_TABLE, END_TABLE, render_table()))):
            print(f"{path}: {'更新' if write_between(path, begin, end, body) else '変化なし'}")
        return 0
    root = git_root(a.repo.expanduser() if a.repo else Path.cwd())
    item = check_repo(root, a.mode)
    if a.format == "json":
        print(json.dumps(item, ensure_ascii=False, indent=1))
    else:
        text = render(item, a.quiet, a.mode)
        if text:
            print(text)
    return 1 if a.mode == "enforce" and item["hits"] else 0


if __name__ == "__main__":
    sys.exit(main())
