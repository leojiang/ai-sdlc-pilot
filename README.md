# ai-sdlc-pilot

Pilot repo for the AI-augmented SDLC workflow: GitHub Issues (stories) + Claude Code (AI agent).

## Try it

```bash
claude
```
```
/story-draft "<one-paragraph feature brief>"
```

AI drafts the story → you review and confirm → it's created with `story` + `ai-draft` labels →
a human reviews it in the browser before it counts as Ready.

## Files that matter

- `CLAUDE.md` — conventions + the story template (read by humans and the AI)
- `.claude/commands/story-draft.md` — the story-drafting workflow
- `.claude/commands/story-refine.md` — Definition-of-Ready check
