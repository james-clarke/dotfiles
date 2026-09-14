# Ticket pipeline

> Context brief already built by the router.

Principle: a gate at every point where being wrong is cheap to fix and expensive to discover later.

## 0. Corrections mode — when the brief flags `CORRECTIONS`

The user's own PR came back with feedback, so the feedback IS the plan. Build a ledger, one row per reviewer comment (PR inline, PR review body, ticket comment) → intended action (fix / push back / question).

STOP for the user's OK on the ledger, then run steps 2-5 against it. Every row must end resolved: a code change, or a drafted reply in the user's voice.

## 1. Plan — gate #1

- Skip only when the diff is one-sentence-describable — say so and go to step 2.
- Written plan: ordered steps with `file:line` anchors, data/hook/authorization impacts, explicit non-goals. No code yet. `AskUserQuestion` only for genuine forks the code can't answer.
- STOP for the user's OK — cheapest point to be wrong.

## 2. Implement — gate per chunk

- Smallest viable diff; match module conventions; respect the repo's authorization/scoping rules on every user-data query; no unsolicited tests; no new comments unless the WHY is non-obvious.
- Reviewable chunks, one logical change each: show the staged diff, get an explicit OK, commit — single-line message in the repo's existing style (read `git log` first), no co-author trailer.
- Two-strikes rule: same correction twice = stop iterating in place, restate the lesson, re-approach fresh.

## 3. Verify — no servers, no tests

- Run the static-verify engine (`references/static-verify.md`, scope: accumulated diff) for a wiring trace with `file:line` evidence.
- Hand the user exact manual commands (repo test runner with the relevant target, UI click paths) for whatever static reading can't prove.

## 4. Pre-PR review — gate #2

- Run the adversarial-review engine (`references/adversarial-review.md`, scope: branch). Fix confirmed findings back through step 2's chunk gate.
- State-critical paths (as named by the repo's `AGENTS.md`) in the diff = flag for an extra human pass even on a clean run.

## 5. Ship prep

- Draft the PR title and body — or, in corrections mode, the reply-to-reviewer comment set — in the user's voice: human-typed, lowercase and fragments fine, no dash punctuation, no filler.
- Print the exact `git push` / `gh pr create` commands, never run them (settings.json denies `git push`).
- Optional: the repo's QA guide, if it has one.
- Update flow-state at each boundary; delete it on ship.

## Rails

Fan searches out to subagents. StatusLine at 25% = finish the atomic step, then offer a `/remember` handoff. Never push, never `--no-verify`, confirm destructive ops (house rules, CLAUDE.md).
