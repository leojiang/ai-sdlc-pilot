.PHONY: bootstrap lint test test-coverage

# Backend builds go through the Maven wrapper (story #1 AC2) — no local Maven
# install required, only a JDK 17+.

# frontend/pubspec.lock is resolved against the team pub host (flutter-io.cn
# mirror); pub writes that host into every lock entry. Refuse to run pub get
# when the local PUB_HOSTED_URL doesn't match — otherwise the lockfile gets
# silently rewritten (dirty tree / failing CI hygiene check).
.PHONY: check-pub-host
check-pub-host:
	@if [ -f frontend/pubspec.lock ] && grep -q 'pub.flutter-io.cn' frontend/pubspec.lock \
	    && [ "$${PUB_HOSTED_URL:-}" != 'https://pub.flutter-io.cn' ]; then \
	  echo "ERROR: frontend/pubspec.lock is resolved against https://pub.flutter-io.cn but"; \
	  echo "PUB_HOSTED_URL is '$${PUB_HOSTED_URL:-<unset>}' — pub get would rewrite the lockfile."; \
	  echo "Fix: export PUB_HOSTED_URL=https://pub.flutter-io.cn  (see README, Prerequisites)"; \
	  exit 1; \
	fi

bootstrap:
	@if [ -d backend ]; then cd backend && ./mvnw -q -DskipTests dependency:go-offline compile; fi
	@if [ -d frontend ]; then $(MAKE) --no-print-directory check-pub-host && cd frontend && flutter pub get; fi
	@command -v pre-commit >/dev/null && pre-commit install || true

lint:
	@if [ -d backend ]; then cd backend && ./mvnw -q -DskipTests compile; fi
	@if [ -d frontend ]; then $(MAKE) --no-print-directory check-pub-host && cd frontend && flutter pub get && flutter analyze; fi

test:
	@if [ -d backend ]; then cd backend && ./mvnw -q test; fi
	@if [ -d frontend ]; then cd frontend && flutter test; fi

test-coverage:
	@if [ -d backend ]; then cd backend && ./mvnw -q test jacoco:report; fi
	@if [ -d frontend ]; then cd frontend && flutter test --coverage; fi
