---
description: Initialize a new project with the AI-augmented SDLC framework — repo, board, labels, branch protection, and all template files
argument-hint: <project name in quotes>
---
You are setting up a brand-new project with the AI-augmented SDLC framework. This is
a multi-phase guided setup — confirm with the user before each phase that changes
external state. Never skip a phase or proceed after a failure.

## Phase 1 — Collect information

1. **Project name**: use $ARGUMENTS if provided, otherwise ask the user.
2. Ask the user for the following (show sensible defaults in brackets):
   - **One-paragraph description** — what the product does and for whom
   - **GitHub owner** — org name or personal username
     (default: infer from `gh api user -q .login`)
   - **Team lead GitHub username** for CODEOWNERS (default: same as owner)
   - **Repo visibility** — public (recommended) or private.
     If the user picks **private**, warn clearly:
     > GitHub Free cannot enforce branch protection rules (required reviews,
     > required status checks, CODEOWNERS) on private repos — you need GitHub Pro
     > ($4/mo) or Team ($4/user/mo). The workflow's other layers (CI checks,
     > `/start-coding` gate, board automation) still work, but the hard merge
     > backstop won't be active. GitHub Free also limits Actions to 2,000 min/month
     > on private repos — a self-hosted runner is strongly recommended.
   - **Backend stack** — Spring Boot (Java) / Node.js (Express) / Python (FastAPI) / Go / None / Other
   - **Frontend stack** — Flutter / React (TypeScript) / Vue / Angular / None / Other
3. Show a summary table of all collected values and ask for confirmation before
   continuing. If the user changes anything, update and re-confirm.

## Phase 2 — Prerequisites check

Verify each prerequisite. For any failure, print the fix command and STOP — do not
continue with a broken environment.

1. `git --version` — must exist
2. `gh --version` — must exist
3. `gh auth status` — must be authenticated; check output for `project` scope.
   If missing: tell the user to run `gh auth refresh -h github.com -s project`
   and STOP.
4. `jq --version` — required by board workflows
5. Stack-specific checks (only for the chosen stacks):
   - Spring Boot → `java -version` (JDK 17+)
   - Flutter → `flutter --version` (stable channel)
   - Node.js → `node --version` (18+)
   - Python → `python3 --version` (3.10+)
   - Go → `go version` (1.21+)

## Phase 3 — GitHub repository setup

1. Check if already in a git repo with a GitHub remote:
   `git remote get-url origin 2>/dev/null`
   - **Has remote**: confirm with user: "Use existing repo <owner/repo>?"
   - **No remote or no git repo**: initialize and create:
     ```
     git init   (only if not already a repo)
     gh repo create <owner>/<project-name> --source . --<visibility> --push
     ```
2. Verify the remote exists: `gh repo view --json nameWithOwner -q .nameWithOwner`
   If this fails, STOP.
3. Store the repo coordinates for later steps:
   ```
   REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
   OWNER=${REPO%/*}; REPO_NAME=${REPO#*/}
   ```

## Phase 4 — Generate and customize framework files

This is the core of the command. Tell the user you're about to write the framework
files and confirm before proceeding.

### 4a. Files that are fully generic (write as-is from the current repo)

These files are already correct in the template repo and need no modification. If any
are missing (e.g. the user started from a clean clone and deleted them), regenerate
them exactly as they exist in this repo:

- `.claude/commands/story-draft.md`
- `.claude/commands/story-refine.md`
- `.claude/commands/story-status.md`
- `.claude/commands/test-plan.md`
- `.claude/commands/start-coding.md`
- `.claude/commands/gen-tests.md`
- `.claude/prompts/pr-review.md`
- `.claude/settings.json`
- `.claude/settings.review.json`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/actions/project-lookup/action.yml`
- `.github/workflows/ai-review.yml`
- `.github/workflows/deploy.yml`
- `scripts/ai-review.sh`
- `scripts/ai-review.fixture.sh`
- `scripts/heal-filter.jq`
- `scripts/heal-filter.fixture.json`
- `.pre-commit-config.yaml` (the gitleaks base)
- `.github/branch-protection.json` (rules applied in Phase 8)

### 4b. Project-title substitution (4 board workflow files)

In each of these files, replace the `PROJECT_TITLE` env value with the user's project
name (the value that will match the GitHub Project title created in Phase 5):

- `.github/workflows/board-add.yml` — change `PROJECT_TITLE: SDLC Pilot` to `PROJECT_TITLE: <project name>`
- `.github/workflows/story-status.yml` — same substitution
- `.github/workflows/story-review.yml` — same substitution
- `.github/workflows/story-done.yml` — same substitution

Also in `.github/workflows/ci.yml`, the `story-gate` job has `PROJECT_TITLE: SDLC Pilot` — replace it too.

### 4c. Stack-adaptive files (generate based on chosen stack)

For each file below, generate content adapted to the user's chosen backend and frontend
stack. Use the existing file as a structural reference but replace stack-specific parts.
If the user chose "Other" for either stack, use `# ADAPT` comment markers with clear
instructions for what to fill in.

