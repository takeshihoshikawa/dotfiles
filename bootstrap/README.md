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
- Installs system packages, R, development libraries
- Sets up `/work/{projects,data,tmp}`
- Links shared dotfiles via `stow` (git, ssh, claude, codex)

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
