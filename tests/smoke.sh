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

citation_sample="$(mktemp -t codex-say-citation-sample)"
cat > "$citation_sample" <<'EOF'
Useful answer.

<oai-mem-citation>
<citation_entries>
MEMORY.md:1-2|note=[internal]
</citation_entries>
<rollout_ids>
00000000-0000-0000-0000-000000000000
</rollout_ids>
</oai-mem-citation>

2 memory citations
EOF
"$helper" --dry-run -f "$citation_sample" | grep -q "Would speak 14 characters"
if "$helper" --dry-run -f "$citation_sample" | grep -qi "memory"; then
  echo "Memory citation text leaked into dry-run output" >&2
  exit 1
fi
rm -f "$citation_sample"

rendered_citation_sample="$(mktemp -t codex-say-rendered-citation-sample)"
cat > "$rendered_citation_sample" <<'EOF'
Useful answer.

<citation_entries>
MEMORY.md:1-24|note=[codex-say repo context and skip-pattern tasks]
rollout_summaries/2026-06-09T08-49-41-omt2-codex_say_plugin_and_skip_patterns.md:10-12|note=[read aloud citation cleanup]
</citation_entries>
<rollout_ids>
019eab92-bd1d-70c1-9691-9ca82d4383d0
</rollout_ids>
EOF
"$helper" --dry-run -f "$rendered_citation_sample" | grep -q "Would speak 14 characters"
rm -f "$rendered_citation_sample"

commit_sample="$(mktemp -t codex-say-commit-sample)"
cat > "$commit_sample" <<'EOF'
Useful answer.

Pushed commit: `c092e74266ce0ca0aaa8d07bd3b93d2e11fe0487`.

c092e74266ce0ca0aaa8d07bd3b93d2e11fe0487

Done.
EOF
"$helper" --dry-run -f "$commit_sample" | grep -q "Would speak 21 characters"
rm -f "$commit_sample"

codeblock_sample="$(mktemp -t codex-say-codeblock-sample)"
cat > "$codeblock_sample" <<'EOF'
Intro.

```bash
codex-say default rate 210
```

Done.
EOF
"$helper" --dry-run -f "$codeblock_sample" | grep -q "Would speak 41 characters"
rm -f "$codeblock_sample"

link_path_sample="$(mktemp -t codex-say-link-path-sample)"
cat > "$link_path_sample" <<'EOF'
Open https://github.com/Botanium/codex-say and inspect /Users/botanium/Documents/Codex/report.md.
Then check skills/say/config/skip-patterns.txt.
EOF
"$helper" --dry-run -f "$link_path_sample" | grep -q "Would speak 58 characters"
rm -f "$link_path_sample"

markdown_link_sample="$(mktemp -t codex-say-markdown-link-sample)"
cat > "$markdown_link_sample" <<'EOF'
Read [the repo](https://github.com/Botanium/codex-say) and [the file](/Users/botanium/Documents/Codex/report.md).
EOF
"$helper" --dry-run -f "$markdown_link_sample" | grep -q "Would speak 27 characters"
rm -f "$markdown_link_sample"

codeblock_link_path_sample="$(mktemp -t codex-say-codeblock-link-path-sample)"
cat > "$codeblock_link_path_sample" <<'EOF'
Run this:

```bash
cat /Users/botanium/Documents/Codex/report.md
open https://github.com/Botanium/codex-say
```
EOF
"$helper" --dry-run -f "$codeblock_link_path_sample" | grep -q "Would speak 39 characters"
rm -f "$codeblock_link_path_sample"

repo_slug_sample="$(mktemp -t codex-say-repo-slug-sample)"
cat > "$repo_slug_sample" <<'EOF'
Repo slug Botanium/codex-say should stay readable.
EOF
"$helper" --dry-run -f "$repo_slug_sample" | grep -q "Would speak 50 characters"
rm -f "$repo_slug_sample"

hardcoded_home_pattern="$(printf '/%s/' 'Users')"
if grep -R "$hardcoded_home_pattern" "$repo_root/skills/say" >/dev/null; then
  echo "Found local hardcoded path in skill files" >&2
  exit 1
fi

echo "Smoke tests passed."
