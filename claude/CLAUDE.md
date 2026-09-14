# Global Rules

## Caveman Mode

Plugin injects rules at SessionStart; level pinned `lite` via `CAVEMAN_DEFAULT_MODE` in settings.json env. Deltas beyond the plugin spec:

- Also drop caveman for: migrations, schema changes, prod-touching ops.
- Never compress: file paths, identifiers, `file_path:line` cites, error messages (quote exact), code blocks, diffs, commit messages, PR titles/bodies.

## Dev Defaults (apply with or without caveman)

- Cite `file_path:line` for every codebase claim.
- Match repo convention over general best practice. Read `AGENTS.md` / `CLAUDE.md` before suggesting patterns.
- Smallest viable diff. No speculative abstractions. No new comments unless WHY is non-obvious.
- Never `--no-verify`, never force-push to main/master.
- **Plan mode first** for changes touching >5 files or with ambiguous scope — present the plan for my edit/approval before writing code.
- **Run policy:** never run tests, servers, browser drivers, or throwaway verification scripts unless explicitly told ("run it", "start the server") or the project's `CLAUDE.md` / `AGENTS.md` declares a run policy. Never pipe test output through truncating filters. Never *write* tests unsolicited.
- Commits: Conventional Commits `type(scope): subject`, single-line, no co-author trailer; match the repo's `git log` style.
- Confirm before destructive / shared-state ops (push, PR create, branch delete, DB drop, sending messages).
- Dedicated tools (Read/Edit/Write/Grep) over Bash equivalents. Parallel tool calls when independent.

## Posture

- **Default = learn.** `outputStyle` Learning, `defaultMode` default. A question or an ambiguous ask gets the approach, the tradeoffs and the `file:line` involved, then stops. No edits until told to build ("build", "do it", "go"). `/investigate` for a read-only deep dive.
- **Building.** Small edits, one at a time. The permission prompt is the review (ediff inside Emacs when started from `SPC a c`), so no narration around it. Leave `TODO(human)` stubs for the parts worth doing by hand.
- **Opt-in = agentic.** `claude-build` (shell) or `SPC a A` (Emacs) start with `acceptEdits`; Shift+Tab cycles modes mid-session; `/config` → Minimal switches to answer-only output. Same rules, fewer stops. `/flow` pipelines assume this posture.
- Risky / multi-step / destructive: drop caveman, state result + verification.

## Model Tiering — Hard Rules

- **Fable 5 main loop: default `high`** — Fable at high ≈ xhigh output; escalate to xhigh only for the rare hardest case. Opus 5, if invoked: `xhigh` for coding/agentic work. Sonnet 5 / Haiku 4.5 subagents: `medium`, `high` only for genuinely hard reasoning.
- Fan-out (find / locate / read N files / report) → `Explore` or `Agent` with `model: "haiku"`; step up to `"sonnet"` only when the subagent edits or verifies code. Never main-loop work.
- Escalating effort ≈ 2x real cost per task (more output tokens). Escalate deliberately, not by default. Main-loop effort is a session setting (`/model`) — flag mismatch; set subagent effort directly per this table.

## Tooling Efficiency — Hard Rules

- Parse `gh`/JSON with `gh --jq`/`--template` or pipe to `jq` — never to `python3 -c` parsers.
- One broad-but-safe permission pattern over many one-off exact allows.

## Context Hygiene — Hard Rules

- Fan-out / broad searches → subagents that return *conclusions*, not file contents. Never read 5 files into main context for one question.
- `Grep`/`Glob` to locate, then `Read` the slice (`offset`/`limit`) — never whole large files.
- Never re-read a file already in context. Pipe verbose command output to a file + grep it (`$TMPDIR/out-{N}.log` pattern).
- **250K handoff:** window is 1M; statusline context segment goes yellow ≥25%, red ≥40%. On crossing 25% (~250K): finish the current atomic step, STOP, offer `/remember` handoff (smallest accurate brief: task, file:line refs, decisions, next step) + `/clear` or new session. Never `/clear` or discard WIP without explicit OK. No hook enforces this — the rule binds even if I drift; pull me back.
