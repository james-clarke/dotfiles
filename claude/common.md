# Global Rules (shared by both profiles)

## Caveman Mode

Plugin injects rules at SessionStart; level pinned `lite` via `CAVEMAN_DEFAULT_MODE` in settings.json env. Deltas beyond the plugin spec:

- Also drop caveman for: migrations, schema changes, prod-touching ops.
- Never compress: file paths, identifiers, `file_path:line` cites, error messages (quote exact), code blocks, diffs, commit messages, PR titles/bodies.

## Ask

- When a decision is mine (design, naming, scope, a trade-off the code does not settle), stop and ask with AskUserQuestion before building on a guess. Recommendation first, then the alternatives. One question per decision.
- Never `--no-verify`, never `git push`.
- `/investigate` for a read-only deep dive, `/review` for a PR.

## Dev Defaults

- Cite `file_path:line` for every codebase claim.
- Match repo convention over general best practice. Read `AGENTS.md` / `CLAUDE.md` before suggesting patterns.
- Smallest viable change. No speculative abstractions. No new comments unless WHY is non-obvious.
- Commits I ask you to draft: Conventional Commits `type(scope): subject`, single-line, no co-author trailer; match the repo's `git log` style.
- Dedicated tools (Read/Grep/Glob) over Bash equivalents. Parallel tool calls when independent.

## Model Tiering — Hard Rules

- **Fable 5 main loop: default `high`** — Fable at high ≈ xhigh output; escalate to xhigh only for the rare hardest case. Opus 5, if invoked: `xhigh`. Sonnet 5 / Haiku 4.5 subagents: `medium`, `high` only for genuinely hard reasoning.
- Fan-out (find / locate / read N files / report) → `Explore` or `Agent` with `model: "haiku"`; step up to `"sonnet"` only for real reasoning. Never main-loop work.
- Escalating effort ≈ 2x real cost per task (more output tokens). Escalate deliberately, not by default. Main-loop effort is a session setting (`/model`) — flag mismatch; set subagent effort directly per this table.

## Tooling Efficiency — Hard Rules

- Parse JSON with `jq` — never with `python3 -c` parsers.
- One broad-but-safe permission pattern over many one-off exact allows.

## Context Hygiene — Hard Rules

- Fan-out / broad searches → subagents that return *conclusions*, not file contents. Never read 5 files into main context for one question.
- `Grep`/`Glob` to locate, then `Read` the slice (`offset`/`limit`) — never whole large files.
- Never re-read a file already in context. Verbose command output: filter with `rg`/`head` in the same pipe, never dump it.
- **250K handoff:** window is 1M; statusline context segment goes yellow ≥25%, red ≥40%. On crossing 25% (~250K): finish the current atomic step, STOP, give me a five-line brief (task, `file:line` refs, decisions, next step) to paste into a fresh session. No hook enforces this — the rule binds even if I drift; pull me back.
