#!/usr/bin/env bash
# Fixtures pinning scripts/ai-review.sh's contract (issue #32 test plan):
# refusal paths, prompt assembly, read-only allowlist, toplevel workspace, and
# stdout pass-through — all against a stubbed `claude`, so lint/CI catch drift
# without any API call. Style: fail fast on the first bad assertion.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SUBJECT="$HERE/ai-review.sh"
REPO=$(git -C "$HERE" rev-parse --show-toplevel)
PROMPT_FILE="$REPO/.claude/prompts/pr-review.md"
N=0

ok() { N=$((N + 1)); }
bad() { echo "ERROR: ai-review fixture failed: $*" >&2; exit 1; }

# --- arg validation -----------------------------------------------------------
RC=0; OUT=$("$SUBJECT" 2>&1) || RC=$?
[ "$RC" -eq 2 ] || bad "no args should exit 2 (usage), got $RC"
case "$OUT" in *usage*) ok ;; *) bad "no-arg run must print usage, got: $OUT" ;; esac

RC=0; OUT=$("$SUBJECT" not-a-number 2>&1) || RC=$?
[ "$RC" -eq 1 ] || bad "non-integer PR should exit 1, got $RC"
case "$OUT" in *integer*) ok ;; *) bad "non-integer run must say 'integer', got: $OUT" ;; esac

"$SUBJECT" 0 >/dev/null 2>&1 && bad "PR 0 must be rejected" || ok

# --- refusal: outside a git repository ---------------------------------------
TMP=$(mktemp -d)
RC=0; OUT=$(cd "$TMP" && "$SUBJECT" 7 2>&1) || RC=$?
[ "$RC" -eq 1 ] || bad "outside-repo run should exit 1, got $RC"
case "$OUT" in *git\ repository*) ok ;; *) bad "outside-repo run must name the git-repo requirement, got: $OUT" ;; esac

# --- refusal: claude not on PATH ---------------------------------------------
NOTMP=$(mktemp -d)
git -C "$NOTMP" init -q
# /usr/bin:/bin has git and coreutils but no claude on macOS and CI runners.
RC=0; OUT=$(cd "$NOTMP" && PATH=/usr/bin:/bin "$SUBJECT" 7 2>&1) || RC=$?
[ "$RC" -eq 1 ] || bad "claude-less run should exit 1, got $RC"
case "$OUT" in *claude*) ok ;; *) bad "claude-less run must name claude/PATH, got: $OUT" ;; esac
rm -rf "$TMP" "$NOTMP"

# --- happy paths against a stubbed claude, invoked from a repo subdir --------
BIN=$(mktemp -d)
CAP_ARGS="$BIN/args.txt"
CAP_STDIN="$BIN/stdin.txt"
CAP_CWD="$BIN/cwd.txt"
cat >"$BIN/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CLAUDE_ARGS"
cat > "$CLAUDE_STDIN"
pwd > "$CLAUDE_CWD"
echo "STUB-REVIEW-MARKER"
STUB
chmod +x "$BIN/claude"
run_stub() { # <pr> [context...] -> captures stdout/stderr, sets RC
  STDOUT=$(cd "$HERE" && CLAUDE_ARGS="$CAP_ARGS" CLAUDE_STDIN="$CAP_STDIN" CLAUDE_CWD="$CAP_CWD" \
    PATH="$BIN:$PATH" "$SUBJECT" "$@" 2>"$BIN/err.txt") && RC=0 || RC=$?
}

# With round context: argv pinned set-wise (12 tokens: -p, --max-turns, 30,
# --allowedTools + 8 allowlist entries — order-free so cosmetic reorders pass,
# additions/removals/typos fail).
run_stub 42 "round 1: fresh review" "round 2: verify fixes"
[ "$RC" -eq 0 ] || { cat "$BIN/err.txt"; bad "stubbed happy path should exit 0, got $RC"; }
ok
[ "$STDOUT" = "STUB-REVIEW-MARKER" ] || bad "script stdout must be exactly the review (stub sentinel), got: $STDOUT"
ok
[ -s "$BIN/err.txt" ] && bad "happy path must print nothing to stderr: $(cat "$BIN/err.txt")" || ok
LINES=$(wc -l <"$CAP_ARGS" | tr -d ' ')
[ "$LINES" -eq 12 ] || bad "claude argv should have 12 tokens, got $LINES: $(cat "$CAP_ARGS")"
ok
for token in '-p' '--max-turns' '30' '--allowedTools' 'Read' 'Grep' 'Glob' \
  'Bash(gh pr diff *)' 'Bash(gh pr view *)' 'Bash(gh issue view *)' \
  'Bash(git log *)' 'Bash(git show *)'; do
  grep -qxF -e "$token" "$CAP_ARGS" || bad "claude argv missing token: $token (got: $(cat "$CAP_ARGS"))"
  ok
done
# Prompt assembly is pinned byte-exact — deliberate format changes update this
# expectation together with the script (check-gate-query philosophy).
{
  echo "Review pull request #42 of this repository."
  echo
  cat "$PROMPT_FILE"
  echo
  echo "## Round context"
  echo "- round 1: fresh review"
  echo "- round 2: verify fixes"
} >"$BIN/expected-with-context.txt"
cmp -s "$BIN/expected-with-context.txt" "$CAP_STDIN" ||
  bad "assembled prompt mismatch (with context): $(diff "$BIN/expected-with-context.txt" "$CAP_STDIN" | head -20)"
ok
[ "$(cat "$CAP_CWD")" = "$REPO" ] || bad "agent workspace must be repo toplevel $REPO, got $(cat "$CAP_CWD")"
ok

# Without round context: no Round-context section at all.
run_stub 7
[ "$RC" -eq 0 ] || bad "stubbed no-context run should exit 0, got $RC"
ok
{
  echo "Review pull request #7 of this repository."
  echo
  cat "$PROMPT_FILE"
} >"$BIN/expected-bare.txt"
cmp -s "$BIN/expected-bare.txt" "$CAP_STDIN" ||
  bad "assembled prompt mismatch (no context): $(diff "$BIN/expected-bare.txt" "$CAP_STDIN" | head -20)"
ok

rm -rf "$BIN"
echo "check-ai-review: $N assertions pass (refusals, allowlist, assembly, stdout)"
