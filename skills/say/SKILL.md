---
name: say
description: Local no-key read-aloud workflow for Codex/ChatGPT output, selected text, clipboard text, and Markdown files using macOS speech instead of sending large content through the model. Use when the user invokes $say, asks for /say or /read behavior, wants chat output read aloud, wants a .md report spoken, wants text-to-speech without an API key, or wants to avoid token use while listening to generated reports.
---

# Say

Use local macOS speech for read-aloud tasks. Keep the model out of the content path whenever possible: read from the clipboard, a file path, or the local Codex transcript directly, not by pasting or loading large text into the conversation.

Use the bundled helper at `scripts/codex-say` relative to this skill folder. If the user installed the helper globally, `codex-say`, `saychat`, and `readchat` are also available on PATH.

Command naming: `/say` and `$say` are Codex chat invocations. `codex-say` is the Terminal/helper command that the skill runs under the hood. In user-facing Codex chat guidance, prefer `/say` or `$say`; in shell examples, use `codex-say`.

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
- If the user asks to make the current thread active for queued automatic speech, run:
  `scripts/codex-say focus`
- If the user asks what automatic speech is waiting to read, run:
  `scripts/codex-say queue`
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
codex-say focus
codex-say queue
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

Automatic mode is thread-scoped: it stores local state in `~/.local/state/codex-say`, remembers the transcript cursor, and handles each future final answer once.

Automatic mode uses a local active-thread queue. Background threads queue their final answers instead of speaking over the active thread. `codex-say focus` marks the current thread active and drains queued responses for that thread. Speech is chunked so a stop or active-thread change can resume near the interrupted chunk later.

Codex Desktop currently does not expose a public local click/focus event to skills. The helper includes an internal `--set-active-thread` hook for future integration; until that exists, use `focus` as the reliable fallback when a queued background thread should start reading.

Code blocks are skipped silently by default to preserve natural listening flow. Inline code remains readable because command names, flags, and file paths are often meaningful.

## User Guidance

For the lowest-token workflow, tell the user:

1. Invoke `$say` or `/say` with no pasted text to read the latest Codex response when available.
2. Add `$say next` or `/say next` to a prompt when the user wants the answer currently being generated to be read automatically.
3. Use `$say auto on` or `/say auto on` when the user wants every future final answer in the current thread read aloud.
4. Disable automatic mode with `$say auto off` or `/say auto off`.
5. Use `$say focus` or `/say focus` to mark the current thread active and drain queued background responses.
6. Use `$say queue` or `/say queue` to inspect queued automatic responses.
7. If that is not available, copy the chat output or report text and invoke `$say clipboard` or `/say clipboard`.
8. Stop current speech with `/say stop`, `$say stop`, or `saychat --stop`.

For a completely model-free workflow, recommend macOS Spoken Content: select text on screen and use the system "Speak selected text" shortcut, commonly Option-Esc when enabled.
