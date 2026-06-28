# Say

Local, no-key read-aloud for Codex and ChatGPT workflows on macOS.

This skill uses macOS `say` locally, so speech does not send the spoken text through a model. It is designed for cognitive offloading: read visually while listening to the same answer, Markdown report, clipboard text, or selected chat output.

## Simple Guide

If you are in Codex chat, most of the time you only need:

```text
/say
```

Use `/say` after an answer to read the latest useful Codex response aloud. Type it exactly as `/say`, with no space between `/` and `say`. Codex runs the local helper for you, so you do not need to paste the answer into chat or open Terminal.

Common chat commands:

```text
/say
/say next
/say auto on
/say auto off
/say clipboard
/say stop
```

- `/say` reads the latest Codex answer when available, then falls back to the clipboard.
- `/say next` waits for the next final answer and reads it when it appears.
- `/say auto on` reads every future final answer in the current thread.
- `/say auto off` turns automatic read-aloud off.
- `/say clipboard` reads copied text.
- `/say stop` stops the current voice.

Use `/say` inside Codex chat. Use `codex-say` only in Terminal, for example `codex-say -f report.md`.

## Features

- Read the latest Codex final answer from the local transcript.
- Read the next final answer automatically with `next`.
- Turn on thread-scoped automatic read-aloud for every future final answer.
- Read clipboard text, inline text, or Markdown files.
- Save a default speech rate such as `210 wpm`.
- Use speed multipliers such as `--speed 1x`, `--speed 1.5x`, and `--speed 2x`.
- Read fenced code block contents while skipping the backtick fences.
- Skip or shorten noisy metadata such as memory citations, Git commit hashes, raw links, and file paths.
- Stop active speech and stale launchd jobs with one command.

## Install as a Codex plugin

The repo includes a plugin manifest at:

```bash
.codex-plugin/plugin.json
```

You can install the plugin from this repository in Codex, or use the local skill installer below while developing.

## Install the local skill helper

```bash
git clone https://github.com/Botanium/say.git
cd say
bash scripts/install.sh
```

The installer copies the skill to:

```bash
~/.codex/skills/say
```

It also links these commands into `~/.local/bin`:

```bash
codex-say
saychat
readchat
```

Make sure `~/.local/bin` is on your `PATH`.

## Detailed Usage

### Which Command Should I Use?

- Use `/say` or `$say` inside Codex chat.
- Use `codex-say` in Terminal.
- The skill itself runs `scripts/codex-say` under the hood.

So `codex-say` is the shell helper. `/say` is the chat shortcut you type to make Codex run that helper for you.

In Codex chat:

```text
/say
/say next
/say auto on
/say auto off
/say auto status
/say rate 210
/say clipboard
/say stop

$say
$say next
$say auto on
$say auto off
$say auto status
$say rate 210
$say clipboard
$say stop
```

In a terminal:

```bash
codex-say "Read this aloud"
codex-say --speed 1.5x "Read this faster"
codex-say -f report.md
codex-say --clipboard
codex-say auto on
codex-say auto speed 1.5x
codex-say default rate 210
codex-say auto status
codex-say auto off
codex-say --stop
```

Exact speech rates still work:

```bash
codex-say -r 220 report.md
```

Set the saved default rate for future read-aloud commands:

```bash
codex-say default rate 210
codex-say default status
```

## Automatic Mode

Use automatic mode when you want every future final answer in the current Codex thread to be read aloud:

```text
/say auto on
```

Tune the speed:

```text
/say auto speed 1.5x
/say auto rate 220
```

Check or disable it:

```text
/say auto status
/say auto off
```

Automatic mode is thread-scoped. It watches the local Codex transcript, remembers the last line it already handled, and only speaks future `final_answer` messages. `/say stop` stops the current voice and pending one-shot `next` watchers; `/say auto off` disables automatic future answers.

Manual read-aloud commands are protected while automatic mode is on. For example, `/say clipboard` will keep reading the clipboard and skip the tiny Codex confirmation response, instead of letting auto mode interrupt the clipboard audio.

The current plugin keeps speech local by default. A future companion app can add a visual progress indicator and richer pause/resume using macOS `AVSpeechSynthesizer`; the plain `say` command does not expose word-level progress.

## Skip Patterns

Say removes noisy text before speaking. Packaged defaults live in:

```bash
skills/say/config/skip-patterns.txt
```

That file currently skips Codex memory citations, rendered memory-citation entries, and Git commit hashes. It also shortens raw links and path-like strings so they are spoken as `this link` or `this path` instead of long URLs or filesystem paths. Markdown links still use their readable label, so `[the repo](https://example.com)` is spoken as `the repo`.

You can add your own skip rules without editing the plugin:

```bash
~/.config/codex-say/skip-patterns.txt
```

Each non-empty, non-comment line is a Python regular expression removed before Markdown cleanup. To speak a short placeholder instead of removing the match, use:

```text
pattern => replacement
```

## Why not Whisper?

Whisper is speech-to-text: it turns audio into text. This plugin needs text-to-speech: it turns Codex text into audio. OpenAI text-to-speech can do that, but it requires an API key and API billing, so the default plugin uses local macOS speech instead.

## Token Note

The speech itself is local and does not use model tokens. A Codex chat turn still uses tokens for the prompt, response, and skill instructions. For large reports, prefer:

```bash
codex-say -f report.md
```

or:

```bash
codex-say --clipboard
```

instead of pasting the full report into chat.

## Platform

Currently macOS only. Linux and Windows can be added later with `spd-say`, `espeak`, or PowerShell voices.

## License

MIT
