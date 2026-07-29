#!/usr/bin/env bash
# research-project/init.sh — 研究プロジェクトの立ち上げ補助
#
# サブコマンド:
#   adopt              プロジェクトディレクトリを作成または既存ディレクトリを補完
#   add-proposal       proposals/{YEAR}-{GRANT_TYPE}/ サブツリーを追加
#   add-papis-lib      Papis ライブラリを作成・登録（実体は iCloud、リポジトリ外）
#   add-obsidian-note  Obsidian プロジェクトノートを生成
#
# 設計方針:
#   - 既存ファイルは絶対に上書きしない（cp -n、mkdir -p のみ使用）
#   - 何回実行しても安全（冪等）
#   - --name 以外はすべて省略可。未指定変数は {{VAR}} のまま残る
#   - 構想を ChatGPT/Obsidian/FS で先行構築した運用にも対応

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/work/projects}"
VAULT_ROOT="${VAULT_ROOT:-$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/main}"
PAPIS_ROOT="${PAPIS_ROOT:-$HOME/Documents/papis}"
PAPIS_CONFIG="${PAPIS_CONFIG:-$HOME/Library/Application Support/papis/config}"

# ---------- 共通ヘルパー ----------

log()  { printf '  %s\n' "$*"; }
err()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# substitute_in_file FILE KEY1 VAL1 [KEY2 VAL2 ...]
# {{KEY}} を VAL に置換。VAL が空文字なら置換しない（プレースホルダを残す）。
substitute_in_file() {
  local file=$1; shift
  while [[ $# -gt 0 ]]; do
    local key=$1
    local val=${2-}
    shift 2 || true
    [[ -z $val ]] && continue
    local esc
    esc=$(printf '%s' "$val" | sed -e 's/[#&\\]/\\&/g')
    sed -i.bak "s#{{${key}}}#${esc}#g" "$file"
  done
  rm -f "$file.bak"
}

# copy_template_file SRC DST KEY1 VAL1 ...
# DST が既に存在すればスキップ。.template 拡張子を剥がし、変数置換も行う。
copy_template_file() {
  local src=$1; local dst=$2; shift 2
  if [[ -e $dst ]]; then
    log "skip (exists): $dst"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  substitute_in_file "$dst" "$@"
  log "added: $dst"
}

# ---------- adopt ----------

cmd_adopt() {
  local name= rep= proj_full=
  while [[ $# -gt 0 ]]; do
    case $1 in
      --name)           name=$2; shift 2 ;;
      --representative) rep=$2; shift 2 ;;
      --project-name)   proj_full=$2; shift 2 ;;
      *) err "adopt: unknown option $1" ;;
    esac
  done
  [[ -z $name ]] && err "adopt: --name required"

  local target="$PROJECTS_ROOT/$name"
  mkdir -p "$target"
  printf '==> adopt: %s\n' "$target"

  # .gitignore はそのままコピー
  if [[ ! -e "$target/.gitignore" ]]; then
    cp "$SCRIPT_DIR/skeleton/.gitignore" "$target/.gitignore"
    log "added: $target/.gitignore"
  else
    log "skip (exists): $target/.gitignore"
  fi

  # .template ファイルを変数置換しつつコピー
  copy_template_file \
    "$SCRIPT_DIR/skeleton/CLAUDE.md.template" \
    "$target/CLAUDE.md" \
    PROJECT_NAME "$name" \
    FULL_PROJECT_NAME "${proj_full:-}" \
    REPRESENTATIVE "$rep"

  copy_template_file \
    "$SCRIPT_DIR/skeleton/README.md.template" \
    "$target/README.md" \
    PROJECT_NAME "$name" \
    FULL_PROJECT_NAME "${proj_full:-}"

  # 空ディレクトリを .gitkeep 付きで作成（構造の正本: ~/dotfiles/claude/.claude/research-project-conventions.md）
  local d
  for d in data/raw data/interim data/processed data/outputs \
           src notebooks \
           scripts/pipeline scripts/experiments scripts/publication scripts/utilities \
           config/datasets config/models config/paths \
           results outputs/papers outputs/presentations outputs/reports docs; do
    if [[ ! -d "$target/$d" ]]; then
      mkdir -p "$target/$d"
      touch "$target/$d/.gitkeep"
      log "added: $target/$d/"
    else
      log "skip (exists): $target/$d/"
    fi
  done

  # NAS/S3 同期スクリプト（ENV_PREFIX は kebab-case 名の頭文字、例: tree-species-classification -> TSC）
  local env_prefix
  env_prefix=$(printf '%s' "$name" | awk -F- '{for (i = 1; i <= NF; i++) printf "%s", toupper(substr($i, 1, 1))}')
  local s
  for s in sync_with_nas.sh sync_with_s3.sh; do
    copy_template_file \
      "$SCRIPT_DIR/skeleton/scripts/utilities/$s.template" \
      "$target/scripts/utilities/$s" \
      PROJECT_NAME "$name" \
      ENV_PREFIX "$env_prefix"
    chmod +x "$target/scripts/utilities/$s"
  done

  # git 初期化（既存 .git は触らない）
  if [[ ! -d "$target/.git" ]]; then
    (
      cd "$target"
      git init -q
      git add .
      git commit -q -m "Initial scaffold from research-project template"
    )
    log "git: initialized + initial commit"
  else
    log "git: already initialized (preserved)"
  fi

  cat <<EOF

次のステップ:
  1. ChatGPT や Obsidian で書いた構想メモを CLAUDE.md に貼り込む（{{...}} と <!-- TODO --> を埋める）
  2. proposals/ を作る場合:
       $0 add-proposal --name $name --year YYYY --grant-type 種別
  3. Papis ライブラリを使う場合:
       $0 add-papis-lib --name $name
  4. Obsidian プロジェクトノートを作る場合:
       $0 add-obsidian-note --name $name
  5. GitHub private repo に push する（申請書を含むなら必須。提出版の正本がここだけになる）:
       cd $target && gh repo create --private $name --source=. --remote=origin --push

EOF
}

