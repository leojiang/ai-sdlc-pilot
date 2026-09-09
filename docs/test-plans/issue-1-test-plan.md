# Test Plan — Issue #1: Bootstrap codebase (Spring Boot + Flutter scaffold)

**Story:** #1 — Bootstrap codebase: Spring Boot backend + Flutter frontend scaffold
**Status:** ai-draft — needs human review before implementation starts.
**Assumptions this plan is written against** (from open questions, to be confirmed at refinement):
Maven (`./mvnw`), Java 17, Spring Boot 3.x, monorepo. Current CI pins Temurin 17 and the
Makefile assumes Maven, so these are the de-facto defaults. If refinement picks Gradle or
Java 21, only the build-command cells below change — the test set stays the same.

## Objective

Prove the scaffold delivers its core promise: **anyone can fresh-clone this repo and build
and run both apps with only the standard SDKs installed** — with the two sides actually
wired together (health endpoint consumed by the frontend). The deepest risk in a scaffold
story is that it only works on the author's machine; this plan therefore weights
clean-environment builds over local verification.

## Traceability table

| # | Acceptance criterion (from #1) | Planned test(s) | Layer | Runs where |
|---|---|---|---|---|
| AC1 | Fresh clone shows `backend/` + `frontend/`, no build artifacts committed, `.gitignore` covers `target/`, `build/`, `.gradle/`, `.dart_tool/`, IDE folders | 1. CI script: `git ls-files` returns nothing under `target/`, `build/`, `.gradle/`, `.dart_tool/`, `.idea/`, `.vscode/`, `*.iml`.<br>2. Repo-hygiene step after CI build: `git status --porcelain` is empty post-build (= edge case 5). | Integration (repo-level) | CI, every PR |
| AC2 | Wrapper build (`./mvnw verify`) on a JDK-only machine downloads the build tool, compiles, default tests pass | Clean-clone CI build: checkout → `make bootstrap` → `make test` (and one explicit `backend/mvnw verify` step — see note below). Runner has no project-local cache, exercising the wrapper-download path. | Integration | CI `test` job |
| AC3 | `GET /actuator/health` → HTTP 200 `{"status":"UP"}` | `@SpringBootTest(webEnvironment = RANDOM_PORT)` test asserting status code **and** body `status == UP` via TestRestTemplate. This is the cross-side contract — see risk P0-1. | Integration | CI `test` job |
| AC4 | `flutter analyze` and `flutter test` pass in `frontend/` | 1. `flutter analyze` in CI `lint` job (via `make lint`).<br>2. At least one meaningful widget test: the placeholder smoke screen renders and shows the health result using a faked HTTP client (also covers the static half of AC5). | Unit (widget) + static analysis | CI `lint` + `test` jobs |
| AC5 | `flutter run` on ≥1 platform shows a placeholder screen that calls the backend health endpoint and displays the result | Widget test with mocked HTTP (automated half, see AC4-2) **plus** a manual smoke run: start backend → `flutter run` on the agreed platform → observe "UP" rendered. Screenshot attached to the PR. | E2E (manual smoke) | Local, by implementer + reviewer |
| AC6 | README setup steps suffice for a new developer, unaided | Manual walkthrough on a clean-ish environment following the README verbatim (fresh clone, emptied caches where feasible). CI clean-clone build (AC2) approximates the automated portion. | Manual | Local, pre-merge |

**Note for implementers (tooling gap):** AC2 names the *wrapper* (`./mvnw verify`) but the
current `Makefile` invokes system `mvn`. Recommend the story switches Makefile commands to
`./mvnw` (one-line change) so CI exercises the exact path the AC promises. Otherwise the
wrapper is never tested by CI.

## Risk-based priority

Which failures would hurt most? Test those hardest.

- **P0-1 — Health contract breaks the wire-up (AC3/AC5).** Everything downstream depends on
  `200 + {"status":"UP"}`. A typo'd actuator exposure config compiles fine and fails only at
  runtime. The `RANDOM_PORT` integration test must assert body, not just status code, and the
  frontend smoke test must parse the same shape.
- **P0-2 — Scaffold only builds on the author's machine (AC2, edge 4).** Local `~/.m2` /
  Gradle caches mask wrapper and pinning problems. The clean-clone CI build is the primary
  defense; versions must be pinned (wrapper properties, Spring Boot BOM, Flutter/Dart SDK
  constraint) so once cached, builds are deterministic.