**`CLAUDE.md`** — Rewrite with:
- Project name and description from Phase 1
- The **Workflow** section stays identical (it is stack-agnostic)
- The **Board lifecycle** section stays identical
- The **Definition of Done** section stays identical
- The **Story template** section stays identical
- The **Code style** section: generate rules appropriate for the chosen stack
  (e.g., Java: Google Java Format; Node.js: ESLint + Prettier strict TypeScript;
  Python: ruff; Flutter: flutter analyze; Go: gofmt + go vet)
- The **Commands** section: `make bootstrap`, `make lint`, `make test` (same names,
  stack-specific descriptions of what they run)
- The **Architecture map** section: a starter tree showing the chosen stack's
  conventional layout (e.g., `src/main/java/...` for Spring Boot, `src/` for Node,
  `lib/` for Flutter). Include `# ADAPT as the codebase grows` note.

**`Makefile`** — Generate with the 4 standard targets adapted to the stack:

| Target | Spring Boot | Node.js | Python (FastAPI) | Flutter | Go |
|---|---|---|---|---|---|
| bootstrap | `./mvnw dependency:go-offline compile` | `npm install` | `pip install -e ".[dev]"` | `flutter pub get` | `go mod download` |
| lint | `./mvnw -DskipTests compile` | `npm run lint` | `ruff check . && ruff format --check .` | `flutter analyze` | `go vet ./...` |
| test | `./mvnw test` | `npm test` | `pytest` | `flutter test` | `go test ./...` |
| test-coverage | `./mvnw verify jacoco:report` | `npm test -- --coverage` | `pytest --cov` | `flutter test --coverage` | `go test -coverprofile=coverage.out ./...` |

If both backend and frontend are chosen, each target runs both (backend first, then
frontend), following the existing Makefile pattern with `if [ -d backend ]; then ...`.

Always include the framework-level lint checks that already exist in the Makefile:
`check-gate-query`, `check-ai-review`, `check-ai-review-tools`, `check-review-settings`.

**`.editorconfig`** — Keep the generic root block (charset, EOL, whitespace). Add
language-specific sections for the chosen stacks (e.g., `[*.java]` indent_size 4,
`[*.py]` indent_size 4, `[*.dart]` indent_size 2, `[*.go]` indent_style tab).
Always include `[Makefile]` with tab indent.

**`.gitignore`** — Generate for the chosen stacks. Always include: `.env*`, `.DS_Store`,
`*.log`, `.idea/`, `.vscode/`, `*.iml`. Add stack-specific patterns
(e.g., `target/` for Java, `node_modules/` for Node, `__pycache__/` for Python,
`build/` for Flutter, vendor for Go).

**`.github/workflows/ci.yml`** — Adapt the `lint` and `test` jobs' setup steps and
env vars for the chosen stack. Keep the `traceability`, `story-gate`, `conventions`,
and `triage` jobs exactly as they are (they are stack-agnostic). Specific adaptations:
- Spring Boot: `actions/setup-java@v4` with temurin 17
- Node.js: `actions/setup-node@v4` with node 20
- Python: `actions/setup-python@v5` with python 3.12
- Flutter: `subosito/flutter-action@v2` + `actions/setup-java@v4`
- Go: `actions/setup-go@v5`
- Coverage artifact paths: adapt to the stack's coverage output location
- Remove the `PUB_HOSTED_URL` env and `check-pub-host` steps unless Flutter is chosen
- Remove the `Pub-host guard smoke` step unless Flutter is chosen

