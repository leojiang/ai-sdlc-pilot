# AI-Augmented SDLC Template

A reusable framework for AI-augmented software development: GitHub Issues (stories) +
GitHub Projects (board) + GitHub Actions (CI/CD) + Claude Code (AI agent).

**Core principle:** AI drafts everything, humans decide everything. Every artifact
(stories, test plans, code, reviews) starts as an AI draft; every gate (approval,
merge) is a human decision.

## Start your own project

Clone this repo, then run the interactive setup command:

```bash
git clone https://github.com/leojiang/ai-sdlc-pilot.git my-project
cd my-project
rm -rf .git && git init    # clean history — start fresh
claude
> /init-sdlc "My Project Name"
```

The `/init-sdlc` command guides you through everything:

1. **Prerequisites** — verifies gh, git, and your stack-specific tools
2. **GitHub repo** — creates a new repo or uses an existing one
3. **Framework files** — customizes CLAUDE.md, Makefile, CI, .gitignore for your tech stack
4. **Project board** — creates a GitHub Project with the Status field (Backlog → Ready → In progress → In review → Done)
5. **Labels** — creates `story`, `ai-draft`, `needs-expansion`, `flaky`
6. **Branch protection** — applies rules from `.github/branch-protection.json`
7. **Secrets** — walks you through setting PROJECT_TOKEN and ANTHROPIC_AUTH_TOKEN

**Note:** Public repos are recommended — GitHub Free cannot enforce branch protection
rules (required reviews, required status checks) on private repos.

## How the workflow works

```
Story flow:   idea → /story-draft → Issue [ai-draft] → HUMAN review → Ready
Dev flow:     /start-coding <n> → branch → implement → PR → AI review → HUMAN merge
Board flow:   Backlog → Ready (human) → In progress → In review → Done (all automated)
```

| Who | What |
|---|---|
| AI (Claude Code) | Drafts stories, test plans, code, reviews (advisory) |
| Human | Reviews drafts, promotes to Ready, resolves review threads, clicks merge |
| Automation | Moves board cards on git events (push, PR, merge) |

## What's in the template

```
CLAUDE.md                       # conventions — read by humans AND the AI
.claude/commands/               # /init-sdlc, /story-draft, /story-refine,
                                # /story-status, /test-plan, /gen-tests, /start-coding
.claude/prompts/pr-review.md    # AI reviewer instructions (advisory output)
.claude/settings.json           # dev-session permissions
.claude/settings.review.json    # read-only review-session permissions
.github/workflows/              # CI gates + board automation
.github/actions/project-lookup/ # shared board project/field/option lookup
.github/branch-protection.json  # branch protection rules (applied by /init-sdlc)
scripts/                        # ai-review.sh + fixtures
docs/test-plans/                # per-story test plans (created during development)
Makefile                        # bootstrap / lint / test + framework drift checks
```

## After setup

Draft your first story:
```
/story-draft "<one-paragraph feature brief>"
```

Review the draft → confirm → issue created → promote to Ready on the board → then:
```
/start-coding <issue-number>
```

## CI secrets

| Secret | Used by | Effect when missing |
|---|---|---|
| `PROJECT_TOKEN` | board-add / story-status / story-review / story-done / story-gate | Board never moves; Ready gate stays open |
| `ANTHROPIC_AUTH_TOKEN` (+ `ANTHROPIC_BASE_URL`, `ANTHROPIC_DEFAULT_*_MODEL`) | ai-review / triage | No AI review; no failure triage |

Both skip gracefully with warnings when missing — CI doesn't block, but the gates
aren't enforced.

## Everyday commands

```bash
make lint          # framework checks + your stack's linter
make test          # your stack's test suite
make test-coverage # tests with coverage report
```

Run these before pushing — CI runs the same.
