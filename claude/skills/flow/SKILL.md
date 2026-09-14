---
name: flow
description: >-
  Agentic entry point for build and review work. Kinds = dev (ticket
  development), pr (code review), repr (re-review changes). Runs a shared
  orient stage that gathers ticket, PR, comment, and any other relevant
  context into one brief, then dispatches to the matching pipeline in
  references/. Read-only exploration lives in /investigate. Use as
  /flow [kind] [target].
disable-model-invocation: true
---

# Flow — single harness

Router only. Everything else lives in `references/`, paths relative to this skill's directory.

- Pipelines are read ONLY after routing. Never load more than one.
- `references/adversarial-review.md` and `references/static-verify.md` are **engines**, not pipelines — load one only at the step where a pipeline calls for it.

## 1. Classify

Arguments = whatever follows `/flow` (`$ARGUMENTS`).

| Invocation | Routes to |
|---|---|
| `/flow` | infer from signals |
| `/flow dev [KEY]` | ticket dev pipeline |
| `/flow pr <PR#\|branch>` | review pipeline, fresh |
| `/flow repr <PR#>` | review pipeline, re-review mode |

Read-only exploration is `/investigate`, not a kind here; it hands off to `/flow dev` when the user says build.

Inference signals, gathered in parallel and cheap:

| Signal | Kind |
|---|---|
| branch carries a ticket key (`ABC-1234`) and the user authored it | ticket dev |
| the PR belongs to a teammate, no prior review by the user | fresh review |
| teammate's PR, user has prior review or comments on it | re-review |
| user's own PR with reviewer feedback since the last commit | ticket dev, corrections mode |

One kind fits = state the routing in one line and proceed. Signals conflict = `AskUserQuestion` with the top 2 candidates. Never guess.

## 2. Orient — shared, always runs

Build the **context brief**: a structured block injected into whichever pipeline runs. Fan heavy fetching to subagents (haiku for pure fetch/search); the brief itself stays under ~60 lines.

- **Ticket** — key (branch / PR title / args), summary and acceptance criteria via the issue-tracker MCP (`ToolSearch` first), plus ALL ticket comments.
- **PR**, when one exists — state, mergeable, CI rollup, and ALL review threads + inline comments with their resolution state (via the hosting platform's MCP if one is configured, otherwise ask the user to paste them). Split the user's own prior comments from everyone else's.
- **Diff** — `--stat`, touched modules, list of module `AGENTS.md` files to load.
- **History flags** — `RE-REVIEW` (user already reviewed this PR; attach their prior asks as a list) or `CORRECTIONS` (user's own PR has unaddressed reviewer feedback; attach each item).

## 3. Dispatch

Read exactly one file and follow it, with the brief prepended:

| Kind | File |
|---|---|
| ticket dev, incl. corrections mode | `references/ticket.md` |
| review / re-review | `references/review.md` |

## 4. State

`~/.claude/flow-state/<key>.json` — kind, stage, chunk, last-seen PR comment id, timestamp.

Write at each stage boundary. Invoked with existing state for the target = offer resume at the recorded stage vs restart. Delete state on ship or verdict.
