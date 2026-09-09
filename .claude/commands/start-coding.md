---
description: Start work on a story — mechanical Ready gate, sync main, create and push the story branch, then implement
argument-hint: <issue number>
---
The single entry point for implementation work. Run the steps in order — the first
check that fails stops the whole command. Never skip step 1-2 "just to get started".

1. Read the issue: `gh issue view $ARGUMENTS --json state,title,body`.
   Missing issue → STOP. Closed issue → STOP and say so: a story's lifecycle is terminal
   at Done, follow-up work gets its own issue (CLAUDE.md).

2. Board gate — check the card's Status (the `/story-status` query):
   gh api graphql -f query='query($o: String!, $r: String!, $n: Int!){ repository(owner: $o, name: $r){ issue(number: $n){ projectItems(first: 10){ nodes{ fieldValues(first: 10){ nodes{ ... on ProjectV2ItemFieldSingleSelectValue{ name field{ ... on ProjectV2SingleSelectField{ name } } } } } } } } } } }' -f o=leojiang -f r=ai-sdlc-pilot -F n=$ARGUMENTS
   Read the value of the field named `Status` (no `Status` value or no card at all =
   not on the board). Then:
   - **Ready** → continue with step 3
   - **In progress** → resume mode: `git switch` to the existing `story/$ARGUMENTS-*`
     branch if present (`git branch --list 'story/$ARGUMENTS-*'`), else continue with
     step 3 to create it; skip to step 5 either way
   - **Backlog** → STOP: "Card #$ARGUMENTS is at Backlog — review it and promote it to
     Ready first." Create no branch, write no code, wait for the user
   - **not on the board / Done / In review** → STOP with guidance: follow-up work needs
     a new issue; an unboarded story needs boarding before it can be worked on

3. Sync: `git checkout main && git pull --ff-only`.
   If it fails — dirty working tree, untracked files in the way, diverged history —
   STOP and show the exact git output. Never stash, force, reset, or clean on the
   user's behalf.

4. Branch: `git checkout -b story/$ARGUMENTS-<short-slug>` (match the story to a
   1-3 word slug), then `git push -u origin story/$ARGUMENTS-<short-slug>`.
   This push moves the card to In progress (story-status.yml) — that is expected and
   is the lifecycle connecting, not a side effect to suppress.

5. Implement per CLAUDE.md: acceptance criteria are the contract; draft a test plan with
   `/test-plan $ARGUMENTS` and generate tests with `/gen-tests` where applicable;
   `make lint` and `make test` must pass before each push. End by opening the PR to
   `main` whose body contains a closing keyword for the story ("Closes #$ARGUMENTS") —
   story-review.yml then moves the card to In review.

Merging is never part of this command. The merge click belongs to a human, always.
