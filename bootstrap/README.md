## Stow packages

| パッケージ | 対象OS | 内容 |
|-----------|--------|------|
| `git` | 全OS | `.gitconfig` |
| `ssh` | 全OS | `.ssh/config` |
| `claude` | 全OS | `.claude/` |
| `codex` | 全OS | `.codex/` |
| `zsh` | mac のみ | `.zshrc` |
| `brew` | mac のみ | `Brewfile` |
| `aws` | mac のみ | `.aws/config` |
| `vscode` | mac のみ | VSCode `settings.json` |

> **注**: `~/.claude/settings.local.json` は gitignore 済みのため新マシンでは手動で作成すること（ローカル専用設定を記述）。
>
> **Ubuntu（gpu 計算機）は stow を使わない**（2026-10-22 変更）。Mac から ssh で操作する実行専用機で、Claude Code・Codex・エディタのサーバ・dotfiles の clone は置かない。必要な git / ssh / aws の設定は `setup_ubuntu.sh` が実ファイルとして作る。上の表の「全OS」は Mac と EC2 を指す。

---

## Setup (Ubuntu / gpu 計算機)

想定は Windows とのデュアルブート機（Windows 専用 SSD ＋ Ubuntu 用 SSD ＋ 共用 HDD）。実行専用機なので dotfiles は clone せず、Mac から必要なファイルだけ送って流す。

### 1. OS インストール時（手作業）

- Windows の SSD には触らない（パーティション操作の対象から外す。可能なら物理的に外す）。ブートローダは Ubuntu 用 SSD 側の EFI に入れる
- Ubuntu 用 2TB SSD を分ける: EFI 1GB ／ `/` 約300GB（ext4）／ `/work` 残り全部（ext4、約1.7TB）。OS を入れ直しても作業データが残るよう `/work` を分けておく
- UEFI で Secure Boot を無効にする（NVIDIA ドライバの MOK 登録は実機の画面前でしかできない）。Windows が BitLocker／デバイス暗号化なら、先に回復キーを控える
- Windows 側: 高速スタートアップと休止状態を無効化する（共用 HDD の NTFS に汚れフラグが残り、Ubuntu から読み書きできなくなる）。時計のずれを避けるためレジストリ `HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\RealTimeIsUniversal`（DWORD）を `1` にする

### 2. ディスクを登録（`setup_ubuntu_disks.sh`）

パーティションの作成・フォーマットは**しない**。fstab への登録とマウントだけを行う。

```bash
bash setup_ubuntu_disks.sh                                      # 候補の UUID を一覧
bash setup_ubuntu_disks.sh --work UUID=... --scratch UUID=...   # 追記する内容の確認（dry-run）
bash setup_ubuntu_disks.sh --work UUID=... --scratch UUID=... --apply
```

- `/work`: ext4。`gpu_run.py` の `/work/projects`・`/work/runs`、Docker の bind mount 元はすべてここ
- `/mnt/scratch`: Windows と共用の HDD（NTFS／exFAT）。**一時データ（interim）専用**で、`/work/tmp` はここへのリンク。Git リポジトリ・`.venv`・Docker のデータは置かない（権限・シンボリックリンク・実行ビットが効かない）。未マウント時に SSD へ書き込む事故を防ぐため、マウントポイントに `chattr +i` を掛ける

### 3. セットアップ本体（Mac から送って実行）

```bash
rsync -a --exclude .git ~/dotfiles/bootstrap ~/dotfiles/ssh ~/dotfiles/git <host>:/tmp/dotfiles-bootstrap/
ssh -t <host> NEW_HOSTNAME=arabica bash /tmp/dotfiles-bootstrap/bootstrap/setup_ubuntu.sh
```

`NEW_HOSTNAME` は必須。機械の名前は**豆系**（GPU 機は `robusta`・`arabica`、Mac は飲み物系）で、ホスト名と Tailscale のマシン名を同じにする。`gpu-remote` は実行機という役割名で、`ssh gpu-remote` は robusta の別名（`ssh/.ssh/includes/gpu-remote.conf`）。

最初に `x86_64`・Ubuntu 24.04・`/work` のマウント・Secure Boot 無効を検査し、満たさなければ何も変更せず止まる。冪等で、入っているものは飛ばす。

This script:
- Installs system packages (incl. `cifs-utils`, `ntfs-3g`, `fonts-noto-cjk`), R (+`renv`), Python `uv`, development libraries
- Installs Docker + NVIDIA Container Toolkit（GPU コンテナ解析用）、`gh`、`awscli`、Tailscale
- Sets `vm.swappiness=10`（解析ワークロードでスワップを避けるチューニング）
- Enables linger（`loginctl enable-linger`。`gpu_run.py` が `systemd-run --user` でジョブを切り離すための必須前提）
- Sets the hostname（`NEW_HOSTNAME`）
- Sets up `/work/{projects,data,runs,tools}` と `~/work -> /work`
- Writes `~/.gitconfig`・`~/.ssh/config`（GitHub と QNAP のみ）・`~/.aws/config`、この機械専用の SSH 鍵を新規に作る（他の機械の鍵・認証情報は持ち込まない）
- Sets up NAS CIFS automount via `setup_nas_mount.sh`（下記参照）
- Installs the recommended NVIDIA driver（版を固定するときは `NVIDIA_DRIVER=nvidia-driver-595-open` のように渡す）

