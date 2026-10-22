#!/usr/bin/env bash
#
# gpu 計算機（Ubuntu 24.04 / x86_64）のセットアップ。
# Mac から ssh で操作する実行専用機で、Claude Code・Codex・エディタのサーバ・dotfiles は置かない。
#
# 使い方（Mac から、dotfiles の bootstrap/ と ssh/ だけを送って流す）:
#   rsync -a --exclude .git ~/dotfiles/bootstrap ~/dotfiles/ssh ~/dotfiles/git <host>:/tmp/dotfiles-bootstrap/
#   ssh -t <host> bash /tmp/dotfiles-bootstrap/bootstrap/setup_ubuntu.sh
#
# 先に setup_ubuntu_disks.sh で /work（と一時データ用ディスク）を用意しておく。
# 冪等: 何度実行しても安全（入っているものは飛ばす）。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

# --- 前提検査（ここで止まれば何も変更していない） ---------------------------------
[ "$(uname -m)" = "x86_64" ] || { echo "ERROR: x86_64 専用（awscli・Docker の取得先を固定している）"; exit 1; }
. /etc/os-release
[ "${VERSION_CODENAME:-}" = "noble" ] || { echo "ERROR: Ubuntu 24.04 (noble) 専用（CRAN のリポジトリ名を固定している）"; exit 1; }

if ! mountpoint -q /work && [ -z "${ALLOW_WORK_ON_ROOT:-}" ]; then
  echo "ERROR: /work がマウントされていない。先に setup_ubuntu_disks.sh を実行する。"
  echo "       ルートのディスクに /work を作ってよいときだけ ALLOW_WORK_ON_ROOT=1 を付ける。"
  exit 1
fi

# NVIDIA ドライバは Secure Boot が有効だと再起動後に実機の画面前で MOK 登録が要る。
# ssh だけでは完結しないので、無効にしてから流す。
if command -v mokutil >/dev/null && mokutil --sb-state 2>/dev/null | grep -qi 'enabled' && [ -z "${ALLOW_SECURE_BOOT:-}" ]; then
  echo "ERROR: Secure Boot が有効。UEFI 設定で無効にしてから再実行する。"
  echo "       MOK 登録を実機の画面で行うと決めてあるときだけ ALLOW_SECURE_BOOT=1 を付ける。"
  exit 1
fi

# --- システムパッケージ ------------------------------------------------------------
sudo apt update

sudo apt install -y \
  git \
  tmux \
  htop \
  rsync \
  wget \
  curl \
  unzip \
  zip \
  jq \
  tree \
  cifs-utils \
  ntfs-3g \
  efibootmgr \
  mokutil \
  build-essential \
  cmake \
  openssh-server \
  pkg-config \
  software-properties-common \
  dirmngr \
  gpg \
  libgdal-dev \
  libgeos-dev \
  libproj-dev \
  libudunits2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfreetype6-dev \
  fonts-noto-cjk

# R (CRAN)。forest-instance-annotation が renv.lock を持つため残す。
if ! dpkg -s r-base >/dev/null 2>&1; then
  curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
    | gpg --dearmor | sudo tee /usr/share/keyrings/cran.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/cran.gpg] https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" \
    | sudo tee /etc/apt/sources.list.d/cran-r.list > /dev/null
  sudo apt update
  sudo apt install -y r-base r-base-dev
fi

# --- 作業領域 ----------------------------------------------------------------------
# /work はディスクごと別（setup_ubuntu_disks.sh）。ここではディレクトリを作るだけ。
# /work/tmp は一時データ用ディスクへのリンクで、setup_ubuntu_disks.sh が張る。
sudo chown "$USER:$USER" /work
mkdir -p /work/projects /work/data /work/runs /work/tools
# プロジェクト文書が ~/work/projects/... で書かれているのに合わせる
ln -sfn /work "$HOME/work"

# R の重い解析処理でメモリに余裕があるうちからスワップへ逃げないよう抑制する
# (デフォルト 60 は汎用デスクトップ向けで、解析ワークロードには積極的すぎる)
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
sudo sysctl --system > /dev/null

# Windows とのデュアルブート。Ubuntu は RTC を UTC として扱う（既定）が、Windows は既定でローカル時刻として
# 扱うため、切り替えるたびに時計が9時間ずれる。Ubuntu 側は UTC に固定し、Windows 側に
# RealTimeIsUniversal=1 を入れて合わせる（末尾の NOTE 8）。
sudo timedatectl set-local-rtc 0

sudo systemctl enable --now ssh

# systemd --user のジョブをログアウト後も生かす。gpu_run.py（systemd-run --user）の必須前提。
sudo loginctl enable-linger "$USER"

# --- R / Python ツール -------------------------------------------------------------
mkdir -p ~/R/library
if ! grep -q 'R/library' ~/.Rprofile 2>/dev/null; then
  cat << 'EOF' >> ~/.Rprofile
dir.create("~/R/library", recursive = TRUE, showWarnings = FALSE)
.libPaths(c("~/R/library", .libPaths()))
EOF
fi
R -q -e "options(repos='https://cloud.r-project.org'); if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv')"

