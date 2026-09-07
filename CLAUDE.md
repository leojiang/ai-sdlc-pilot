# ai-sdlc-pilot

Pilot repository for our AI-augmented software development lifecycle. Currently validating the AI story-drafting workflow (GitHub Issues + Claude Code) before rolling it out to real project repos.

## Team conventions

### Workflow
- Every change starts as a GitHub Issue (story).
- Stories labeled `ai-draft` were drafted by AI and **require human review** before being worked on.
- The AI never: transitions issue state, assigns people, removes the `ai-draft` label, or closes issues.
- Branches: `story/<issue#>-short-slug`. PRs to `main` only — no direct pushes.
- A PR merges only when CI (lint/test/traceability) is green, AI review threads are resolved,
  and a human approves. PR body must reference the issue ("Closes #N").

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
