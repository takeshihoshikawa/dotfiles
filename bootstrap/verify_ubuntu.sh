#!/usr/bin/env bash
#
# gpu 計算機が setup_ubuntu.sh の想定どおりかを調べる（読み取り専用。何も変更しない）。
# 既存機でも新機でも流せる。実機からの差分確認は
#   ssh <host> bash -s < bootstrap/verify_ubuntu.sh
# FAIL が1つでもあれば終了コード 1。WARN は任意項目・手動手順の未了。
set -u

export PATH="$HOME/.local/bin:$PATH"   # 非対話 ssh では uv が PATH に無い
fail=0
ok()   { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- 基本 ---
[ "$(uname -m)" = x86_64 ] && ok "x86_64" || bad "x86_64 ではない"
. /etc/os-release
[ "${VERSION_CODENAME:-}" = noble ] && ok "Ubuntu 24.04" || bad "Ubuntu 24.04 ではない: ${PRETTY_NAME:-?}"

# --- 名前（豆系。ホスト名と Tailscale のマシン名を同じにする） ---
host="$(hostname)"
case "$host" in
  robusta|arabica) ok "ホスト名: $host" ;;
  *) warn "ホスト名が想定外: $host（robusta／arabica 以外。改名前なら想定どおり）" ;;
esac
ts="$(tailscale status --self --json 2>/dev/null | jq -r '.Self.HostName // empty')"
if [ -n "$ts" ]; then [ "$ts" = "$host" ] && ok "Tailscale のマシン名 = ホスト名" || warn "Tailscale のマシン名($ts)がホスト名($host)と違う: sudo tailscale set --hostname=$host"; fi

# --- 作業領域 ---
if mountpoint -q /work; then
  t="$(findmnt -no FSTYPE /work)"
  [ "$t" = ext4 ] && ok "/work は別パーティション (ext4)" || warn "/work は別パーティションだが ext4 ではない: $t"
else
  bad "/work が別パーティションとしてマウントされていない"
fi
for d in projects data runs tools; do [ -d "/work/$d" ] && ok "/work/$d" || bad "/work/$d が無い"; done
[ "$(readlink "$HOME/work" 2>/dev/null)" = /work ] && ok "~/work -> /work" || bad "~/work -> /work のリンクが無い"
if [ -L /work/tmp ] && [ -d /work/tmp ]; then ok "/work/tmp -> $(readlink /work/tmp)"; else warn "/work/tmp（一時データ用ディスク）が未設定"; fi
if findmnt /mnt/scratch >/dev/null 2>&1; then ok "/mnt/scratch (automount: $(findmnt -no FSTYPE /mnt/scratch | head -1))"; else warn "/mnt/scratch が未設定（共用 HDD を使わないなら無視）"; fi

# --- gpu_run.py の前提 ---
[ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" = yes ] && ok "linger（ログアウト後もジョブが生きる）" || bad "linger が無効: sudo loginctl enable-linger $USER"
systemctl --user show-environment >/dev/null 2>&1 && ok "systemd --user が使える" || bad "systemd --user が使えない"
[ "$(sysctl -n vm.swappiness 2>/dev/null)" = 10 ] && ok "vm.swappiness=10" || warn "vm.swappiness が 10 ではない"

# --- コマンド ---
for c in git tmux rsync curl cmake jq uv gh aws docker R Rscript tailscale nvidia-smi nvidia-ctk; do
  have "$c" && ok "$c" || bad "$c が無い"
done
Rscript -e 'quit(status = !requireNamespace("renv", quietly = TRUE))' >/dev/null 2>&1 && ok "R: renv" || bad "R: renv が無い"

# --- GPU / Docker ---
nvidia-smi -L >/dev/null 2>&1 && ok "GPU: $(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | head -1)" || bad "nvidia-smi が GPU を認識しない（再起動前なら正常）"
id -nG | tr ' ' '\n' | grep -qx docker && ok "docker グループ" || bad "docker グループに入っていない（再ログインが要る場合あり）"
docker info 2>/dev/null | grep -q 'Runtimes:.*nvidia' && ok "Docker の nvidia runtime" || bad "Docker に nvidia runtime が無い: sudo nvidia-ctk runtime configure --runtime=docker"

# --- ネットワーク / 認証 ---
{ systemctl is-active --quiet ssh || systemctl is-active --quiet ssh.socket; } && ok "sshd" || bad "sshd が動いていない"
tailscale status >/dev/null 2>&1 && ok "tailscale 接続" || warn "tailscale が未接続: sudo tailscale up"
systemctl is-enabled --quiet mnt-public.automount 2>/dev/null && ok "NAS automount (/mnt/public)" || warn "NAS automount が未設定"
sudo -n grep -q CHANGE_ME /etc/cifs-tsc.cred 2>/dev/null && warn "NAS のパスワードが未記入（/etc/cifs-tsc.cred）"
gh auth status >/dev/null 2>&1 && ok "gh 認証" || warn "gh 未認証: gh auth login"
aws sts get-caller-identity >/dev/null 2>&1 && ok "aws 認証" || warn "aws 未認証: aws login"
[ -n "$(git config --global user.name)" ] && ok "git user.name" || bad "git の user.name が無い"
[ -e ~/.ssh/id_ed25519 ] && ok "ssh 鍵 (GitHub 用)" || bad "~/.ssh/id_ed25519 が無い"
[ -e ~/.ssh/id_ed25519_qnap ] && ok "ssh 鍵 (QNAP 用)" || warn "~/.ssh/id_ed25519_qnap が無い"

# --- デュアルブート ---
if [ -d /sys/firmware/efi ]; then
  if have mokutil && mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then warn "Secure Boot が有効（NVIDIA ドライバに MOK 登録が要る）"; else ok "Secure Boot: 無効"; fi
  first="$(efibootmgr 2>/dev/null | sed -n 's/^BootOrder: *\([0-9A-Fa-f]*\).*/\1/p')"
  if [ -n "$first" ]; then
    efibootmgr 2>/dev/null | grep -q "^Boot$first\*\? *.*ubuntu" \
      && ok "UEFI の起動順は Ubuntu が先頭" || warn "UEFI の起動順の先頭が Ubuntu ではない（Windows の更新で戻ることがある）"
  fi
fi

# --- 参考情報 ---
[ -f /var/run/reboot-required ] && warn "再起動が必要（保留中のカーネル更新など）"
n="$(apt list --upgradable 2>/dev/null | grep -c upgradable)"; echo "INFO  更新可能なパッケージ: $n"

exit "$fail"
