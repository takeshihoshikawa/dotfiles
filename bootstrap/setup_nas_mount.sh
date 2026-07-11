#!/usr/bin/env bash
#
# NAS (QNAP `Public` share) を Linux ワークステーションに CIFS automount する再現セットアップ。
# 接続は Tailscale MagicDNS 名経由（在宅・外出どちらでも同じアドレスで届き、LAN 内は直結）。
#
# systemd automount にすることで:
#   - /mnt/public にアクセスした時だけマウント（常時マウントの stale 化を防ぐ）
#   - TimeoutIdleSec でアイドル自動アンマウント（席を離れた際の切断警告を出さない）
#   - nofail + Tailscale 依存で、NAS/Tailscale が落ちていても起動をブロックしない
#
# 冪等: 何度実行しても安全。単体でも setup_ubuntu.sh からでも呼べる。
#
# 実行後、資格情報ファイルのパスワードを手で埋めるまでマウントは失敗する（下記 NOTE 参照）。
set -euo pipefail

# --- 設定（環境に合わせて変更可） ---------------------------------------------
NAS_HOST="${TSC_NAS_HOST:-nas6d4f9b.tailedbc60.ts.net}"  # Tailscale MagicDNS 名
NAS_SHARE="${TSC_NAS_SHARE:-Public}"
MOUNT_POINT="${TSC_NAS_MOUNT:-/mnt/public}"
CRED_FILE="${TSC_NAS_CRED:-/etc/cifs-tsc.cred}"
SMB_USER="${TSC_NAS_USER:-owner}"                        # SMB ユーザー名（パスワードは手で記入）
SMB_VERS="${TSC_NAS_SMB_VERS:-3.1.1}"                    # QNAP が古い場合は 3.0 に下げる
IDLE_SEC="${TSC_NAS_IDLE_SEC:-600}"                      # アイドル自動アンマウントまでの秒数
# -----------------------------------------------------------------------------

uid="$(id -u)"
gid="$(id -g)"
unit_base="$(systemd-escape -p --suffix=mount "$MOUNT_POINT")"      # 例: mnt-public.mount
automount_unit="${unit_base%.mount}.automount"

echo "=== NAS CIFS automount setup ==="
echo "  //$NAS_HOST/$NAS_SHARE -> $MOUNT_POINT (uid=$uid gid=$gid, vers=$SMB_VERS)"

echo "--- cifs-utils ---"
if ! command -v mount.cifs >/dev/null 2>&1; then
  sudo apt update && sudo apt install -y cifs-utils
else
  echo "cifs-utils already installed."
fi

echo "--- mount point ---"
sudo mkdir -p "$MOUNT_POINT"

echo "--- credentials file ($CRED_FILE) ---"
if [ ! -f "$CRED_FILE" ]; then
  # 平文パスワードはリポジトリに置けないため、テンプレのみ生成し手で埋める。
  sudo install -m 600 /dev/null "$CRED_FILE"
  printf 'username=%s\npassword=CHANGE_ME\n' "$SMB_USER" | sudo tee "$CRED_FILE" >/dev/null
  CRED_CREATED=1
else
  echo "$CRED_FILE already exists — leaving as-is."
  CRED_CREATED=0
fi

echo "--- systemd units ---"
sudo tee "/etc/systemd/system/${unit_base}" >/dev/null <<EOF
[Unit]
Description=CIFS mount ${NAS_SHARE} over Tailscale
After=tailscaled.service tailscale-online.target network-online.target
Wants=network-online.target

[Mount]
What=//${NAS_HOST}/${NAS_SHARE}
Where=${MOUNT_POINT}
Type=cifs
Options=credentials=${CRED_FILE},uid=${uid},gid=${gid},iocharset=utf8,vers=${SMB_VERS},_netdev,nofail
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF

sudo tee "/etc/systemd/system/${automount_unit}" >/dev/null <<EOF
[Unit]
Description=Automount ${NAS_SHARE} over Tailscale

[Automount]
Where=${MOUNT_POINT}
TimeoutIdleSec=${IDLE_SEC}

[Install]
WantedBy=multi-user.target
EOF

echo "--- enable automount ---"
sudo systemctl daemon-reload
sudo systemctl enable --now "$automount_unit"

echo "--- TSC_NAS_ROOT (~/.bashrc) ---"
# sync_with_nas.sh はこの env でマウント先を吸収する（既定は Mac の /Volumes/Public）。
if ! grep -q 'TSC_NAS_ROOT' "$HOME/.bashrc" 2>/dev/null; then
  echo "export TSC_NAS_ROOT=${MOUNT_POINT}" >> "$HOME/.bashrc"
  echo "Added: export TSC_NAS_ROOT=${MOUNT_POINT}"
else
  echo "TSC_NAS_ROOT already present in ~/.bashrc — leaving as-is."
fi

echo
echo "Done."
if [ "${CRED_CREATED:-0}" = "1" ]; then
  echo "NOTE: $CRED_FILE のパスワードが 'CHANGE_ME' のままです。マウントは失敗します。"
  echo "      次を実行してパスワードを記入してください（シェル履歴に残さないためエディタ経由）:"
  echo "        sudoedit $CRED_FILE   # または: sudo nano $CRED_FILE"
  echo "      記入後、アクセスで自動マウントを発火して確認:"
  echo "        ls $MOUNT_POINT && findmnt $MOUNT_POINT"
fi
echo "NOTE: 新しいシェルで TSC_NAS_ROOT が有効になります（既存シェルは 'source ~/.bashrc'）。"