# ---------- add-proposal ----------

cmd_add_proposal() {
  local name= year= gtype=
  while [[ $# -gt 0 ]]; do
    case $1 in
      --name)       name=$2; shift 2 ;;
      --year)       year=$2; shift 2 ;;
      --grant-type) gtype=$2; shift 2 ;;
      *) err "add-proposal: unknown option $1" ;;
    esac
  done
  [[ -z $name ]]  && err "add-proposal: --name required"
  [[ -z $year ]]  && err "add-proposal: --year required"
  [[ -z $gtype ]] && err "add-proposal: --grant-type required"

  local target="$PROJECTS_ROOT/$name"
  [[ ! -d $target ]] && err "add-proposal: $target does not exist (run adopt first)"

  printf '==> add-proposal: %s/proposals/%s-%s/\n' "$target" "$year" "$gtype"

  # proposal-skeleton/proposals/{{YEAR}}-{{GRANT_TYPE}}/ 配下のサブディレクトリ構造を反映。
  # 雛形にディレクトリを追加すれば自動で取り込まれる（スクリプト改修不要）。
  local skel_root="$SCRIPT_DIR/proposal-skeleton/proposals/{{YEAR}}-{{GRANT_TYPE}}"
  [[ ! -d $skel_root ]] && err "add-proposal: proposal-skeleton not found at $skel_root"

  local rel d
  while IFS= read -r rel; do
    [[ -z $rel || $rel == "." ]] && continue
    d="$target/proposals/$year-$gtype/${rel#./}"
    if [[ ! -d $d ]]; then
      mkdir -p "$d"
      touch "$d/.gitkeep"
      log "added: $d/"
    else
      log "skip (exists): $d/"
    fi
  done < <(cd "$skel_root" && find . -mindepth 1 -type d)

  # CLAUDE.md と README.md の {{YEAR}}/{{GRANT_TYPE}} を置換（プレースホルダが残っていれば）
  local f
  for f in "$target/CLAUDE.md" "$target/README.md"; do
    if [[ -f $f ]] && grep -q '{{YEAR}}\|{{GRANT_TYPE}}' "$f"; then
      substitute_in_file "$f" YEAR "$year" GRANT_TYPE "$gtype"
      log "substituted YEAR/GRANT_TYPE in: $f"
    fi
  done
}

# ---------- add-papis-lib ----------

