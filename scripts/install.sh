#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  pwd
)"

skill_src="$repo_root/skills/say"
skill_dest="${CODEX_HOME:-$HOME/.codex}/skills/say"
bin_dir="$HOME/.local/bin"

mkdir -p "$(dirname "$skill_dest")" "$bin_dir"
rm -rf "$skill_dest"
cp -R "$skill_src" "$skill_dest"
chmod +x "$skill_dest/scripts/codex-say"

ln -sf "$skill_dest/scripts/codex-say" "$bin_dir/codex-say"
ln -sf "$skill_dest/scripts/codex-say" "$bin_dir/saychat"
ln -sf "$skill_dest/scripts/codex-say" "$bin_dir/readchat"

echo "Installed Say skill to $skill_dest"
echo "Linked codex-say, saychat, and readchat in $bin_dir"
echo "Try: codex-say --dry-run --speed 1.5x 'hello'"
