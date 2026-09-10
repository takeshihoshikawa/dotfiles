"""
tests/test_vocab_check.py — vocab_check.py の禁止語検出の単体テスト

**偽陽性を1件でも定常化させない**（doc_refs.py と同じ規範）。毎朝出るノイズは読まれなくなり、
検査そのものが死ぬ。ここで固定するのは、規約
`~/dotfiles/claude/.claude/vocabulary-conventions.md` の「検出の規則」で決まっている 3 つ:

1. 部分一致（造語側が開いている語）と境界つき（正当語側が開いている語）の使い分け
2. 除外語（規約が挙げる 5 語だけ。先回りして増やさない）
3. `.py` はコメントと三重引用符の中だけ（日本語の短い文字列は JSON キー・列名になりうる）

および、実測して外した 1 つ:

4. **「層」は検査しない**（2026-09-08。境界つきで 42 件当たり、大半が統計の層別・点群の
   高さの層・データ管理の層・GeoPackage のレイヤ＝規約が「残す」と言っている側だった）

さらに、**表を二重管理へ戻さないこと**（同日。表は `vocabulary.toml` が唯一の正本で、
グローバル `CLAUDE.md` の一覧も規約の表も検査もそこから来る）。
"""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import vocab_check  # noqa: E402


class HitsTest(unittest.TestCase):
    def words(self, line: str) -> set[str]:
        return {w for w, _ in vocab_check.hits_in(line)}

    def test_partial_match_catches_compounds(self) -> None:
        # 造語側が開いている語は複合語ごと拾う（窓内・証拠窓・床効果…）
        self.assertEqual(self.words("証拠窓を 60 日にする"), {"窓"})
        self.assertEqual(self.words("床効果が出る"), {"床"})
        self.assertEqual(self.words("発火率は 0.3"), {"発火"})

    def test_partial_exclusions_are_only_the_five_in_the_spec(self) -> None:
        for ok in ("窓関数を掛ける", "林床が見える", "林床侵入", "温床になる", "高床の倉庫"):
            self.assertEqual(self.words(ok), set(), ok)

    def test_bounded_match_lets_kanji_compounds_through(self) -> None:
        # 正当語側が開いている語は境界つき＝漢語の複合語は除外リスト無しで素通りする
        for ok in ("専門職大学", "帯域を分ける", "林帯の縁", "海岸帯", "障壁になる", "既製品を使う"):
            self.assertEqual(self.words(ok), set(), ok)
        self.assertEqual(self.words("3〜8 m の帯"), {"帯"})
        self.assertEqual(self.words("60km の壁"), {"壁"})

    def test_bounded_exclusion_covers_the_verb(self) -> None:
        # 「被害を帯びる」は前後が平仮名なので境界つきで当たる（2026-09-04 実測）
        self.assertEqual(self.words("被害を帯びる"), set())

    def test_exclusion_does_not_mask_a_real_hit_on_the_same_line(self) -> None:
        """除外語は**その一致が複合語の一部か**で効く。同じ行にあるだけでは消えない。

        2026-09-08 まで一致の前後 4 文字を見ていたため、正当な複合語が近くにあると
        本物の違反が消えた。語順で結果が変わる（下 2 行が別の答えになる）のが症状だった。
        """
        self.assertEqual(self.words("林床と床効果を比べる"), {"床"})
        self.assertEqual(self.words("床効果は林床でも起きる"), {"床"})
        self.assertEqual(self.words("証拠窓と窓関数を使う"), {"窓"})
        self.assertEqual(self.words("被害を帯びる区域と 3〜8 m の帯"), {"帯"})

    def test_layer_is_not_checked(self) -> None:
        # 統計の層別・点群の高さの層・データ管理の層は全て正当（2026-09-08 に外した判断）
        for ok in ("層ごとに抽出する", "高さ方向の層 L0〜L7", "disposable 層", "blocks 層を読む"):
            self.assertEqual(self.words(ok), set(), ok)

    def test_long_vowel_katakana(self) -> None:
        self.assertEqual(self.words("レイヤーを追加"), {"レイヤー"})
        self.assertEqual(self.words("ユーザーが決める"), set())   # ユーザーだけ長音あり

    def test_long_vowel_takes_the_longest_match(self) -> None:
        """`クラスター` は `ラスター` を含む。1 語で 2 件鳴らさない（2026-09-08）。"""
        self.assertEqual(self.words("クラスターを作る"), {"クラスター"})
        self.assertEqual(self.words("ラスターを読む"), {"ラスター"})


class PythonScopeTest(unittest.TestCase):
    def test_only_comments_and_docstrings(self) -> None:
        src = ('"""説明の窓について。"""\n'
               "# コメントの窓\n"
               'KEY = "発火数"          # ← JSON キー。これは対象外\n'
               'df["温室旗率"] = 1\n')
        keep = vocab_check.python_comment_lines(src)
        self.assertTrue(any("説明の窓について" in k for k in keep))
        self.assertTrue(any("コメントの窓" in k for k in keep))
        self.assertFalse(any('KEY = "発火数"' == k.strip() for k in keep))
        self.assertFalse(any("温室旗率" in k and "#" not in k for k in keep))

    def test_broken_fragment_is_silent(self) -> None:
        self.assertEqual(vocab_check.python_comment_lines("def f(:\n  # 窓\n"), set())


class RepoTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def git(self, *args: str) -> None:
        subprocess.run(["git", "-C", str(self.root), *args], check=True,
                       capture_output=True)

    def write(self, rel: str, text: str) -> None:
        p = self.root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text, encoding="utf-8")

    def test_repo_without_opt_in_is_not_checked(self) -> None:
        """参加宣言の無いリポは見ない（admin が参加リポの一覧を持たないための形）。"""
        self.write("docs/a.md", "証拠窓を使う\n")
        self.git("add", "-A"); self.git("commit", "-qm", "x")
        got = vocab_check.check_repo(self.root)
        self.assertFalse(got["opted_in"])
        self.assertEqual(got["hits"], [])
        # 1 リポずつ呼ぶので、未参加は黙らず 1 行返す（--quiet のときだけ黙る）
        self.assertIn("未参加", vocab_check.render(got, quiet=False, mode="enforce"))
        self.assertEqual(vocab_check.render(got, quiet=True, mode="enforce"), "")

    def test_repo_config_declares_the_baseline(self) -> None:
        """`.claude/vocab.toml` の baseline が使われ、タグより優先される。"""
        self.write("docs/a.md", "既存の証拠窓\n")
        self.git("add", "-A"); self.git("commit", "-qm", "before")
        self.git("tag", "here")
        self.write("docs/a.md", "既存の証拠窓\n新しい床効果\n")
        self.git("add", "-A"); self.git("commit", "-qm", "after")
        self.write(".claude/vocab.toml", 'baseline = "here"\n')
        self.git("add", "-A"); self.git("commit", "-qm", "opt-in")
        got = vocab_check.check_repo(self.root)
        self.assertEqual(got["baseline"], vocab_check.REPO_CONFIG)
        self.assertEqual([h["word"] for h in got["hits"]], ["床"])

    def test_unresolvable_baseline_fails_loudly(self) -> None:
        self.git("commit", "-qm", "root", "--allow-empty")
        self.write(".claude/vocab.toml", 'baseline = "no-such-ref"\n')
        self.git("add", "-A"); self.git("commit", "-qm", "bad")
        with self.assertRaises(SystemExit):
            vocab_check.check_repo(self.root)

    def test_only_lines_added_after_baseline(self) -> None:
        self.write("docs/a.md", "既存の証拠窓は直さない\n")
        self.git("add", "-A"); self.git("commit", "-qm", "before")
        self.git("tag", vocab_check.BASELINE_TAG)   # タグはフォールバックとして今も効く
        self.write("docs/a.md", "既存の証拠窓は直さない\n新しい床効果の行\n")
        self.git("add", "-A"); self.git("commit", "-qm", "after")
        hits = vocab_check.check_repo(self.root)["hits"]
        self.assertEqual([h["word"] for h in hits], ["床"])

    def test_self_and_spec_files_are_exempt(self) -> None:
        self.git("commit", "-qm", "root", "--allow-empty")
        self.git("tag", vocab_check.BASELINE_TAG)
        self.write("docs/vocabulary-conventions.md", "床・窓・発火の表\n")
        self.write("vocab_check.py", '"""床・窓・発火の表"""\n')
        self.write("tests/test_vocab_check.py", '"""床・窓・発火の表"""\n')
        self.git("add", "-A"); self.git("commit", "-qm", "spec")
        self.assertEqual(vocab_check.check_repo(self.root)["hits"], [])

    def test_generated_block_is_skipped_and_the_yaml_source_is_checked(self) -> None:
        """生成ブロックでは直せない。**正本の `.yaml` の方を指す**（2026-09-08）。

        `CLAUDE.md` の `**Concern**:` は `project-status.yaml` の描画で、
        md を直しても `project render` で戻る。両方を検査すると同じ違反が 2 件になり、
        しかも片方は直せない場所を指す。
        """
        self.git("commit", "-qm", "root", "--allow-empty")
        self.git("tag", vocab_check.BASELINE_TAG)
        self.write("CLAUDE.md", "<!-- BEGIN GENERATED PROJECT STATUS -->\n"
                                "**Concern**: 3〜8 m の帯は若齢林\n"
                                "<!-- END GENERATED PROJECT STATUS -->\n")
        self.write("project-status.yaml", 'concern: "3〜8 m の帯は若齢林"\n')
        self.git("add", "-A"); self.git("commit", "-qm", "status")
        hits = vocab_check.check_repo(self.root)["hits"]
        self.assertEqual([(h["file"], h["word"]) for h in hits], [("project-status.yaml", "帯")])

    def test_prose_outside_the_generated_block_is_still_checked(self) -> None:
        self.git("commit", "-qm", "root", "--allow-empty")
        self.git("tag", vocab_check.BASELINE_TAG)
        self.write("CLAUDE.md", "<!-- BEGIN GENERATED PROJECT STATUS -->\n"
                                "**Phase**: ふつうの記述\n"
                                "<!-- END GENERATED PROJECT STATUS -->\n"
                                "手で書いた床効果の行\n")
        self.git("add", "-A"); self.git("commit", "-qm", "mixed")
        hits = vocab_check.check_repo(self.root)["hits"]
        self.assertEqual([h["word"] for h in hits], ["床"])


