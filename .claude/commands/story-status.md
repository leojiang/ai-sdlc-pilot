---
description: Read-only check of a story's board status and test-plan approval before starting work
argument-hint: <issue number>
---
Check, report, and change nothing:

1. Board status — run:
   gh api graphql -f query='query($o: String!, $r: String!, $n: Int!){ repository(owner: $o, name: $r){ issue(number: $n){ state title projectItems(first: 10){ nodes{ fieldValues(first: 10){ nodes{ ... on ProjectV2ItemFieldSingleSelectValue{ name field{ ... on ProjectV2SingleSelectField{ name } } } } } } } } } }' -f o=leojiang -f r=ai-sdlc-pilot -F n=$ARGUMENTS
   Report the issue state and the card's Status field value (or "not on the board").

2. Test plan — check whether docs/test-plans/issue-$ARGUMENTS-test-plan.md exists, and
   whether the issue carries a "test plan approved" comment (gh issue view $ARGUMENTS --comments).

Gate rule (CLAUDE.md): if the card is at **Backlog** or not on the board, do NOT start
implementation. Tell the user: the story needs review and Ready promotion first, and
summarize what the story would need (acceptance criteria quality, test plan). Wait for
their instruction. Only proceed on Ready (or later) with an approved test plan.
