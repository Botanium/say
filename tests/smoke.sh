#!/usr/bin/env bash
set -euo pipefail

repo_root="$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  pwd
)"

helper="$repo_root/skills/say/scripts/codex-say"

bash -n "$helper"
"$helper" --help | grep -q "auto on"
"$helper" --dry-run "hello" | grep -q "Would speak"
"$helper" --dry-run --speed 1x "hello" | grep -q "170 wpm"
"$helper" --dry-run --speed 1.5x "hello" | grep -q "255 wpm"
"$helper" --dry-run --speed 2x "hello" | grep -q "340 wpm"
"$helper" auto status >/dev/null

tmp_config_home="$(mktemp -d)"
XDG_CONFIG_HOME="$tmp_config_home" "$helper" default rate 210 | grep -q "210 wpm"
XDG_CONFIG_HOME="$tmp_config_home" "$helper" default status | grep -q "210 wpm"
XDG_CONFIG_HOME="$tmp_config_home" "$helper" --dry-run "hello" | grep -q "210 wpm"
XDG_CONFIG_HOME="$tmp_config_home" "$helper" --dry-run -r 180 "hello" | grep -q "180 wpm"
rm -rf "$tmp_config_home"

hardcoded_home_pattern="$(printf '/%s/' 'Users')"
if grep -R "$hardcoded_home_pattern" "$repo_root/skills/say" >/dev/null; then
  echo "Found local hardcoded path in skill files" >&2
  exit 1
fi

echo "Smoke tests passed."
