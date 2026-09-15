---
name: review
description: >-
  Read-only PR review. Builds a brief (ticket, diff, every review thread),
  runs the adversarial engine, adds an architecture pass, and drafts comments
  in the user's voice. Re-review mode when the user already sent the PR back.
  Use as /review <PR# | branch>.
disable-model-invocation: true
---

# Review — find, try to kill, draft

Read-only throughout. Never post a comment, resolve a thread, transition a ticket, edit a file, run tests, or push. The user posts everything themselves.

## 1. Orient

Target = `$ARGUMENTS`. Fan heavy fetching to subagents (`model: "haiku"` for pure fetch/search); the brief stays under ~60 lines.

- **PR** — state, mergeable, CI rollup, ALL review threads and inline comments with their resolution state (via the hosting platform's MCP if one is configured, otherwise ask the user to paste them). Split the user's own comments from everyone else's.
- **Ticket**, when the PR names one — summary and acceptance criteria via the issue-tracker MCP (`ToolSearch` first), plus ALL comments.
- **Diff** — `--stat`, touched modules, list of module `AGENTS.md` files to load.
- **Mode** — the user has prior review comments on this PR = re-review; attach their prior asks as a list. Otherwise fresh.

## 2a. Fresh review

1. **Requirement coverage** — diff vs the ticket's acceptance criteria. A missing AC or silent scope creep is a finding like any other: `file:line | coverage | claim | scenario | confidence`.
2. **Engine** — run `references/adversarial-review.md` (scope: `pr <N>`, with `comments`): lens fan-out → skeptic refuters → survivors at ≥80 → comment drafts.
3. **Architecture / business-logic pass** — done in the main loop, never delegated. Does the approach fit the module? Does it create a second way of doing something the repo already does one way? Will it survive the next ticket? Judgment findings may carry lower confidence but must still name a concrete consequence.
4. **Existing threads** — flag overlap with unresolved comments from other reviewers so the user doesn't duplicate a colleague's ask.
5. **Output** — verdict (`approve` / `send back (N asks)` / `discuss`), findings list, comment drafts mapped to `file:line`, and a one-line ticket-comment draft if sending back.

## 2b. Re-review

Prior feedback first, new code second. The author's response is the review target.

1. **Feedback ledger** — one row per prior comment from the user (PR inline + review body + ticket comments):
   `comment → status: addressed (commit/diff evidence file:line) | disputed (author's reply summarized) | ignored (no change, no reply)`
   Evidence is required for "addressed" — a claim in the author's reply is not evidence, the diff is.
2. **Scope** — new commits since the user's last review (`git diff <last-reviewed-sha>...HEAD`, sha from the review timestamp). Run the engine on that range only; do not re-litigate code the user already accepted.
3. **Regression check on fixes** — for each "addressed" row, confirm the fix didn't break the surrounding behavior it touches. Targeted read, not a full re-review.
4. **Output** — the ledger table first, then new findings, then the verdict: `approve` / `send back again (rows: X ignored, Y inadequate)` / `discuss`. Comment drafts for every ignored or inadequate row, in the user's voice.

## 3. Stop

Wait for questions. Answer from loaded context; fan new lookups to haiku subagents.
