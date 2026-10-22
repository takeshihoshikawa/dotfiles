#!/usr/bin/env bash
#
# gpu 計算機のディスクを fstab に登録する。パーティションの作成・フォーマットはしない
# （Windows と同居する機械で、書式化を自動化すると取り返しがつかないため。OS インストール時に手で作る）。
#
#   /work         Ubuntu 用 SSD の ext4 パーティション（作業領域。永続）
#   /mnt/scratch  Windows と共用の HDD（NTFS または exFAT。一時データ＝interim 専用）
#                 /work/tmp はここへのリンクにする
#
# 使い方:
#   setup_ubuntu_disks.sh                                        # 候補の一覧だけ（何も変更しない）
#   setup_ubuntu_disks.sh --work UUID=... --scratch UUID=...     # 追記する内容の表示だけ（dry-run）
#   setup_ubuntu_disks.sh --work UUID=... --scratch UUID=... --apply
#
# --work と --scratch はどちらか片方だけでもよい。冪等（fstab に UUID があれば追記しない）。
set -euo pipefail

WORK_UUID=""
SCRATCH_UUID=""
APPLY=0
WORK_MOUNT=/work
SCRATCH_MOUNT=/mnt/scratch
SCRATCH_SUBDIR=ubuntu-tmp   # HDD の中で Ubuntu が使うディレクトリ（Windows 側のファイルと混ぜない）

while [ $# -gt 0 ]; do
  case "$1" in
    --work)    WORK_UUID="${2#UUID=}"; shift 2 ;;
    --scratch) SCRATCH_UUID="${2#UUID=}"; shift 2 ;;
    --apply)   APPLY=1; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "ERROR: 不明な引数: $1" >&2; exit 2 ;;
  esac
done

echo "--- ブロックデバイス ---"
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS
if [ -z "$WORK_UUID" ] && [ -z "$SCRATCH_UUID" ]; then
  echo
  echo "上の UUID を --work / --scratch に渡す。Windows の SSD（ntfs で EFI と MSR を持つもの）は指定しない。"
  exit 0
fi

fstype_of() { lsblk -rno FSTYPE "/dev/disk/by-uuid/$1" 2>/dev/null | head -1; }
in_fstab()  { grep -qE "^[[:space:]]*UUID=$1[[:space:]]" /etc/fstab; }

lines=()

if [ -n "$WORK_UUID" ]; then
  t="$(fstype_of "$WORK_UUID")"
  [ "$t" = "ext4" ] || { echo "ERROR: --work $WORK_UUID は ext4 ではない（検出: '${t:-なし}'）。作業領域は ext4 で作る。" >&2; exit 1; }
  if in_fstab "$WORK_UUID"; then
    echo "work: fstab に登録済み。飛ばす。"
  else
    # 中身のあるディレクトリの上にマウントすると、元のファイルが隠れる
    if ! mountpoint -q "$WORK_MOUNT" && [ -d "$WORK_MOUNT" ] && [ -n "$(ls -A "$WORK_MOUNT" 2>/dev/null)" ]; then
      echo "ERROR: $WORK_MOUNT に既にファイルがある。マウントすると隠れるので、先に退避する。" >&2; exit 1
    fi
    lines+=("UUID=$WORK_UUID $WORK_MOUNT ext4 defaults,nofail 0 2")
  fi
fi

if [ -n "$SCRATCH_UUID" ]; then
  t="$(fstype_of "$SCRATCH_UUID")"
  uid="$(id -u)"; gid="$(id -g)"
  case "$t" in
    ntfs)  opts="uid=$uid,gid=$gid,umask=022,windows_names,nofail,x-systemd.automount,x-systemd.idle-timeout=600"; fs=ntfs3 ;;
    exfat) opts="uid=$uid,gid=$gid,umask=022,nofail,x-systemd.automount,x-systemd.idle-timeout=600"; fs=exfat ;;
    *) echo "ERROR: --scratch $SCRATCH_UUID は NTFS/exFAT ではない（検出: '${t:-なし}'）。" >&2; exit 1 ;;
  esac
  if in_fstab "$SCRATCH_UUID"; then
    echo "scratch: fstab に登録済み。飛ばす。"
  else
    lines+=("UUID=$SCRATCH_UUID $SCRATCH_MOUNT $fs $opts 0 0")
  fi
fi

echo
echo "--- /etc/fstab に追記する行 ---"
if [ ${#lines[@]} -eq 0 ]; then echo "(なし)"; else printf '%s\n' "${lines[@]}"; fi

if [ "$APPLY" -ne 1 ]; then
  echo
  echo "dry-run のため何も変更していない。反映するには --apply を付ける。"
  exit 0
fi

if [ ${#lines[@]} -gt 0 ]; then
  sudo cp -a /etc/fstab "/etc/fstab.bak-$(date +%Y%m%d-%H%M%S)"
  printf '%s\n' "${lines[@]}" | sudo tee -a /etc/fstab > /dev/null
  sudo systemctl daemon-reload
fi

if [ -n "$WORK_UUID" ]; then
  sudo mkdir -p "$WORK_MOUNT"
  mountpoint -q "$WORK_MOUNT" || sudo mount "$WORK_MOUNT"
  sudo chown "$USER:$USER" "$WORK_MOUNT"
  findmnt "$WORK_MOUNT"
fi

if [ -n "$SCRATCH_UUID" ]; then
  sudo mkdir -p "$SCRATCH_MOUNT"
  # 未マウントのときに SSD へ書き込んでしまう事故を防ぐ（マウント中はこの属性は見えない）
  mountpoint -q "$SCRATCH_MOUNT" || sudo chattr +i "$SCRATCH_MOUNT"
  # アクセスで automount を起動する。失敗の典型は、Windows の高速スタートアップ／休止状態による
  # NTFS の汚れフラグ。Windows 側で無効化してからシャットダウンし直す。
  if ! mkdir -p "$SCRATCH_MOUNT/$SCRATCH_SUBDIR"; then
    echo "ERROR: $SCRATCH_MOUNT をマウントできない。Windows の高速スタートアップと休止状態を無効にして、" >&2
    echo "       Windows を『再起動』ではなく『シャットダウン』してから Ubuntu を起動し直す。" >&2
    exit 1
  fi
  ln -sfn "$SCRATCH_MOUNT/$SCRATCH_SUBDIR" "$WORK_MOUNT/tmp"
  findmnt "$SCRATCH_MOUNT"
fi

echo "完了。verify_ubuntu.sh で確認する。"
