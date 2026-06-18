---
name: say
description: Say is a local no-key read-aloud workflow for Codex/ChatGPT output, selected text, clipboard text, and Markdown files using macOS speech instead of sending large content through the model. Use when the user invokes /say or $say, asks for /read behavior, wants chat output read aloud, wants a .md report spoken, wants text-to-speech without an API key, or wants to avoid token use while listening to generated reports.
---

# Say

Use local macOS speech for read-aloud tasks. Keep the model out of the content path whenever possible: read from the clipboard, a file path, or the local Codex transcript directly, not by pasting or loading large text into the conversation.

Use the bundled helper at `scripts/codex-say` relative to this skill folder. If the user installed the helper globally, `codex-say`, `saychat`, and `readchat` are also available on PATH.

Command naming: `/say` and `$say` are Codex chat invocations. `codex-say` is the Terminal/helper command that the skill runs under the hood. In user-facing Codex chat guidance, prefer `/say` or `$say`; in shell examples, use `codex-say`.

## User Guide

Most users only need `/say` inside Codex chat. Type it exactly as `/say`, with no space between `/` and `say`. It is the simple chat shortcut for local read-aloud: Codex runs the bundled helper for you, reads from the local transcript or clipboard, and does not require pasting the answer back into chat.

1. Type `/say` after an answer to read the latest useful Codex response aloud.
2. Type `/say next` when you want the answer currently being generated, or the next final answer, to be read automatically.
3. Type `/say auto on` when you want every future final answer in the current thread read aloud.
4. Type `/say auto off` to turn automatic read-aloud off.
5. Type `/say clipboard` to read copied text.
6. Type `/say stop` to stop the current voice.

Use `/say` or `$say` in Codex chat. Use `codex-say` only when you are running the helper directly in Terminal, for example `codex-say -f report.md`.

For a completely model-free fallback, use macOS Spoken Content: select text on screen and use the system "Speak selected text" shortcut, commonly Option-Esc when enabled.

## Routing

- If the user asks to turn automatic read-aloud on for future answers, run:
  `scripts/codex-say auto on`
  This starts a thread-scoped local watcher for future `phase=final_answer` messages.
- If the user asks to disable automatic read-aloud, run:
  `scripts/codex-say auto off`
- If the user asks whether automatic read-aloud is enabled, run:
  `scripts/codex-say auto status`
- If the user asks to change automatic read-aloud speed, run one of:
  `scripts/codex-say auto speed 1.5x`
  `scripts/codex-say auto rate 220`
- If the user asks to set the default read-aloud rate for future commands, run:
  `scripts/codex-say default rate <wpm>`
  For short invocations such as `$say rate 210` or `/say rate 210`, run:
  `scripts/codex-say rate 210`
- If the user asks what the default read-aloud rate is, run:
  `scripts/codex-say default status`
- If the user asks to stop speech, run:
  `scripts/codex-say --stop`
  This stops active speech plus any pending `next` watcher. It does not disable automatic future answers; use `auto off` for that.
- If the user asks to read the answer to the current prompt, or invokes `$say next`, `/say next`, `$say` with `next`, or `/read next`, run:
  `scripts/codex-say next`
  Do this before producing the final answer so the local watcher can speak the next `phase=final_answer` message after it is written to the Codex transcript.
- If the user provides no text or path, run:
  `scripts/codex-say`
  Inside Codex this reads the latest final assistant answer from the local thread transcript when available, then falls back to any latest assistant message and finally the macOS clipboard. Outside Codex it reads the clipboard.
- If the user asks to read copied text or clipboard text, run:
  `scripts/codex-say --clipboard`
- If the user provides a file path, and the path exists, run:
  `scripts/codex-say -f <path>`
- If the user provides short inline text, run:
  `scripts/codex-say -- <text>`
- If the user provides long inline text, warn briefly that it has already consumed tokens and suggest the clipboard/file flow next time. Still speak it if they explicitly asked.

## Token Rules

- Do not send a commentary/progress message before running the helper; that short message can become the latest assistant response and be spoken instead of the useful answer.
- For `next`, run `scripts/codex-say next` before the final response and avoid any further commentary messages before final.
- For `auto on`, run `scripts/codex-say auto on`; afterward the local watcher reads future final answers without needing the user to add `next` to every prompt.
- Do not `cat`, `pbpaste`, or otherwise print large content into the model context just to read it aloud.
- Do not summarize, rewrite, or clean the content unless the user asks for that specifically.
- Prefer clipboard reading for chat output. The user can copy the latest response, then invoke `$say` or `/say` with no arguments.
- If `CODEX_THREAD_ID` is present, `codex-say` can read the latest assistant response from the local transcript without copying or exposing the content to the model.
- For `next`, the watcher must ignore commentary/progress messages and wait for `phase=final_answer`.
- For automatic mode, the watcher must remain thread-scoped and only speak future `phase=final_answer` messages from the local transcript.
- Prefer `codex-say -f <path>` for Markdown reports.
- Keep the assistant response tiny after starting or stopping speech.

## Commands

The bundled helper is:

```bash
scripts/codex-say
```

If installed globally, convenience commands are:

```bash
saychat
readchat
```

Useful options:

```bash
codex-say --stop
codex-say next
codex-say auto on
codex-say auto off
codex-say auto status
codex-say auto speed 1.5x
codex-say auto rate 220
codex-say default rate 210
codex-say default status
codex-say --next --timeout 240
codex-say --latest
codex-say --clipboard
codex-say clipboard
codex-say --speed 1.5x "read this faster"
codex-say --list-voices
codex-say -r 150
codex-say -f report.md
codex-say --save report.aiff -f report.md
```

Background speech is handed to macOS `launchctl` so it survives Codex shell cleanup. Use `--foreground` only for diagnostics or when the user explicitly wants the command to wait.

Speech is exclusive by default: starting a new read-aloud command cancels active speech and pending `next` watchers first. This prevents stacked voices.

Stop removes active speech and pending one-shot `next` watchers. It intentionally leaves automatic mode enabled so `/say stop` can be used as a pause. Use `/say auto off` or `$say auto off` to disable future automatic read-aloud.

`next` is one-shot: after it reads one final answer or times out, its watcher removes its own launchd label and exits. It should not read the same answer again.

Automatic mode is thread-scoped: it stores local state in `~/.local/state/codex-say`, remembers the transcript cursor, and reads each future final answer once.

Fenced code blocks are read as their contents while the backtick fences and language labels are skipped. Inline code remains readable because command names, flags, and file paths are often meaningful.

## Skip Patterns

Say includes a packaged skip-pattern file at `config/skip-patterns.txt`. It keeps noisy transcript text out of speech, including memory citations, rendered citation rows, Git commit hashes, raw links, and file paths.

Users can add their own skip rules in `~/.config/codex-say/skip-patterns.txt` without editing the skill. Each rule is a Python regular expression removed before Markdown cleanup. A rule can also use `pattern => replacement` to speak a short placeholder; the packaged defaults speak raw URLs as `this link` and path-like strings as `this path`, while Markdown link labels remain readable.
