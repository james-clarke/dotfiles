# Investigate pipeline

> Context brief already built by the router.

Purpose: load everything relevant so the user can ask questions and set direction. No plan, no code, no gates, no state file. A reading posture, not a doing posture.

## 1. Deepen the brief

The router's brief has the ticket, comments, and PR surface. Add the code layer:

- **Code map** — fan `Explore` subagents (`model: "haiku"`) at the ticket's nouns and module names; return a `file:line` map of the models, handlers, templates, JS, tasks, and hooks the ticket will touch. Conclusions only, no file dumps into main context.
- **Prior art** — how the repo already solves this kind of thing: the existing pattern a new implementation should copy, with `file:line`. One subagent, targeted.
- **Recent history** — `git log --oneline` on the mapped paths; related merged PRs if the ticket references any.
- **Module rules** — list, don't inline, the `AGENTS.md` files covering the mapped modules; read only the ones whose rules plausibly bind this ticket.

## 2. Output

1. The brief — ticket, AC, comment summary, PR state if any.
2. Code map — area | `file:line` | one-line role.
3. Prior art — the pattern to follow, `file:line`.
4. Open questions — what the ticket doesn't specify or contradicts; unknowns that would fork a plan. No recommendations unless asked.

## 3. Stop

Wait for questions and direction. Answer follow-ups from loaded context; fan new lookups to haiku subagents. When the user says build = `/flow dev <KEY>` (orient is already done — carry the brief, start at the plan).

## Rails

Read-only throughout. Never draft a plan, never propose diffs, never touch tracker or GitHub state.