Quarto・`texlive-full`・`pandoc` は入れない（原稿のレンダリングは Mac で行う）。

### 4. 再起動後（手作業・この順）

```bash
sudo reboot
nvidia-smi                                                                    # GPU の確認
sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker
sudo tailscale up --hostname="$(hostname)"                                  # マシン名をホスト名と同じにする
sudoedit /etc/cifs-tsc.cred                                                   # NAS のパスワードを記入
gh auth login
aws login                                                                     # または aws configure
```

公開鍵（`~/.ssh/id_ed25519.pub` を GitHub へ、`~/.ssh/id_ed25519_qnap.pub` を QNAP へ）を登録する。Mac 側は `ssh/.ssh/includes/gpu-remote.conf` に `Host arabica` が入っている。初回接続で `known_hosts` に登録する（`ssh -o StrictHostKeyChecking=accept-new arabica true`）。もう1台の Mac は dotfiles を pull するまで古い設定のまま。

### 5. 確認（`verify_ubuntu.sh`）

```bash
ssh <host> bash -s < ~/dotfiles/bootstrap/verify_ubuntu.sh
```

読み取り専用。PASS／WARN／FAIL を出し、FAIL があれば終了コード 1。既存機に流して「スクリプトの想定とずれていないか」を見るのにも使う。ずれを見つけたら、機械ではなくスクリプトかこの README を直す。

### 既存機の改名（旧名 `my-ubuntu` → `robusta`）

ジョブが走っていないこと（`gpu_run.py --status`）を確かめてから、実機のターミナルで:

```bash
sudo hostnamectl set-hostname robusta && sudo sed -i 's/^127\.0\.1\.1.*/127.0.1.1 robusta/' /etc/hosts && sudo tailscale set --hostname=robusta
```

次に **Tailscale の管理画面**（Machines → 該当機の `…` → Edit machine name → 「Use OS hostname」か `robusta`）でマシン名を直す。`tailscale set --hostname` だけでは MagicDNS 名が変わらないことがある（2026-10-22 の実機で、OS のホスト名は変わったが DNS 名は `my-ubuntu` のままだった）。`tailscale status` の名前が `robusta` になったのを確かめてから、Mac で `ssh/.ssh/includes/gpu-remote.conf` の `HostName my-ubuntu` を `HostName robusta` に直し、`ssh -o StrictHostKeyChecking=accept-new robusta true` で `known_hosts` に登録し、`gpu_run.py --status` と `verify_ubuntu.sh` で確かめる。改名前は `robusta` も `gpu-remote` も `my-ubuntu` へつながる。

### デュアルブートの注意

- Windows を起動している間は Tailscale も ssh も落ち、`gpu_run.py` のジョブも止まる。UEFI の起動順は Ubuntu を先頭にし、停電復帰時の自動起動を有効にする。Windows の大型更新で起動順が戻ることがあるので、`verify_ubuntu.sh` の起動順の項目で確かめる
- 共用 HDD を Windows から使ったあと Ubuntu でマウントできないときは、Windows を「再起動」ではなく「シャットダウン」してから起動し直す

### NAS mount (`setup_nas_mount.sh`)

QNAP の `Public` 共有を **Tailscale MagicDNS 名経由**で `/mnt/public` に CIFS automount する（在宅・外出どちらでも同じアドレス、LAN 内は直結。アクセス時マウント＋アイドル自動アンマウント）。`setup_ubuntu.sh` から自動で呼ばれるが、単体でも再実行できる:

```bash
bash ~/dotfiles/bootstrap/setup_nas_mount.sh
```

> **注（必須手順）**: 資格情報ファイル `/etc/cifs-tsc.cred` は**テンプレのみ生成**される（平文パスワードは git に置けないため）。マウントには `sudo tailscale up` の後、パスワードの記入が必要:
> ```bash
> sudoedit /etc/cifs-tsc.cred     # password=CHANGE_ME を実パスワードに
> ls /mnt/public && findmnt /mnt/public   # アクセスで自動マウント発火 → 確認
> ```
> NAS ホスト・共有名・マウント先・SMB ユーザー等はスクリプト冒頭の変数（`TSC_NAS_HOST` 等の env でも上書き可）で調整する。`TSC_NAS_ROOT=/mnt/public` は `~/.bashrc` に追記され、各プロジェクトの `sync_with_nas.sh`（既定は Mac の `/Volumes/Public`）がマウント先を吸収する。

### Uplink failover (`setup_uplink_failover.sh`)

「リンクは生きているのに上流が転送してくれない」型の障害からの自動復旧と、障害時の層別の証拠ロガーを systemd サービスとして設置する。

