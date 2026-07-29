# 文献管理規約（papis / bib）

引用文献の正本は papis ライブラリ。**ライブラリはリポジトリの外**に置き、
リポジトリに入るのは papis から生成した `refs.bib` だけ。

基準実装は `~/work/projects/nfi-understory-disturbance`（2026-07-28 に移設・`src/nfi/refs.py`・
`scripts/utilities/export_refs_from_papis.py`）。新規プロジェクトはこれを踏襲する。
**参照実装であって依存先ではない**（このリポジトリが無くても本規約は成立する。実装を写すときの見本）。

## 1. ライブラリはすべて iCloud に置く

```
~/Documents/papis/kb/                # 汎用の知識ベース（分野横断の蓄積）
~/Documents/papis/{project}/         # プロジェクト別（その申請・論文で実際に引く文献だけ）
```

- **git 管理しない。** リポジトリのワークツリー内に置かない
- `kb` → プロジェクトライブラリは**一方向**にコピーする。逆流させない
- iCloud に置ける理由: papis は「フォルダ + `info.yaml` + PDF」の離散ファイル書き込みなので、
  SQLite と違い iCloud のバックグラウンド同期と共存できる（書き込み中に同期が割り込んで
  ファイルが壊れる問題が起きない）。2 台の Mac のどちらからも同じライブラリを引ける

### なぜリポジトリの外なのか

出版社版 PDF を含むため、**リポジトリに入れるとコード公開時に著作物の再配布になる**。
`.gitignore` で PDF を除外するだけでは足りない。ライブラリがワークツリー内にある限り、
公開のたびに除外判断が要り、`git archive` や zip 配布で混入する経路が残る。**置き場所で解決する。**

（`nfi-understory-disturbance` は当初 `refs/papis-lib/` に置いており、公開準備の段階で
出版社版 PDF/HTML 9 ファイルの混入が判明して移設した。`nfi/docs/public-release-plan.md` に実物リスト）

## 2. リポジトリに置くのは `refs.bib` だけ

| | 扱い |
|---|---|
| papis ライブラリ（`info.yaml`・PDF・`notes.md`） | リポジトリ外。git 管理しない |
| `refs.bib` | **生成物だが git 追跡する** |

`refs.bib` を追跡するのは、提出した PDF を組んだ文献リストが provenance であり、
査読対応時に「投稿時点の文献リスト」を復元できる必要があるため。生成物を追跡する例外だと理解しておく。

出力先はフェーズで変わるが、**扱いは同じ**（フェーズごとにライブラリの置き場所を分けない）:

```
proposals/{YYYY}-{種別}/refs/refs.bib     # 申請書
outputs/papers/{原稿名}/refs.bib          # 論文
```

ファイル名は `refs.bib` に統一する。**既存プロジェクトは遡及リネームしない**
（`forest-instance-annotation` は `references.bib`）。pandoc/Quarto の参照先を書き換える必要があり、
名前を揃える利益より原稿を壊す危険のほうが大きい。

## 3. `refs.bib` を直接編集しない

文献の追加・修正は papis 側で行う。

```bash
papis --lib {library} add --from doi <DOI> --set ref <citekey>
papis --lib {library} edit <query>
```

`refs.bib` は `scripts/utilities/export_refs_from_papis.py` で再生成する。papis の bibtex 出力は
そのままでは原稿に使えない（Crossref 由来の HTML エンティティ・タグが残る等）ため、
フィールド単位の正規化を挟む。**bib のヘッダに次を書き込む**:

```
% このファイルは papis ライブラリ `{library}` から自動生成される。直接編集しない。
%   uv run python scripts/utilities/export_refs_from_papis.py
% 文献の追加は papis 側で行う:
%   papis --lib {library} add --from doi <DOI> --set ref <citekey>
% ライブラリ実体はリポジトリ外（登録は ~/Library/Application Support/papis/config）
```

中間生成物（`*.papis-raw.bib`）は `.gitignore` 済み。

## 4. 場所の正本は papis の global config

`~/Library/Application Support/papis/config` の `[{library}] dir` が唯一の正本。
マシンによって置き場所が違いうるため、**スクリプトにパスを直書きしない。**

解決コードは `src/{pkg}/refs.py` に置き、config を読んでライブラリ実体を返す
（見つからなければ `~/Documents/papis/{library}/` にフォールバック、それも無ければ例外を投げる）。
実装は `nfi-understory-disturbance` の `src/nfi/refs.py` をひな型にする。

## 5. ライブラリ名

**プロジェクトディレクトリ名に合わせる**のを原則とする。短縮する場合はプロジェクト `CLAUDE.md` に
明記し、コード側は定数 1 箇所（`LIBRARY = "..."`）に閉じる。

既存の `nfi-understory`（プロジェクトは `nfi-understory-disturbance`）は遡及改名しない。

## 6. Mac 以外では papis ライブラリが無い

iCloud は Mac のみ。Ubuntu 機・EC2 にライブラリは存在しない。
ただし `refs.bib` はリポジトリにあるので、**原稿のレンダリングは通る。**

papis を要する作業（引用照合・要旨補完・`refs.bib` の再生成）は Mac 側で行う。
この非対称性は意図した設計であって、欠陥ではない。

## 7. 引用点検の道具立て

`manuscript-submission-check.md` の項目 7（引用と主張の対応）は、原稿の外＝文献の要旨・本文に
当たらないと終わらない。`nfi-understory-disturbance` の `scripts/utilities/` にある 3 本が型。

| スクリプト | 役割 | 項目 7 との対応 |
|---|---|---|
| `citation_claim_audit.py` | 引用キーごとに「本文で背負わせている主張の文」と「papis 側の題名・要旨」を並べて出す。判定は人間/エージェントが読んで行う | 照合の実行 |
| `fetch_missing_abstracts.py` | 要旨が欠けている文献を公開 API（Crossref・Europe PMC）から補う。**既存の要旨は上書きしない** | 段階 2 の材料を揃える |
| `fetch_oa_pdfs.py` | OA 本文 PDF を取り込む（OA が無いものはブラウザで取得して `papis addto`） | 段階 3 の材料を揃える |

コードは各プロジェクトで書く。共有ライブラリ化は
`cross-project-technology-layer.md` の閾値（2 つ目のプロジェクトで**実際に**必要になった時点）に従う。

## 運用ログ

個別プロジェクトの事故メモ・移行の経緯は vault `notes/papis.md`
（`import_readcube.py` の再実行禁止、日本語 citekey の扱い等）。