- **P0-3 — Committed artifacts pollute every future clone (AC1, edge 5).** Cheap to check,
  expensive to retro-fix (history rewrite). Automate the `git ls-files` + post-build
  `git status --porcelain` checks on every PR.
- **P1 — Flutter side drifts (AC4).** `flutter analyze`/`flutter test` green is the minimum
  bar; catch config rot early. CI currently has no explicit Flutter setup step — see
  Environments below.
- **P1 — Cryptic failures for newcomers (edge 1/2/3).** Fail-fast messages (JDK version,
  port-in-use, SDK constraint) are README-promise material; verified manually once, spot-fixed
  if unclear.
- **P2 — README wording gaps (AC6).** Hurts onboarding, caught by one careful walkthrough.

## Negative and boundary cases

| # | Case | Expected behavior | Layer / runs where |
|---|---|---|---|
| N1 | JDK below minimum (e.g. 11) → `./mvnw verify` | Build **fails fast** with a clear toolchain message (enforcer rule or equivalent) — not a cryptic compile error. Verify once manually; enforcer config reviewed in PR. | Manual (one-off) |
| N2 | Port 8080 already in use → start backend | Legible startup failure (Spring's standard port-in-use error is acceptable); `SERVER_PORT=8081 ./mvnw spring-boot:run` works and README documents the override. Re-run health check against 8081. | Manual (one-off) |
| N3 | Flutter/Dart SDK below `pubspec.yaml` constraint → `flutter analyze` / `pub get` | Explicit version-mismatch message from the Dart toolchain; README lists `flutter doctor` as step 1. | Manual (one-off) |
| N4 | No system Maven/Gradle installed (JDK only) | Wrapper downloads the build tool itself; build succeeds. Clean CI runner approximates this; a truly bare check (e.g. container without maven) is nice-to-have. | CI (approximation) |
| N5 | Fresh clone, empty `~/.m2` (first build, slow link) | Wrapper fetches pinned tool + deps and build completes repeatably. Covered by clean-clone CI; determinism by inspection of pinned versions. | CI |
| N6 | Full local builds of both apps, then `git status` | Working tree clean (gitignore completeness). | CI (post-build step) |
| N7 | Backend not running when the Flutter app starts (beyond explicit ACs — implement only if cheap) | Placeholder shows an error state, does not crash or hang silently. | Unit (widget test) — optional |

## Test data & environments

- **Test data:** none beyond scaffold defaults — the health JSON is the only "data". Backend
  tests use `RANDOM_PORT`; no fixtures needed.
- **Environments:**
  - CI (ubuntu-latest, Temurin 17) — already running `make lint` / `make bootstrap` /
    `make test` on PRs. Two gaps this story should close:
    1. **Flutter setup is not declared in CI.** If the runner image's preinstalled Flutter is
       relied upon, it is unpinned (violates the determinism goal, edge 4). Recommend adding a
       pinned flutter-setup action, or documenting the pin decision.
    2. **Coverage artifact paths** (`backend/target/site/jacoco/`, `frontend/coverage/`)
       imply JaCoCo configured in the backend POM and `flutter test --coverage` working —
       include JaCoCo in the scaffold so `make test-coverage` functions.
  - Local dev (implementer + reviewer): JDK 17, Flutter stable, one target platform for the
    manual smoke run (per open question 5).
  - Clean-machine README walkthrough (AC6) — best effort: fresh clone + emptied tool caches.

## Manual vs automated summary

| Automated (CI) | Manual |
|---|---|
| Wrapper build + unit/integration tests (AC2, AC3) | `flutter run` smoke on chosen platform + PR screenshot (AC5) |
| `flutter analyze` + widget tests incl. mocked-health smoke (AC4) | README walkthrough on clean environment (AC6) |
| Repo hygiene: no committed artifacts + clean post-build `git status` (AC1, N6) | Negative checks N1–N3 (one-off each, before merge) |
| Clean-clone repeatability (N4, N5) | |

## Sign-off

(Historical note — this section described the original convention, retired with #30:
a plan is now reviewed as part of card review, and implementation starts via
`/start-coding` once the card is promoted to Ready. #1 itself was approved under the
old comment ritual before it was retired.)
