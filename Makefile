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
	@if [ -d frontend ]; then $(MAKE) --no-print-directory check-pub-host && cd frontend && flutter pub get; fi
	@command -v pre-commit >/dev/null && pre-commit install || true

lint:
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