**`README.md`** — Generate a new README with:
- Project name and description
- A "Development" section with prerequisites for the chosen stack
- First-time setup (`make bootstrap`)
- Everyday commands (`make lint`, `make test`)
- A brief "AI-augmented SDLC" section explaining the workflow and linking to
  CLAUDE.md for details
- A note about required secrets (PROJECT_TOKEN, ANTHROPIC_AUTH_TOKEN)

### 4d. Username substitution

**`.github/CODEOWNERS`** — Write `* @<team-lead-username>` using the value from Phase 1.

### 4e. Optional files

**`.github/ISSUE_TEMPLATE/story.yml`** — Create the story intake form for non-developers:
```yaml
name: Story brief
description: Raw brief — AI will expand it into a full story draft
labels: [story, ai-draft, needs-expansion]
body:
  - type: textarea
    id: brief
    attributes:
      label: Feature brief
      description: The problem or opportunity, in plain language
    validations:
      required: true
  - type: textarea
    id: context
    attributes:
      label: Constraints / context
      description: Deadlines, dependencies, must-nots
```

**`docs/test-plans/.gitkeep`** — Create the empty directory.

## Phase 5 — Clean up pilot-specific content

Delete files and directories that belong to the pilot, not the framework.
Before deleting, confirm with the user: "I'm about to remove pilot-specific files
(backend/, frontend/, pilot test plans, etc.). Confirm?"

Delete:
- `backend/` directory (unless the user chose Spring Boot AND wants to keep the scaffold)
- `frontend/` directory (unless the user chose Flutter AND wants to keep the scaffold)
- `docs/test-plans/issue-1-test-plan.md`
- `docs/test-plans/issue-30-test-plan.md`
- `docs/test-plans/issue-32-test-plan.md`
- `docs/screenshots/` directory
- `ONBOARDING.md` (if it exists — pilot-specific)
- `.claude/settings.local.json` (machine-specific, not part of template)
- Any `.idea/` directories under backend/ or frontend/
- Any `*.iml` files

Do NOT delete:
- `.claude/commands/init-sdlc.md` (this command itself — useful for reference)
- Any file listed in Phase 4 sections a-d
- The `.git/` directory

## Phase 6 — Create GitHub Project board

Tell the user: "I'm about to create a GitHub Project board and link it to your repo.
This requires the `project` scope on your gh token." Confirm before proceeding.

1. Create the project:
   ```
   gh project create --owner <owner> --title "<project name>" --format json
   ```
   Parse the project number from the JSON output.

2. Create the Status field with all required options:
   ```
   gh project field-create <number> --owner <owner> --name "Status" --data-type "SINGLE_SELECT" --single-select-options "Backlog,Ready,In progress,In review,Done"
   ```

3. Link the project to the repository:
   ```
   gh project link <number> --owner <owner> --repo <owner>/<repo-name>
   ```

4. Verify: `gh project field-list <number> --owner <owner> --format json`
   Check that the Status field exists with all 5 options.

If any step fails, show the error and the manual alternative (go to
github.com → Projects → New project → add Status field manually). Do not STOP the
whole init — the rest of the setup can proceed without the board, though board
automation won't fire until it's configured.

5. **Disable built-in project workflows that race our custom automation.**
   The GitHub Projects API does not support toggling built-in workflows, so print
   clear manual instructions for the user:

   > **Important — manual step required:**
   > Go to your project board → ⋯ menu → **Settings** → **Workflows** and:
   > - **Disable** "Pull request linked to issue" — our `story-review.yml` handles this with a Ready gate
   > - **Disable** "Pull request merged" — our `story-done.yml` handles this deterministically with a heal sweep
   > - **Keep enabled**: "Item added to project", "Item closed", "Auto-close issue"
   >
   > If the built-in workflows stay on, they race our custom workflows and can
   > move cards to the wrong status. This is the one manual step that can't be
   > automated.

   Also query the project's current workflow state to confirm what needs changing:
   ```
   gh api graphql -f query='query($login: String!, $n: Int!) {
     user(login: $login) { projectV2(number: $n) {
       workflows(first: 20) { nodes { name enabled } }
     } }
   }' -f login=<owner> -F n=<project-number>
   ```
   Show the user the current state so they can see exactly which toggles to flip.

## Phase 7 — Create labels

Create the 4 required labels (skip with a note if they already exist — `gh label create`
errors on duplicates, so check first with `gh label list --json name -q '.[].name'`):

