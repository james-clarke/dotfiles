# Engine — Adversarial Review

> Find, then try to kill. Called by a pipeline, never run standalone.

Two passes: recall first (parallel lenses), precision second (skeptic refuters). A finding no skeptic could kill is worth the user's time; everything else dies silently.

Hard constraints: read-only. Never edit files, never run tests or servers, never push, never post to GitHub.

## 0. Scope

Set by the calling pipeline:

| Scope | Source |
|---|---|
| `pr <N>` | the PR diff plus its title and body |
| `uncommitted` | staged + unstaged + untracked vs `HEAD` |
| `branch` | `git diff <default-branch>...HEAD` |
| explicit range (re-review) | `git diff <sha>...HEAD` |

Load context once: the root `AGENTS.md` is already in context, so additionally read the `AGENTS.md` of each touched module. Diff over ~1500 lines = split by module, run Phase 1 per chunk, merge findings before Phase 2.

## 1. Lens fan-out — parallel, sonnet

Spawn ALL applicable lens agents in ONE message (`Agent` tool, `model: "sonnet"`). Skip a lens only when the diff clearly cannot trigger it, e.g. no data-layer code = skip perf.

| Lens | Hunts |
|---|---|
| correctness | logic errors, inverted or off-by-one conditionals, unhandled null/empty/timezone edge cases, broken error paths, state-machine breaks |
| security | missing authorization or scope filter on user-data access, IDOR, injection, secrets in code, session misuse in signup and auth flows |
| data-integrity | bulk writes that bypass the hooks, validators, or signals the repo relies on for state-critical models (the ones its `AGENTS.md` names); values passed in the wrong unit (dollars vs cents, seconds vs ms); derived-state recalculation drift |
| perf | N+1 (per-row queries inside loops or template loops), missing eager-loading/joins, unbounded queries, repeated COUNT/EXISTS |
| ai-slop | plausible-but-wrong code, hallucinated APIs or kwargs, convention drift vs the surrounding file, dead or duplicated code. If the diff touches tests: weakened or removed assertions, assertion-free tests, `assert x is not None` as the only check |

Every lens prompt MUST contain:

1. The diff, or chunk, plus the paths of the touched files.
2. Scope lock, verbatim: *"Focus ONLY on issues introduced by this diff. Do not report pre-existing concerns. If a bug predates the diff, ignore it."*
3. Precedent rules — pre-decided judgment calls, do NOT flag:
   - missing migration files (handled separately by the team)
   - environment variables and CLI flags are trusted values
   - UUIDs are unguessable and need no validation
   - style-only nits where the code matches repo convention
   - anything an `AGENTS.md` documents as intentional
4. Finding schema — one line per finding, no prose:
   `file:line | category | claim (1 sentence) | failure scenario (concrete inputs/state → wrong outcome) | confidence 0-100`
   Confidence anchors: 0 false positive · 25 might be real · 50 real but minor · 75 real and important · 100 certain.
5. Kill rule, verbatim: *"If you cannot state a concrete failure scenario, do not report the finding."*

## 2. Skeptic verification — parallel per finding

Order matters: dedup FIRST, then drop.

- Dedup identical or same-root-cause claims across lenses, keeping the highest confidence.
- Convergence rule: the same defect found independently by 2+ lenses goes to a refuter regardless of individual confidence — independent convergence is corroboration the per-lens rubric can't express.
- Then drop remaining single-lens findings under 50.

For each survivor spawn a refuter agent in fresh context on `sonnet`; use the inherited model for data-integrity and security findings:

> Attempt to REFUTE this code-review claim. Read the real code at the cited location plus callers and templates as needed. Default verdict is REFUTED — return CONFIRMED only if the failure scenario is grounded in evidence you can cite as `file:line`. Return: CONFIRMED|REFUTED, evidence `file:line` list, adjusted confidence 0-100, one-sentence reason.

Refuters judge the DEFECT, not the claim's wording: if the underlying defect is real but the claim has wrong line numbers or overstated details, return CONFIRMED with the corrected claim and score the corrected version — citation errors get fixed in the report, not counted against confidence.

Batching: max ~8 refuters per wave; same-file minor findings may share one refuter. Kill everything REFUTED or with a final (corrected-claim) confidence under 80.

## 3. Report

Sort Critical > High > Medium > Low — severity is impact, independent of confidence. Findings on state-critical paths (as named by the repo's `AGENTS.md`) list first regardless of severity math. Cap nit-level items at 3 total.

One line each: `SEV file:line — claim — failure scenario [conf]`

End with a verdict: `merge-ready` / `needs fixes (N)` / `blocked (critical)`. Zero survivors = say so plainly, do not pad with observations.

## 4. Comment drafts — only when the calling pipeline asks for `comments`

For a teammate's PR, convert each surviving finding into a draft PR comment in the user's voice: reads human-typed, lowercase and fragments fine, no dash punctuation, problem stated once, fix given only when obvious (never "consider maybe..."), zero praise filler, style nits omitted entirely.

Output the drafts mapped to `file:line`. The user posts them — never post them yourself.
