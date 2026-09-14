# Engine — Static Verify

> Prove it by reading, not running. Called by a pipeline, never run standalone.

House rule: never run servers or tests. This engine verifies from source evidence only. Output exactly two lists: **VERIFIED** (with `file:line` proof) and **NEEDS MANUAL RUN** (with the exact command for the user).

## 1. Map the change

Scope is set by the calling pipeline — uncommitted diff by default, or a branch or commit range.

Identify every entry point the diff touches: routes, handlers, template blocks, JS handlers, API endpoints, hook or event receivers, background tasks, CLI commands.

## 2. Trace each path end-to-end

For each entry point, walk the chain and record evidence at every hop:

- **Route → handler** — the route exists in the relevant routing module; its name matches every reverse-lookup usage in the diff.
- **Handler → template** — the template path exists; context keys the template uses are actually provided; block names match the parent template.
- **Template → JS** — DOM ids and classes referenced by JS exist in the rendered markup; handlers bind to elements that exist; request URLs point at real routes with matching parameter names.
- **JS → endpoint** — request payload keys match what the handler reads; response shape matches what the JS consumes.
- **Model writes** — which hooks or signals fire; instance saves (hooks fire) vs bulk ops (they don't); authorization scoping present on every user-data query.
- **Async** — task registered; queue correct; caller passes serializable args.
- **Multi-step flows** — handoff tokens and status/websocket paths intact across steps.

Fan wide reads out to `Explore` subagents (`model: "sonnet"`) to keep file dumps out of main context. Large modules get searched, never read whole.

## 3. Allowed mechanical checks

Only checks that boot no framework and touch no DB — per changed file, in the repo's language:

- `python3 -m py_compile <file>`
- `node --check <file>` (skip inline template JS)
- the equivalent syntax-only check for the repo's language (`go vet`, `cargo check`, `ruby -c`, ...)

Nothing else. Repo check scripts, REPL shells, dev servers, and tests are off-limits here — they belong in the NEEDS MANUAL RUN list.

## 4. Output

**VERIFIED** — table: item | evidence `file:line`.

**NEEDS MANUAL RUN** — table: item | why static proof is impossible | the exact command or UI steps for the user (repo test runner with the relevant target, specific admin/control-panel click path, etc.).

No hedging. Broken is reported as broken, with the evidence.
