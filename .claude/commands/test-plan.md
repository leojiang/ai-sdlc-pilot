---
description: Generate a test plan for a story issue
argument-hint: <issue number>
---
1. Run `gh issue view $ARGUMENTS --json title,body,comments` — the acceptance criteria
   are the source of truth.
2. Read the code this story will touch (backend/ is Spring Boot, frontend/ is Flutter),
   to ground the plan in reality.
3. Write docs/test-plans/issue-$ARGUMENTS-test-plan.md:
   - Objective + link to the story
   - Traceability table: acceptance criterion → planned test(s) → layer (unit/integration/E2E)
   - Risk-based priority: which failures would hurt most? Test those hardest.
   - Negative and boundary cases, explicitly listed
   - Test data / environments needed; what stays manual vs automated
4. Post a comment: `gh issue comment $ARGUMENTS --body "Test plan drafted (ai-draft):
   docs/test-plans/issue-$ARGUMENTS-test-plan.md — needs human review."`
5. A human reviews and edits the file, then comments "test plan approved".
   Implementation doesn't start until then.
