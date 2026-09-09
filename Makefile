.PHONY: bootstrap lint test test-coverage

# Backend builds go through the Maven wrapper (story #1 AC2) — no local Maven
# install required, only a JDK 17+.

# frontend/pubspec.lock records the pub host it was resolved against in every
# entry; pub rewrites the whole lockfile when the local host differs. Fail fast
# on any mismatch — in either direction — instead of a silently dirty tree.
.PHONY: check-pub-host
check-pub-host:
	@if [ -f frontend/pubspec.lock ]; then \
	  LOCKED=$$(awk '/^ *url:/ {u=$$0} /^ *source: hosted/ {sub(/^ *url: "/,"",u); sub(/"$$/,"",u); print u; exit}' frontend/pubspec.lock); \
	  EFFECTIVE="$${PUB_HOSTED_URL:-https://pub.dev}"; \
	  if [ -n "$$LOCKED" ] && [ "$$EFFECTIVE" != "$$LOCKED" ]; then \
	    echo "ERROR: frontend/pubspec.lock is resolved against $$LOCKED but the local"; \
	    echo "pub host is $$EFFECTIVE — pub get would rewrite the lockfile."; \
	    echo "Fix: export PUB_HOSTED_URL=$$LOCKED  (see README, Prerequisites)"; \
	    exit 1; \
	  fi; \
	fi

bootstrap:
	@$(MAKE) --no-print-directory check-pub-host
	@if [ -d backend ]; then cd backend && ./mvnw -q -DskipTests dependency:go-offline compile; fi
	@if [ -d frontend ]; then cd frontend && flutter pub get; fi
	@command -v pre-commit >/dev/null && pre-commit install || true

# The board-gate GraphQL query is deliberately duplicated: start-coding.md runs it,
# story-status.md documents it as the read-only inspection. Hand-copying a ~300-char
# line drifted once (#30 review round 3: one extra closing brace — the command then
# could not execute its own gate). Fail on any drift so the copies can only change
# together, byte-identical.
.PHONY: check-gate-query
check-gate-query:
	@a=$$(grep '^   gh api graphql' .claude/commands/story-status.md | sed 's/^ *//'); \
	 b=$$(grep '^   gh api graphql' .claude/commands/start-coding.md | sed 's/^ *//'); \
	 if [ -z "$$a" ] || [ -z "$$b" ]; then \
	   echo "ERROR: check-gate-query could not find the gate query in both command files"; \
	   exit 1; \
	 fi; \
	 if [ "$$a" != "$$b" ]; then \
	   echo "ERROR: the board-gate query drifted between story-status.md and start-coding.md"; \
	   echo "       (#30 round 3 shipped an extra brace this way). Update both together."; \
	   exit 1; \
	 fi; \
	 echo "check-gate-query: gate query copies identical"

# scripts/ai-review.sh is the scripted half of /start-coding's AI-review
# convergence loop (#32) — its invocation must never drift (the ad-hoc
# hand-typed form did; see the story's context). Pin the refusal paths,
# prompt assembly, and read-only allowlist against a stubbed claude so
# lint/CI catch drift with no API call.
.PHONY: check-ai-review
check-ai-review:
	@scripts/ai-review.fixture.sh
	@grep -qF 'scripts/ai-review.sh <pr>' .claude/commands/start-coding.md || { \
	  echo "ERROR: /start-coding step 6 no longer invokes scripts/ai-review.sh —"; \
	  echo "       the loop and the script must change together (check-gate-query class)"; \
	  exit 1; }
	@echo "check-ai-review: /start-coding still wired to scripts/ai-review.sh"

lint:
	@$(MAKE) --no-print-directory check-gate-query
	@$(MAKE) --no-print-directory check-ai-review
	@if [ -d backend ]; then cd backend && ./mvnw -q -DskipTests compile; fi
	@if [ -d frontend ]; then $(MAKE) --no-print-directory check-pub-host && cd frontend && flutter pub get && flutter analyze; fi

test:
	@if [ -d backend ]; then cd backend && ./mvnw -q test; fi
	@if [ -d frontend ]; then $(MAKE) --no-print-directory check-pub-host && cd frontend && flutter test; fi

# Backend goes through the full verify lifecycle (compile, test, package) once
# and reports JaCoCo coverage from the same run — CI relies on this single
# pass instead of running test and verify separately.
test-coverage:
	@if [ -d backend ]; then $(MAKE) --no-print-directory check-pub-host && cd backend && ./mvnw -q verify jacoco:report; fi
	@if [ -d frontend ]; then $(MAKE) --no-print-directory check-pub-host && cd frontend && flutter test --coverage; fi
