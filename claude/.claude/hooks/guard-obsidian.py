#!/usr/bin/env python3
"""
PreToolUse guard: block raw mv/rm/rmdir/trash inside the Obsidian vault.

Direct filesystem moves/renames/deletes break wikilinks, backlinks, and
properties. Structural changes must go through the `obsidian` CLI so the
Obsidian runtime keeps links intact.

Hook contract: exit 0 = allow, exit 2 = block (stderr is returned to Claude).
"""
import json
import re
import sys

# The iCloud container path is so distinctive that a plain substring match is safe.
ICLOUD_HINT = "iCloud~md~obsidian"

# The ~/vault symlink, anchored to the home root so unrelated dirs named "vault"
# elsewhere (e.g. ~/code/vault) are NOT matched. Trailing slash is optional, so
# both `rm ~/vault/foo.md` and `cd ~/vault && rm foo.md` are caught.
# Known limit: env-var indirection like `cd "$VAULT" && rm` can't be detected.
VAULT_ROOT = re.compile(r"(?:~|\$HOME|/Users/[^/\s]+)/vault(?:/|\b)")

DESTRUCTIVE = re.compile(r"\b(mv|rm|rmdir|trash|trash-put)\b")


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # can't parse input -> don't interfere

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    cmd = (data.get("tool_input") or {}).get("command", "")
    if not cmd:
        sys.exit(0)

    # git commands cannot directly modify vault files; skip to avoid false
    # positives from commit messages that describe vault operations.
    if re.match(r"\s*git\b", cmd):
        sys.exit(0)

    if not DESTRUCTIVE.search(cmd):
        sys.exit(0)

    if ICLOUD_HINT not in cmd and not VAULT_ROOT.search(cmd):
        sys.exit(0)  # destructive, but not targeting the vault -> allow

    sys.stderr.write(
        "Blocked: raw mv/rm/rmdir/trash inside the Obsidian vault breaks "
        "wikilinks, backlinks, and properties.\n"
        "Route structural changes through the Obsidian CLI so the runtime "
        "updates links:\n"
        "  - rename/move a note: `obsidian move ...`\n"
        "  - delete a note: `obsidian delete ...`\n"
        "  - other structural ops: run `obsidian help` to find the command\n"
        "Confirm exact arguments with `obsidian help <command>` before "
        "retrying (the Obsidian app must be running).\n"
    )
    sys.exit(2)


if __name__ == "__main__":
    main()
