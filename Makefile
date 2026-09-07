.PHONY: bootstrap lint test test-coverage

# Spring Boot build tool: mvn (default). If you prefer Gradle, swap the
# `mvn -q ...` calls for `./gradlew --quiet ...`.

bootstrap:
	@if [ -d backend ]; then cd backend && mvn -q -DskipTests dependency:go-offline compile; fi
	@if [ -d frontend ]; then cd frontend && flutter pub get; fi
	@command -v pre-commit >/dev/null && pre-commit install || true

lint:
	@if [ -d backend ]; then cd backend && mvn -q -DskipTests compile; fi
	@if [ -d frontend ]; then cd frontend && flutter analyze; fi

test:
	@if [ -d backend ]; then cd backend && mvn -q test; fi
	@if [ -d frontend ]; then cd frontend && flutter test; fi

test-coverage:
	@if [ -d backend ]; then cd backend && mvn -q test jacoco:report; fi
	@if [ -d frontend ]; then cd frontend && flutter test --coverage; fi