# ライブラリ実体はリポジトリの外に置く。出版社版 PDF を含むため、ワークツリー内にあると
# コード公開時に著作物の再配布になる（papis-conventions.md）。
cmd_add_papis_lib() {
  local name= lib=
  while [[ $# -gt 0 ]]; do
    case $1 in
      --name)    name=$2; shift 2 ;;
      --library) lib=$2; shift 2 ;;  # 既定はプロジェクト名
      *) err "add-papis-lib: unknown option $1" ;;
    esac
  done
  [[ -z $name ]] && err "add-papis-lib: --name required"
  [[ -z $lib ]] && lib=$name

  local target="$PROJECTS_ROOT/$name"
  [[ ! -d $target ]] && err "add-papis-lib: $target does not exist (run adopt first)"

  local lib_dir="$PAPIS_ROOT/$lib"
  if [[ ! -d $lib_dir ]]; then
    mkdir -p "$lib_dir"
    log "added: $lib_dir/"
  else
    log "skip (exists): $lib_dir/"
  fi

  # papis config に section を追記（既にあればスキップ）
  mkdir -p "$(dirname "$PAPIS_CONFIG")"
  touch "$PAPIS_CONFIG"
  if grep -q "^\[$lib\]" "$PAPIS_CONFIG" 2>/dev/null; then
    log "skip (exists in papis config): [$lib]"
  else
    printf '\n[%s]\ndir = %s\n' "$lib" "$lib_dir" >> "$PAPIS_CONFIG"
    log "papis: registered library [$lib] -> $lib_dir"
  fi

  # CLAUDE.md の {{PAPIS_LIB_NAME}} を置換
  local f="$target/CLAUDE.md"
  if [[ -f $f ]] && grep -q '{{PAPIS_LIB_NAME}}' "$f"; then
    substitute_in_file "$f" PAPIS_LIB_NAME "$lib"
    log "substituted PAPIS_LIB_NAME in: $f"
  fi
}

# ---------- add-obsidian-note ----------

cmd_add_obsidian_note() {
  local name= rep= aff= phase=
  while [[ $# -gt 0 ]]; do
    case $1 in
      --name)           name=$2; shift 2 ;;
      --representative) rep=$2; shift 2 ;;
      --affiliation)    aff=$2; shift 2 ;;
      --phase)          phase=$2; shift 2 ;;
      *) err "add-obsidian-note: unknown option $1" ;;
    esac
  done
  [[ -z $name ]] && err "add-obsidian-note: --name required"

  local note="$VAULT_ROOT/projects/$name.md"

  if [[ ! -d "$VAULT_ROOT/projects" ]]; then
    err "add-obsidian-note: $VAULT_ROOT/projects/ does not exist"
  fi

  if [[ -e $note ]]; then
    printf 'warning: %s already exists — preserving existing note (no changes)\n' "$note" >&2
    return 0
  fi

  local today
  today=$(date +%Y-%m-%d)

  cp "$SCRIPT_DIR/obsidian-project-note.md.template" "$note"
  substitute_in_file "$note" \
    PROJECT_NAME "$name" \
    REPRESENTATIVE "$rep" \
    AFFILIATION "$aff" \
    PHASE "$phase" \
    TODAY "$today"

  log "added: $note"
}

# ---------- usage / dispatch ----------

usage() {
  cat <<EOF
Usage: $0 <subcommand> [options]

Subcommands:
  adopt              --name NAME [--representative "氏名"] [--project-name "正式名"]
  add-proposal       --name NAME --year YYYY --grant-type 種別
  add-papis-lib      --name NAME [--library ライブラリ名]
  add-obsidian-note  --name NAME [--representative "氏名"] [--affiliation "所属"] [--phase 現フェーズ]

Environment:
  PROJECTS_ROOT  default: ~/work/projects
  VAULT_ROOT     default: Obsidian iCloud Vault
  PAPIS_ROOT     default: ~/Documents/papis
  PAPIS_CONFIG   default: ~/Library/Application Support/papis/config

EOF
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 0; }
  local sub=$1; shift
  case $sub in
    adopt)             cmd_adopt "$@" ;;
    add-proposal)      cmd_add_proposal "$@" ;;
    add-papis-lib)     cmd_add_papis_lib "$@" ;;
    add-obsidian-note) cmd_add_obsidian_note "$@" ;;
    -h|--help|help)    usage ;;
    *) err "unknown subcommand: $sub" ;;
  esac
}

main "$@"
