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

## Development

Monorepo with two apps scaffolded side by side:

- `backend/` — Spring Boot 3.5 (Java 17, Maven via wrapper — no local Maven install needed)
- `frontend/` — Flutter (Dart SDK ≥ 3.9), platforms: Android, iOS, web, macOS

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| JDK | 17 or newer | The only backend requirement — the Maven wrapper downloads Maven itself. Older JDKs fail the build with an explicit enforcer message. |
| Flutter SDK | stable (≥ 3.41) | **Run `flutter doctor` first** and fix anything red before continuing. Dart constraint is enforced by `frontend/pubspec.yaml`. |
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` | **Required.** The team's pub host; `frontend/pubspec.lock` is resolved against it. Without it, `pub get` rewrites every lockfile entry. Set it in your shell profile. |
| git, GNU make | any recent | |

### First-time setup

```bash
git clone <this-repo>
cd ai-sdlc-pilot
export PUB_HOSTED_URL=https://pub.flutter-io.cn   # add to your shell profile
make bootstrap   # backend deps (via wrapper) + frontend packages + git hooks
```

`make bootstrap` and `make lint` fail fast with instructions if `PUB_HOSTED_URL`
doesn't match the host the lockfile is resolved against.

### Running the backend

```bash
cd backend
./mvnw spring-boot:run
```

Verify it's up:

```bash
curl http://localhost:8080/actuator/health
# {"status":"UP"}
```

**Port 8080 already in use?** Override it (also useful to run two instances):

```bash
SERVER_PORT=8081 ./mvnw spring-boot:run
curl http://localhost:8081/actuator/health
```

### Running the frontend

The placeholder screen calls the backend health endpoint and shows the result —
this proves both sides are wired together.

```bash
cd frontend
flutter run    # pick a device; needs the backend running first
```

On the **Android emulator**, `localhost` is not your machine — point the app at the host:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

(On iOS simulator, macOS, and Chrome, the default `http://localhost:8080` works.)

### Everyday commands

```bash
make lint            # backend compile + flutter analyze
make test            # backend tests + flutter tests
make test-coverage   # both, with coverage (backend JaCoCo / frontend lcov)
```

Run these before pushing — CI runs the same.

### Troubleshooting

- **"requires Java 17 or newer"** during backend build — that's the enforcer
  doing its job. Install JDK 17+ (`sdk install java 17-...`, `brew install --cask temurin@17`, …).
- **Backend fails to start with "Port 8080 was already in use"** — see the
  `SERVER_PORT` override above.
- **Flutter/Dart version errors** — check `flutter doctor`, upgrade Flutter
  (`flutter upgrade`), and confirm your Dart satisfies `environment.sdk` in
  `frontend/pubspec.yaml`.
- **First backend build is slow** — the wrapper downloads Maven and all
  dependencies on first run; versions are pinned, so subsequent builds are
  deterministic and offline-capable (via the local cache).

