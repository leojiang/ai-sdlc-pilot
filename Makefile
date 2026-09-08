.PHONY: bootstrap lint test test-coverage

# Backend builds go through the Maven wrapper (story #1 AC2) — no local Maven
# install required, only a JDK 17+.

bootstrap:
	@if [ -d backend ]; then cd backend && ./mvnw -q -DskipTests dependency:go-offline compile; fi
	@if [ -d frontend ]; then cd frontend && flutter pub get; fi
	@command -v pre-commit >/dev/null && pre-commit install || true

lint:
	@if [ -d backend ]; then cd backend && ./mvnw -q -DskipTests compile; fi
	@if [ -d frontend ]; then cd frontend && flutter pub get && flutter analyze; fi

test:
	@if [ -d backend ]; then cd backend && ./mvnw -q test; fi
	@if [ -d frontend ]; then cd frontend && flutter test; fi

test-coverage:
	@if [ -d backend ]; then cd backend && ./mvnw -q test jacoco:report; fi
	@if [ -d frontend ]; then cd frontend && flutter test --coverage; fi