```
gh label create story          --description "User story"                     --color 0E8A16
gh label create ai-draft       --description "AI-drafted; needs human review" --color D4C5F9
gh label create needs-expansion --description "Raw brief; CI will expand it"  --color FBCA04
gh label create flaky          --description "Quarantined flaky test"         --color F9D0C4
```

## Phase 8 — Branch protection (public repos only)

Branch protection rules are stored in `.github/branch-protection.json` — the single
source of truth. This file mirrors the pilot repo's proven settings: required status
checks (lint, test, story-gate), enforce admins, dismiss stale reviews, required linear
history, required conversation resolution, no force pushes, no deletions.

If the repo is **private**, skip this phase and print:
> Branch protection requires GitHub Pro/Team for private repos. The rules are saved
> in `.github/branch-protection.json` — apply them manually after upgrading, or switch
> to a public repo. The workflow's other enforcement layers (CI checks, `/start-coding`
> gate, board automation) still work without branch protection.

If the repo is **public**, confirm with the user, then apply the protection rules:

```
gh api repos/<owner>/<repo-name>/branches/main/protection -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input .github/branch-protection.json
```

After applying, verify:
```
gh api repos/<owner>/<repo-name>/branches/main/protection
```

If this fails (e.g., insufficient permissions), print the contents of
`.github/branch-protection.json` as a manual checklist and continue.

The user can customize the rules later by editing `.github/branch-protection.json`
and re-applying with the same `gh api` command.

## Phase 9 — Secrets guidance

Secrets cannot be set silently. Guide the user through each one:

1. **PROJECT_TOKEN** — a GitHub PAT (classic) with the `project` scope. Required for
   board automation. Walk the user through:
   - Create at github.com → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
   - Scope: `project` (and `repo` if the repo is private)
   - Then: `gh secret set PROJECT_TOKEN` (paste the token when prompted)

2. **ANTHROPIC_AUTH_TOKEN** — the API key or token for the AI model endpoint. Required
   for AI review and failure triage:
   `gh secret set ANTHROPIC_AUTH_TOKEN`

3. **ANTHROPIC_BASE_URL** (optional) — only if using a non-Anthropic-compatible endpoint:
   `gh secret set ANTHROPIC_BASE_URL`

4. **Model overrides** (optional) — if using a custom model endpoint that remaps model
   names (e.g., GLM), set:
   `gh secret set ANTHROPIC_DEFAULT_SONNET_MODEL`
   `gh secret set ANTHROPIC_DEFAULT_HAIKU_MODEL`
   `gh secret set ANTHROPIC_DEFAULT_OPUS_MODEL`

Tell the user: "The board workflows and AI review will skip gracefully if these secrets
are missing — they emit warnings but don't block. You can set them now or later."

## Phase 10 — Initial commit and verification

1. Stage and commit everything:
   ```
   git add -A
   git commit -m "bootstrap: AI-augmented SDLC framework for <project name>"
   ```
2. Push: `git push -u origin main`
   (If this is a fresh repo, the push may need `--force` if gh repo create already
   pushed an empty commit — confirm with the user before force-pushing.)

3. Run verification checks:
   - `make lint` — should pass (at least the framework-level checks)
   - `gh project list --owner <owner>` — should show the board
   - `gh label list` — should show all 4 labels
   - If public: `gh api repos/<owner>/<repo>/branches/main/protection` — should return the rules

4. Print the **"What's next"** summary:
   ```
   ✅ Project "<project name>" is set up with the AI-augmented SDLC framework.

   Secrets to configure (if not done above):
     gh secret set PROJECT_TOKEN        # PAT with project scope — board automation
     gh secret set ANTHROPIC_AUTH_TOKEN  # AI model API key — AI review + triage

   Your first story:
     claude
     > /story-draft "<one-paragraph feature brief>"
     # Review the draft → confirm → issue created with story + ai-draft labels
     # Go to the Project board → promote the card from Backlog to Ready

   Start coding:
     > /start-coding <issue-number>
     # Gate-checks Ready → syncs main → branches → implements → opens PR

   Everyday commands:
     make lint          # must pass before pushing
     make test          # must pass before pushing
     /story-status <n>  # check where a story stands on the board
   ```

Never: create issues, draft stories, or start implementation during init. The setup
is complete when the framework files are committed and the GitHub resources exist.
