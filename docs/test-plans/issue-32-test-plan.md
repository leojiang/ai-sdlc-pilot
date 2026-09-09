# Test plan — issue #32 (/start-coding step 6: mandatory AI-review convergence loop)

Story: #32 · Drafted mid-implementation per start-coding step 5's own rule (the plan
was missing when work began — noted in the PR body, as the rule requires; same
precedent as #30).

## Objective
Make the local AI-review convergence loop procedural: one scripted invocation
(`scripts/ai-review.sh`), identical across rounds, wired into `/start-coding` as a
mandatory step after the PR exists. The loop's own behavior is validated by
meta-dogfooding — this story's PR is the first to run it end to end.

## Traceability (AC → evidence → layer)

| Acceptance criterion | Evidence | Layer |
|---|---|---|
| `scripts/ai-review.sh <pr> [round-context…]` CLI shape exists | Fixture: stubbed `claude` on PATH captures argv — asserts `--max-turns 30`, the read-only allowlist (`gh pr diff/view`, `gh issue view`, `git log/show`, `Read`, `Grep`, `Glob`), and `--disallowedTools` denying 20 write forms (`gh pr comment/edit/merge/create/close/ready/review`, `gh issue comment/edit/create/delete/develop/transfer/reopen/lock/unlock/pin/unpin/add-sub-issue/remove-sub-issue`) — project settings allow `Bash(gh issue *)` and merge over `--allowedTools` (rounds 8-9 🟡 findings; enumeration is gh-version-bound by construction, deny cannot be broad or it would override the needed `gh issue view` allow) | automated — `make check-ai-review` (in `make lint`, hence CI) |
| Review prompt missing or unreadable refuses with a clear message | Fixture: temp git repo without `.claude/prompts/pr-review.md` ("prompt not found") and with a chmod-000 one ("prompt not readable") — both exit 1 (round-9 💬 finding, pinned) | automated — `make check-ai-review` |
| Assembles `.claude/prompts/pr-review.md` + PR number + round context, pipes to `claude -p` | Fixture: same stub captures stdin — asserts prompt contains the verbatim prompt file, the PR number, and each round-context arg | automated — `make check-ai-review` |
| Blocking, prints the review to stdout | Fixture: stub writes a sentinel to stdout; script's stdout must be exactly the sentinel (no interleaved chatter) | automated — `make check-ai-review` |
| Failed round (claude exits nonzero) dies with a clear message, never an empty review | Fixture: failing stub — nonzero exit + "claude exited 1 —" (with the code) on stderr + empty stdout (round-2 💬 finding, pinned) | automated — `make check-ai-review` |
| Silent round (claude exits 0 with no output) is a failed round too | Fixture: silent stub — exit 1 + "produced no review" on stderr + empty stdout (round-5 💬 finding, pinned); whitespace-only output likewise (round-9 💬) | automated — `make check-ai-review` |
| Refuses outside a git repo, clear message | Fixture: run from a `mktemp -d` — expect nonzero exit + message naming the git-repo requirement | automated — `make check-ai-review` |
| Refuses when `claude` is not on PATH, clear message | Fixture: temp git repo, PATH containing only symlinked `bash`+`git` — nonzero exit + message naming `claude`/PATH (deterministic wherever claude lives; the initial `/usr/bin:/bin` assumption was a round-1 review 💬) | automated — `make check-ai-review` |
| Refuses when `git` is not on PATH — message names git, never a misleading "not inside a repository" | Fixture: PATH with only symlinked `bash` — nonzero exit + message naming the missing git binary | automated — `make check-ai-review` |
| `/start-coding` gains step 6 (6 sub-steps: run → fix → re-run w/ round context + checks → convergence definition → 10-round budget/STOP → hand to user) | Witnessed on this story's own PR: the loop runs per the new text, verbatim; coupling to the script pinned mechanically — `check-ai-review` greps start-coding.md for the `scripts/ai-review.sh <pr>` invocation (round-3 💬, check-gate-query class) | meta-dogfood (witnessed procedure) |
| Loop demonstrably iterates before converging; invocation identical across rounds | PR timeline: ≥1 finding → fix commit → re-review with round context; the command line differs between rounds only in the quoted round-context arg | witnessed in PR |
| CLAUDE.md workflow section notes the loop (procedural via `/start-coding`; `ai-review.yml` stays the per-push backstop; findings advisory) | Review + grep of CLAUDE.md | checked |

## Risks / what stays manual
- The stub fixture never calls the real `claude` binary — API/agent behavior is
  covered only by the meta-dogfood run on this PR. A regression in the *real*
  invocation path (auth, flags rejected by the CLI) surfaces there, not in CI.
- The 10-round budget STOP and the convergence verdict parsing are agent-procedure,
  not script logic — they stay prose until reality exercises them (same stance as
  #30's unwitnessed STOP branches).
- Round-context wording is freeform by design (it summarizes the fixes); the
  invariant pinned by fixtures is the *script's* contract, not the context text.
