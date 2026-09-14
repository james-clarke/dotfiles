# Review pipeline

> Context brief already built by the router.

Two modes, flagged in the brief. Both end with draft comments in the user's voice. The user posts everything themselves — never post comments yourself, never transition a ticket without their OK.

## Mode A — fresh review

1. **Requirement coverage** — diff vs the ticket's acceptance criteria from the brief. A missing AC or silent scope creep is a finding like any other: `file:line | coverage | claim | scenario | confidence`.
2. **Engine** — run `references/adversarial-review.md` (scope: `pr <N>`, with `comments`): lens fan-out → skeptic refuters → survivors at ≥80 → comment drafts.
3. **Architecture / business-logic pass** — done in the main loop, never delegated. Does the approach fit the module? Does it create a second way of doing something the repo already does one way? Will it survive the next ticket? Judgment findings may carry lower confidence but must still name a concrete consequence.
4. **Existing threads** — unresolved comments from other reviewers are in the brief; flag overlap so the user doesn't duplicate a colleague's ask.
5. **Output** — verdict (`approve` / `send back (N asks)` / `discuss`), findings list, comment drafts mapped to `file:line`, and a one-line ticket-comment draft if sending back.

## Mode B — re-review, already sent this back

Prior feedback first, new code second. The author's response is the review target.

1. **Feedback ledger** — one row per prior comment from the user (PR inline + review body + ticket comments, all in the brief):
   `comment → status: addressed (commit/diff evidence file:line) | disputed (author's reply summarized) | ignored (no change, no reply)`
   Evidence is required for "addressed" — a claim in the author's reply is not evidence, the diff is.
2. **Scope the re-review** — new commits since the user's last review (`git diff <last-reviewed-sha>...HEAD`, sha from the review timestamp in the brief). Run the adversarial-review engine on that range only; do not re-litigate code the user already accepted.
3. **Regression check on fixes** — for each "addressed" row, confirm the fix didn't break the surrounding behavior it touches. Targeted read, not a full re-review.
4. **Output** — the ledger table first, then new findings, then the verdict: `approve` / `send back again (rows: X ignored, Y inadequate)` / `discuss`. Comment drafts for every ignored or inadequate row, in the user's voice.

## Rails

Read-only throughout. Fan file reads out to subagents. Never post, never push, never resolve threads — drafts only.
