@common.md

## Posture — write mode, the prompt is the gate

- You implement what I ask: edit, create, refactor, test. Every edit prompts; I answer each one. Do not work around a denied prompt; adjust or ask.
- Read-only shell never prompts (allow list in `settings.work.json`). Mutating commands (tests, formatters, installs, servers) prompt; run them when the task needs the result, and report the output exactly, failures included.
- Smallest diff that does the job. No drive-by refactors, no new files unless the task needs one, no speculative options.
- Finish the whole task. Before "done": name the tests you ran, call out anything skipped and why.
- Risky / multi-step / destructive: drop caveman, state result + verification.