class SingleSourceTest(unittest.TestCase):
    """表は `vocabulary.toml` 1 か所。写しを作らない（2026-09-08）。"""

    def test_table_is_loaded_from_toml(self) -> None:
        banned, long_vowel = vocab_check.load_table()
        self.assertGreater(len(banned), 10)
        self.assertNotIn("層", banned)                 # rule = "none" は検査に入らない
        self.assertIn("掃引", banned)                  # 2026-09-08 に踏んだ語
        self.assertIn("レイヤー", long_vowel)

    def test_summary_lists_every_word(self) -> None:
        """グローバル CLAUDE.md の一覧に**全語**が出る（8 語しか無かったのが 186 件の原因）。"""
        text = vocab_check.render_summary()
        with vocab_check.TABLE.open("rb") as f:
            import tomllib
            words = tomllib.load(f)["word"]
        for w in words:
            self.assertIn(w["avoid"], text, w["avoid"])

    def test_meaning_split_notes_survive(self) -> None:
        """「意味で分ける」語の分け方が表に残っている（1 語に畳むと機械置換されて壊れる）。"""
        table = vocab_check.render_table()
        self.assertIn("全面踏査", table)               # 掃引
        self.assertIn("工事区域", table)               # 帯
        self.assertIn("運用上の改善", table)           # 利得


class RenderPreconditionTest(unittest.TestCase):
    """`--render` の前提条件（`require_in_sync`）。

    **2台で走らせると人が解けない差分になる。** 2026-09 の語彙置換は境界つき 2,243 件・
    複合語込みで 3,000 件超あり、両方の機械で走れば「どちらを丸ごと採るか」しか残らない。
    `--render` の書き込み先はグローバル `CLAUDE.md` と規約＝**dotfiles にあり全機に配られる**
    ので、同じ型に属する。防ぐのは規律ではなく前提条件で、ここで固定するのは
    **書かずに落ちること**（黙って上書きしないこと）。
    """

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        base = Path(self._tmp.name)
        self.origin, self.root = base / "origin", base / "work"
        subprocess.run(["git", "init", "-q", "-b", "main", "--bare", str(self.origin)],
                       check=True, capture_output=True)
        subprocess.run(["git", "clone", "-q", str(self.origin), str(self.root)],
                       check=True, capture_output=True)
        self.git("config", "user.email", "t@example.com")
        self.git("config", "user.name", "t")
        self.target = self.root / "CLAUDE.md"
        self.target.write_text("x\n", encoding="utf-8")
        self.git("add", "-A"); self.git("commit", "-qm", "init")
        self.git("push", "-q", "-u", "origin", "main")

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def git(self, *args: str) -> None:
        subprocess.run(["git", "-C", str(self.root), *args], check=True,
                       capture_output=True)

    def test_clean_and_up_to_date_passes(self) -> None:
        vocab_check.require_in_sync(self.root, [self.target], force=False)

    def test_uncommitted_change_to_target_refuses(self) -> None:
        """書き込み先が dirty なら書かない——生成物と手の編集が混ざると後から分けられない。"""
        self.target.write_text("手で直した\n", encoding="utf-8")
        with self.assertRaises(SystemExit) as e:
            vocab_check.require_in_sync(self.root, [self.target], force=False)
        self.assertIn("未コミットの変更", str(e.exception))

    def test_behind_origin_refuses(self) -> None:
        """behind なら書かない——古い表から生成して新しい内容を上書きする形が2台運用の本命。"""
        self.git("commit", "-qm", "ahead", "--allow-empty")
        self.git("push", "-q")
        self.git("reset", "-q", "--hard", "HEAD~1")   # origin より 1 つ後ろへ下がる
        with self.assertRaises(SystemExit) as e:
            vocab_check.require_in_sync(self.root, [self.target], force=False)
        self.assertIn("behind", str(e.exception))

    def test_force_skips_every_check(self) -> None:
        """`--force` は「片方の機械しか使っていないと分かっているとき」の逃げ道。"""
        self.target.write_text("手で直した\n", encoding="utf-8")
        vocab_check.require_in_sync(self.root, [self.target], force=True)

    def test_missing_upstream_refuses_rather_than_passing_silently(self) -> None:
        """判定できないことを「問題なし」に畳まない（無音は検査が死んだ状態と区別できない）。"""
        self.git("checkout", "-q", "-b", "no-upstream")
        with self.assertRaises(SystemExit) as e:
            vocab_check.require_in_sync(self.root, [self.target], force=False)
        self.assertIn("upstream", str(e.exception))


if __name__ == "__main__":
    unittest.main()
