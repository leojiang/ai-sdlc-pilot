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

## User Guide: Step-by-Step Workflow

This section walks through a complete development cycle, from drafting a story to shipping code.

### Phase 1: Draft a Story

**Goal:** Capture a feature idea and let AI expand it into a proper story.

1. **Prepare your brief** (2-3 sentences):
   - What problem does it solve?
   - Who benefits?
   - What's the expected outcome?

2. **Run the draft command:**
   ```bash
   /story-draft "As a user, I want to filter stories by status so I can focus on In progress work"
   ```

3. **Review the AI draft:**
   - Claude will create an issue with all required sections (context, acceptance criteria, edge cases, testability notes)
   - Read through the issue carefully
   - Check if acceptance criteria are testable (Given/When/Then format)
   - Identify any missing context or edge cases

4. **Refine if needed:**
   - Edit the issue body directly on GitHub, or
   - Ask Claude to refine with specific feedback (e.g., "add edge case for empty results")
   - The issue starts labeled `ai-draft` and `needs-expansion` — you're in full control

5. **Confirm the draft:**
   - Once satisfied, remove the `ai-draft` label to signal "human approved"
   - The story is now ready for the next phase

### Phase 2: Add to Board and Promote to Ready

**Goal:** Commit to working on this story by moving it to the Ready column.

1. **Check the board:**
   ```bash
   gh project view <project-number> --owner <your-org>
   ```

2. **Add the story to the board:**
   - Open the GitHub Project board in your browser
   - Click "+ Add item" → select the issue from the list
   - The issue is now in the **Backlog** column

3. **Review the story one final time:**
   - Use `/story-refine <issue-number>` to check it against the Definition of Ready
   - Claude will output a table showing what passes and what's missing
   - Edit the issue if needed

4. **Promote to Ready:**
   - On the GitHub Project board, drag the card from **Backlog** to **Ready**
   - This signals "all questions are answered, implementation can start"
   - **Only Ready stories can be started** (enforced by `/start-coding`)

### Phase 3: Start Coding

**Goal:** Create a branch, set up your local environment, and begin implementation.

1. **Lock in the work:**
   ```bash
   /start-coding <issue-number>
   ```
   This command:
   - Verifies the story is at **Ready** status on the board (gate)
   - Creates a branch: `story/<issue#>-short-slug`
   - Moves the board card to **In progress** (automated)
   - Gives you the branch name to check out

2. **Check out the branch:**
   ```bash
   git checkout story/<issue#>-short-slug
   ```

3. **Local setup:**
   ```bash
   make bootstrap    # install dependencies, git hooks
   make lint         # verify your code style locally
   make test         # run tests
   ```

4. **Implement:**
   - Follow the acceptance criteria from the story
   - Write tests alongside code
   - Commit early and often: `git commit -m "feature: describe the change"`

5. **Local quality gate:**
   ```bash
   make lint && make test-coverage
   ```
   Both must pass before pushing (CI enforces the same remotely).

### Phase 4: Push, Create PR, AI Review

**Goal:** Get code reviewed and approved before merge.

1. **Push your branch:**
   ```bash
   git push -u origin story/<issue#>-short-slug
   ```
   - Pushing a `story/*` branch automatically moves the board card to **In progress** (if not already)

2. **Create a Pull Request:**
   ```bash
   gh pr create --fill
   ```
   Or in the browser: click "Compare & pull request" on GitHub.
   
   **Important:** The PR body must reference the story issue:
   ```
   Closes #<issue-number>
   ```
   (Other forms work too: "Fixes #N", "Resolves #N")

3. **Wait for CI:**
   - `lint` — code style check
   - `test` — test suite (must pass)
   - `traceability` — verifies PR closes a story issue
   - `story-gate` — verifies the story is past Backlog (Ready, In progress, or In review)
   - `conventions` — framework-level checks
   - `ai-review` — Claude posts advisory review comments
   - `triage` — if tests fail, Claude classifies the failure

4. **Respond to AI review threads:**
   - Claude's comments are **advisory** — they suggest improvements, not requirements
   - You can:
     - Agree and make the suggested change, then push again
     - Disagree and resolve the thread with a reason ("by design", "not in scope", etc.)
   - All threads must be resolved before merge (GitHub branch protection rule)

5. **Push fixes if needed:**
   ```bash
   git commit -m "fix: address review feedback"
   git push
   ```
   - CI runs again automatically
   - The board card moves to **In review** (automated, when PR opens)

### Phase 5: Human Approval and Merge

**Goal:** Get a human sign-off and merge to main.

1. **Approve the PR:**
   - As a project maintainer, open the PR on GitHub
   - Review the changes and AI review comments
   - Click "Review changes" → "Approve"
   - (Note: `ai-review.yml` is advisory; human approval is required)

2. **Merge:**
   - Click "Merge pull request" on GitHub (or `gh pr merge <pr> --merge`)
   - GitHub auto-closes the issue (because of `Closes #N` in the PR body)
   - The board card moves to **Done** (automated)

3. **Verify:**
   ```bash
   gh issue view <issue-number>
   ```
   - Issue should show "CLOSED" status
   - Board card should be in **Done** column

4. **Delete the branch (optional):**
   ```bash
   git branch -d story/<issue#>-short-slug
   ```

### Phase 6: Follow-up Work

**Goal:** Handle bugs, edge cases, or improvements discovered after merge.

- **If a bug is found:** Create a new story issue (don't reopen the old one)
  - The original story's lifecycle is terminal at Done
  - Follow-up work gets its own issue and PR
  - Link the new story to the original with a comment if needed

- **If enhancement requested:** Same process — new story, new PR

### Useful Commands Reference

| Command | What it does |
|---------|-------------|
| `/story-draft "<brief>"` | AI drafts a new story issue |
| `/story-refine <n>` | Grade story #n against Definition of Ready (pass/fail checklist) |
| `/start-coding <n>` | Verify story #n is Ready, create branch, move board to In progress |
| `/test-plan <n>` | AI drafts a test plan for story #n |
| `/gen-tests <n>` | AI generates test scaffolding for story #n |
| `make bootstrap` | Install dependencies and git hooks |
| `make lint` | Run code style checks |
| `make test` | Run test suite |
| `make test-coverage` | Run tests with coverage report |
| `gh issue list --state all` | View all stories (backlog) |
| `gh issue view <n>` | Read story #n details |
| `gh pr list` | View all pull requests |
| `gh project view <n> --owner <org>` | View the board |

### Common Questions

**Q: Can I start coding before the story is Ready?**
- A: No — `/start-coding` enforces the Ready gate. Backlog stories are refused. This ensures all questions are answered before you write code.

**Q: What if I push to the wrong branch by mistake?**
- A: No problem. The board automation only reacts to:
  - `story/*` branches (for In progress)
  - Non-draft PRs that reference issues (for In review)
  - Merged PRs (for Done)
  - Other branches are ignored by the workflow.

**Q: Do I have to follow AI review feedback?**
- A: No. AI review is advisory. You can resolve threads with a reason. But all threads must be resolved before GitHub allows merge (branch protection rule).

**Q: What if tests fail?**
- A: The `triage` job automatically classifies the failure (real regression vs flaky test vs environment issue) and posts an analysis. Fix the issue and push — CI runs again.

**Q: Can I reopen a closed story?**
- A: Not recommended. If new work is needed, open a new issue (follow-up story). The original story's lifecycle is terminal at Done.

**Q: How do I check if the board is set up correctly?**
- A: Run:
  ```bash
  gh project field-list <project-number> --owner <org>
  ```
  Look for the Status field with options: Backlog, Ready, In progress, In review, Done
