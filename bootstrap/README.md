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

---

## Setup (Ubuntu)

```bash
git clone https://github.com/takeshihoshikawa/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap/setup_ubuntu.sh
```

This script:
- Installs system packages (incl. `cifs-utils`), R, development libraries
- Sets up `/work/{projects,data,tmp}`
- Links shared dotfiles via `stow` (git, ssh, claude, codex)
- Sets up NAS CIFS automount via `setup_nas_mount.sh`（下記参照）

After setup:
```bash
sudo reboot
```

After reboot, verify GPU (if applicable):
```bash
nvidia-smi
```

Login to Tailscale:
```bash
sudo tailscale up
```

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
