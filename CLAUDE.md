# ai-sdlc-pilot

Pilot repository for our AI-augmented software development lifecycle. Currently validating the AI story-drafting workflow (GitHub Issues + Claude Code) before rolling it out to real project repos.

## Team conventions

### Workflow
- Every change starts as a GitHub Issue (story).
- Stories labeled `ai-draft` were drafted by AI and **require human review** before being worked on.
- The AI never: transitions issue state, assigns people, removes the `ai-draft` label, or closes issues.
  Board status changes come only from event-driven automation (branch push, PR link, merge) — never from the agent.
- Branches: `story/<issue#>-short-slug`. PRs to `main` only — no direct pushes.
- A PR merges only when CI (lint/test/traceability) is green, AI review threads are resolved,
  and a human approves. PR body must reference the issue ("Closes #N").
- A story's lifecycle is terminal at Done: follow-up work on a merged story gets its own
  issue; board automation ignores pushes to a closed story's branch.
- Before writing implementation code, check the story's board status and test-plan approval
  (`/story-status <n>`). If the card is at Backlog or not on the board, STOP: remind the
  user to review the story and promote it to Ready, then wait for their instruction.
  Implementation starts on Ready stories only — CI refuses Backlog → In progress on
  branch push, and PRs do not move Backlog cards to In review.

### Board lifecycle (SDLC Pilot project)
Status moves are automatic consequences of verifiable events — the only manual move is the first one:
- **Ready** — a human promotes the story after review
- **In progress** — first push of the `story/<issue#>-*` branch (`.github/workflows/story-status.yml`) — Ready stories only: a Backlog card is refused until a human promotes it
- **In review** — a non-draft PR closes the story (on open, or on a body edit that adds the closing ref — `.github/workflows/story-review.yml`)
- **Done** — a PR closing the story merges (`.github/workflows/story-done.yml`); the issue auto-closes (GitHub built-in). A story closed as completed without a merge is healed to Done by the next story-done run — closed-as-completed means Done, however it closed. (Healing covers carded stories; never-boarded closed stories are a known residual — #25.)

### Definition of Done
A story is done when its PR merges, and all of the following held at merge time:
1. Every acceptance criterion has a passing test, traceable via the test plan
2. The test plan was human-approved before implementation started
3. `lint`, `test`, and `traceability` CI checks are green
4. All AI review threads are resolved, or explicitly dismissed with a reason
5. A human clicked merge
6. The story's own lifecycle fired — the board shows its trail (Backlog → … → Done)
Merge closes the issue and moves the board item to Done automatically.

### Story template (required — used by /story-draft)
Every story contains these sections:
- **Context** — the problem/opportunity, 2-4 sentences
- **User story** — "As a \<role\>, I want \<capability\>, so that \<benefit\>."
- **Acceptance criteria** — Given/When/Then bullets, each independently testable
- **Edge cases & error handling** — at least 3
- **Out of scope** — explicitly excluded
- **Open questions** — what a human must decide before Ready
- **Testability notes** — risk areas the test plan should focus on

### Commands
- `make bootstrap` — install dependencies and git hooks
- `make lint` / `make test` — must pass locally before pushing
- `gh issue list --state all` — see the backlog
- `gh issue view <n>` — read a story

## Architecture map
(No code yet — this is a workflow pilot. Fill this in when real code lands.)
