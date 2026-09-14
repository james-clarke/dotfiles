---
name: investigate
description: >-
  Read-only deep dive on a ticket, PR or area of the code so the user can ask
  questions and set direction. Loads ticket, PR, comments, code map and prior
  art into one brief. No plan, no code, no gates, no state. Use as
  /investigate <KEY | PR# | path | topic>.
disable-model-invocation: true
---

# Investigate — read, map, stop

A reading posture, not a doing posture. Nothing here edits a file, drafts a diff, or touches tracker or GitHub state.

## 1. Orient

Target = `$ARGUMENTS`. Fan heavy fetching to subagents (`model: "haiku"` for pure fetch/search); the brief itself stays under ~60 lines.

- **Ticket**, when the target is a key — summary and acceptance criteria via the issue-tracker MCP (`ToolSearch` first), plus ALL comments.
- **PR**, when one exists — state, mergeable, CI rollup, ALL review threads and inline comments (`gh pr view --json reviews,comments`, `gh api -X GET repos/{owner}/{repo}/pulls/{n}/comments`). Split the user's own comments from everyone else's.
- **Diff** — `--stat`, touched modules, list of module `AGENTS.md` files that plausibly bind.
- **Path or topic** — skip the tracker; start from the code layer below.

## 2. Code layer

- **Code map** — `Explore` subagents at the nouns and module names; return a `file:line` map of models, handlers, templates, JS, tasks, hooks. Conclusions only, no file dumps into main context.
- **Prior art** — how the repo already solves this kind of thing: the pattern a new implementation should copy, with `file:line`. One subagent, targeted.
- **Recent history** — `git log --oneline` on the mapped paths; related merged PRs if the ticket references any.
- **Module rules** — list, don't inline, the `AGENTS.md` files covering the mapped modules; read only the ones whose rules plausibly bind.

## 3. Output

1. The brief — ticket, AC, comment summary, PR state if any.
2. Code map — area | `file:line` | one-line role.
3. Prior art — the pattern to follow, `file:line`.
4. Open questions — what is unspecified or contradictory; unknowns that would fork a plan. No recommendations unless asked.

## 4. Stop

Wait for questions and direction. Answer follow-ups from loaded context; fan new lookups to haiku subagents. When the user says build, hand off to `/flow dev <KEY>` with the brief; orient is already done, it starts at the plan.