# uv (Python パッケージマネージャ。data-analysis-coding-conventions.md の標準ツール)
command -v uv >/dev/null || [ -x "$HOME/.local/bin/uv" ] || curl -LsSf https://astral.sh/uv/install.sh | sh

# --- git / ssh / aws の設定（dotfiles は置かないので、必要なものをここで実ファイルにする） -----
# git: dotfiles の git/.gitconfig をそのまま使う（認証は gh の credential helper）
[ -e ~/.gitconfig ] || install -m 644 "$REPO/git/.gitconfig" ~/.gitconfig
[ -e ~/.gitignore_global ] || install -m 644 "$REPO/git/.gitignore_global" ~/.gitignore_global

# ssh: GitHub(443番ポート)と QNAP の接続先だけ。Mac 向けの記述（colima・Keychain・lidar-pi）は持ち込まない
mkdir -p ~/.ssh/includes && chmod 700 ~/.ssh
install -m 644 "$REPO/ssh/.ssh/includes/github.conf" "$REPO/ssh/.ssh/includes/qnap.conf" ~/.ssh/includes/
if [ ! -e ~/.ssh/config ]; then
  cat > ~/.ssh/config << 'EOF'
# gpu 計算機（Ubuntu）用。Mac 向けの記述は含めない。
Include ~/.ssh/includes/*.conf

Host *
  AddKeysToAgent yes
EOF
  chmod 600 ~/.ssh/config
fi
# 鍵はこの機械で新規に作る（他の機械から持ち込まない）。公開鍵の登録は手動（末尾の NOTE）
[ -e ~/.ssh/id_ed25519 ]      || ssh-keygen -t ed25519 -N '' -C "$USER@$(hostname)" -f ~/.ssh/id_ed25519
[ -e ~/.ssh/id_ed25519_qnap ] || ssh-keygen -t ed25519 -N '' -C "$USER@$(hostname)-qnap" -f ~/.ssh/id_ed25519_qnap

# aws: 設定のみ。認証情報は手動（末尾の NOTE）
mkdir -p ~/.aws && chmod 700 ~/.aws
[ -e ~/.aws/config ] || printf '[default]\nregion = ap-northeast-1\noutput = json\n' > ~/.aws/config

# --- gh / awscli -------------------------------------------------------------------
if ! command -v gh >/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update && sudo apt install -y gh
fi

if ! command -v aws >/dev/null; then
  tmp="$(mktemp -d)"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp/awscliv2.zip"
  unzip -q "$tmp/awscliv2.zip" -d "$tmp"
  sudo "$tmp/aws/install"
  rm -rf "$tmp"
fi

# --- Docker + NVIDIA Container Toolkit（GPU コンテナでの解析ワークロード用） --------------
if ! command -v docker >/dev/null; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo usermod -aG docker "$USER"
fi

if ! dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor | sudo tee /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg > /dev/null
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
  sudo apt update
  sudo apt install -y nvidia-container-toolkit
fi
# GPU ドライバは末尾で入れるため、Docker の GPU runtime 設定は再起動後（末尾の NOTE）

# --- Tailscale / NAS ---------------------------------------------------------------
command -v tailscale >/dev/null || curl -fsSL https://tailscale.com/install.sh | sh

# NAS (QNAP Public share) を Tailscale 経由で CIFS automount。
# 資格情報テンプレを作るだけで、パスワード記入までマウントは失敗する。
# tailscale 導入後に呼ぶ（automount は tailscaled.service に依存）。失敗しても全体は止めない。
bash "$HERE/setup_nas_mount.sh" || echo "WARN: setup_nas_mount.sh failed — 後で個別に実行してください"

# --- GPU ドライバ（最後） ----------------------------------------------------------
# 既定は ubuntu-drivers の推奨版。版を固定するときは NVIDIA_DRIVER=nvidia-driver-595-open のように渡す。
echo "--- GPU / 推奨ドライバ ---"
ubuntu-drivers devices || true
if [ -n "${NVIDIA_DRIVER:-}" ]; then
  sudo apt install -y "$NVIDIA_DRIVER"
else
  sudo ubuntu-drivers install
fi

cat << 'EOF'

NOTE: 以降は手動（この順）。
  1. sudo reboot
  2. nvidia-smi で GPU を確認し、Docker の GPU runtime を設定:
       sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker
  3. sudo tailscale up
  4. sudoedit /etc/cifs-tsc.cred       # password=CHANGE_ME を実パスワードに
  5. 公開鍵を登録（GitHub は ~/.ssh/id_ed25519.pub、QNAP は ~/.ssh/id_ed25519_qnap.pub）
  6. gh auth login
  7. aws login（または aws configure）
  8. Windows 側: 高速スタートアップと休止状態を無効化、RealTimeIsUniversal=1
  9. bash <dotfiles>/bootstrap/verify_ubuntu.sh で全項目を確認
EOF
echo "Setup finished."
