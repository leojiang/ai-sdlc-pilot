# Test plan — issue #30 (/start-coding: mechanical Ready gate at work start)

Story: #30 · PR: #31 · Drafted mid-implementation per start-coding step 5's own rule
(the plan was missing when work began — noted in the PR body, as the rule requires).

## Objective
Prove the single-lock model end to end: `/start-coding <n>` refuses anything that is
not Ready/In progress, and its Ready proceed path connects the lifecycle (branch push
→ card In progress). This is a command-docs story: validation is witnessed procedure,
not executable tests.

## Traceability (AC → evidence → layer)

| Acceptance criterion | Evidence | Layer |
|---|---|---|
| Backlog → STOP, no branch, no code | Act 1: gate run against #28 (Backlog) → refused | witnessed procedure |
| Ready → proceed | Act 2: #30 → sync → branch pushed → run 34321063802 moved card Ready → In progress | witnessed event |
| Step-2 query executes **verbatim** from the file | Round-3 🔴 (11 closing braces) fixed by splicing story-status.md's byte-identical query; fix commit re-runs the file's exact line against #28 and #30 | witnessed in fix commit |
| In progress → resume mode | Spec only: ls-remote authoritative lookup, single-match, --track for remote-only | manual — first real resume run |
| Multi-match / dirty tree / ff-only refusal / In review / Done / unboarded STOPs | Spec only | manual — next natural occurrences |
| CLAUDE.md + commands + PR template carry no present-tense comment gate | grep across repo in review round 3 | checked |
| Workflow layers unchanged (story-status.yml / story-gate) | Out of scope by AC; CI green on every push | automated (CI) |

## Risks / what stays manual
- The STOP branches and resume path are prose until reality exercises them; each
  unwitnessed branch is expected to surface as a small follow-up, not a reopen.
- The gate query is duplicated (start-coding.md and story-status.md must stay
  byte-identical); the round-3 brace bug came from hand-copying. Now guarded
  mechanically: `make check-gate-query` (part of `make lint` and CI) fails on any
  drift between the copies.