対象とする障害の署名は、キャリア UP・IP・デフォルト経路すべて正常でゲートウェイまで ping も通るのに、その先だけが全滅し、L2/DHCP を再アタッチする（ケーブル抜き差し等）まで戻らないというもの。ネットワーク管理デーモンは異常と認識しないためログを出さず、**経路メトリックによる自動フェイルオーバも働かない**（リンクが生きて見えるため）。副回線へ逃がすには主回線を明示的に落とす必要があり、それをやるのがこのサービス。

```bash
bash ~/dotfiles/bootstrap/setup_uplink_failover.sh
```

動作は二段構え。遮断を既定3分検知したら、段1で主回線のリンクを down/up（＝抜き差し相当）を最大2回、それでも直らなければ段2で**主回線を down のまま保持して副回線へ退避**し、30分ごとに主回線の回復を確認する。

```bash
sudo tail -f /var/log/uplink-recover.log   # 復旧動作
sudo tail -f /var/log/uplink-watch.log     # 障害時にどの層が落ちているか
```

インタフェースとゲートウェイはデフォルト経路から自動判定される。閾値等を変えたい場合のみ `/etc/uplink-failover.conf`（コメントアウト済みのテンプレートが生成される）を編集する。

> **注**: 段2を使うには副回線が要る。有線＋無線の2本立てにする netplan の例が `netplan-dual-uplink.yaml.example`。**実値（SSID・パスワード）を書いたものは資格情報を含むため git に入れないこと**（`.gitignore` で `netplan-*.yaml` を除外済み）。副回線にデフォルト経路が無いうちは段2に移らず、段1だけを試す。段2の退避中は主回線が down するため、同一セグメントの NAS 等には届かなくなる。

---

## Setup (macOS)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/takeshihoshikawa/dotfiles/main/bootstrap/setup_mac.sh)"
```

This script:
- Installs Homebrew (if not already installed)
- Clones dotfiles to `~/dotfiles`
- Creates `~/.ssh`, `~/.aws`, `~/work/{projects,data,tmp}` directories
- Installs packages from Brewfile
- Links dotfiles via `stow` (ssh, aws, git, zsh, brew, claude, codex, vscode)
- Registers daily-report reminder (weekdays 16:33, notify only when Mac is awake) via launchd (not stowed — installed directly to `~/.local/bin/` and `~/Library/LaunchAgents/`)
- Installs R `renv` package

### 鍵と認証情報（クリーンインストールの後）

Mac の鍵も Ubuntu 機と同じく、**作り直して公開鍵を登録し直す**（2026-10-29 決定）。秘密鍵・`~/.aws/credentials` は dotfiles に入れない。
例外は lidar_pi の鍵だけで、Apple の「パスワード」アプリにメモとして残す。Pi がパスワードでのログインを切っていると、鍵を無くしたら SD カードを抜くまで入れなくなるため。

| 鍵・認証情報 | 使い道 | 登録し直す先 |
|---|---|---|
| `~/.ssh/id_ed25519_lidar_pi` | LiDAR の Raspberry Pi（`lidar-pi`） | 作り直さない。「パスワード」アプリから戻す |
| `~/.ssh/id_ed25519_qnap` | メイン NAS（`qnap`） | QNAP の管理画面で `authorized_keys` に足す |
| `~/.ssh/id_ed25519_windows` | Windows 機（`iwata`） | 職場で Windows にログインし、`authorized_keys` に足す |
| `~/.ssh/harvest_mirror_deploy` | harvest-accessibility の deploy key | GitHub のリポ設定（Deploy keys）で差し替える |
| `~/.aws/credentials` の `[default]` | AWS | IAM コンソールでアクセスキーを作り直し、古いキーを無効にする（`aws configure`） |
| GitHub 本体 | HTTPS と `gh` | `gh auth login`（SSH 鍵は使っていない） |

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_qnap -C "$(hostname -s)-qnap"   # windows・harvest_mirror_deploy も名前を変えて同じ
```

- Pi にパスワードでログインできるかは未確認（2026-10-29）。
- `ssh/.ssh/includes/github.conf` は実在しない `~/.ssh/id_ed25519` を指している。GitHub は HTTPS なので実害は無い。

---

## Academic Secretaryの共通手順

朝の計画・日報・週次レビューの正本は [academic-secretaryのreferences](../codex/plugins/academic-secretary/references/) にある `morning-workflow.md` / `daily-report-workflow.md` / `weekly-review-workflow.md`。共通の操作・保存形式はここだけで更新する。

Claudeの `claude/.claude/skills/{morning,daily-report,weekly-review}/SKILL.md` は `~/dotfiles` の同じ正本を読む入口。Work/Codexの `codex/plugins/academic-secretary/skills/` はパッケージ内の同じ正本を読み、実行プロファイルと会話の引継ぎだけを持つ。Claudeを使うマシンではdotfiles全体を取得し、共通手順だけを別の場所へコピーしない。

変更時は入口の形式と参照先を検証する。配布済みプラグインはインストール時点のコピーなので、配布元の更新とアプリ側での更新適用は別の操作。キャッシュを直接編集せず、アプリ側の適用後に配布元と内容を照合する。
