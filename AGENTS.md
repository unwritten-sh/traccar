# AGENTS.md

## What this is

Traccar server: an open source GPS tracking server in Java 21 that decodes 200+ device protocols, stores positions in an SQL database and exposes a REST/WebSocket API for the Traccar web and mobile apps. Gradle builds it; the `Makefile` is a thin wrapper that gives one entry point and picks a JDK 21+.

## Commands

| Task | Command |
| --- | --- |
| List targets | `make help` |
| Setup (git hooks + build) | `make setup` |
| Run locally (H2, port 8082) | `make dev` |
| Fast gate (Checkstyle + unit tests, ~30 s) | `make check-fast` |
| Full gate (same as CI: `./gradlew build`) | `make check` |
| All unit tests | `make test` |
| One test class | `make test TESTS=org.traccar.protocol.Gt06ProtocolDecoderTest` |
| Lint only | `make lint` |
| Optional PostgreSQL/MySQL | `make db-up` / `make db-down` |
| Clean (also deletes the local H2 database) | `make clean` |

Every Gradle run needs Maven Central until the cache is warm (`build.gradle` resolves versions at configuration time).

## Layout

| Path | What lives there |
| --- | --- |
| `src/main/java/org/traccar/` | Server code. `Main.java` starts Guice and the services. |
| `.../protocol/` | ~680 files: `*Protocol`, `*FrameDecoder`, `*ProtocolDecoder`, `*ProtocolEncoder` per device protocol. |
| `.../config/` | `Keys.java` (every config key, documented), `ProtocolConfig.java` (protocol list and ports), `Config.java`. |
| `.../handler/`, `.../handler/events/` | Position processing chain and event detection. |
| `.../api/`, `.../web/` | Jersey REST resources, security, WebSocket, Jetty server, MCP endpoint. |
| `.../storage/`, `.../model/` | SQL storage, query builder, model classes mapped to `tc_*` tables. |
| `.../notification/`, `.../notificators/`, `.../forward/`, `.../reports/`, `.../schedule/` | Notifications, forwarders, reports, scheduled tasks. |
| `.../helper/` | Shared parsing helpers (`Parser`, `PatternBuilder`, `BitUtil`, `Checksum`, `UnitsConverter`). |
| `src/test/java/org/traccar/` | JUnit 6 + Mockito tests, mirroring the main packages. `ProtocolTest`, `BaseTest` helpers. |
| `schema/` | Liquibase changelogs, entry `changelog-master.xml`. |
| `templates/` | Velocity notification templates and jxls report templates. |
| `openapi.yaml` | REST API description. |
| `debug.xml` | Local config used by `make dev`. `setup/traccar.xml` is the packaged default. |
| `setup/`, `docker/` | Installers, systemd unit, Dockerfiles, example compose stacks. |
| `tools/` | Python/shell scripts that talk to a running server (`test-integration.py`, `hex.sh`); `tools/harness/` gate helpers. |
| `traccar-web/` | Git submodule for the web UI, empty in a plain checkout. |

## Conventions that matter

- Checkstyle (`gradle/checkstyle.xml`) fails the build on any violation. 4 spaces, 120 columns, single-class imports (`.editorconfig`). Apache license header on new Java files.
- One protocol = `<Name>Protocol` + decoder (+ frame decoder, encoder) in `protocol/`, registered with a port in `config/ProtocolConfig.java`, tested by `<Name>ProtocolDecoderTest` with real device messages.
- Schema changes go into a new Liquibase changeset in `schema/`, never into a released changelog. They must work on H2, MySQL, MariaDB, PostgreSQL and SQL Server.
- New configuration keys go into `config/Keys.java` with a Javadoc comment (it is the user documentation).
- REST changes are reflected in `openapi.yaml`.
- Commit subject: short, imperative, capitalised, no prefix; `(#PR)` or `(fix #issue)` at the end. See [CONTRIBUTING.md](CONTRIBUTING.md).

## How to verify a change

1. Run the test you touched: `make test TESTS=<fully.qualified.TestClass>`.
2. Run `make check-fast` before you say a change is done. It must pass.
3. Run `make check` before you open a pull request. CI runs `./gradlew build` and `npx -y uw-harness verify`.
4. For runtime behaviour, `make dev` and `curl localhost:8082/api/health` (prints `OK`).
5. After each significant change, add an entry to [docs/harness/log.md](docs/harness/log.md): date, what changed, what you learned, what is left.

## What never to do

- Never push to `master` or merge your own pull request. Open a pull request for human review.
- Never edit a released `schema/changelog-*.xml`.
- Never delete or `@Disabled` a failing test to get a green gate, and never add Checkstyle suppressions. Report the problem instead.
- Never invent device sample messages for decoder tests. Use real ones from the issue or device documentation.
- Never commit `.env`, local databases (`target/`) or credentials.
- Do not change `release.yml`, `setup/` or `docker/` without a maintainer asking for it.

## Where to find more

- [docs/architecture.md](docs/architecture.md): components, diagram, tables.
- [docs/product.md](docs/product.md): users, use cases with code entry points, glossary.
- [docs/local-dev.md](docs/local-dev.md): prerequisites, first run, debugging, common problems.
- [docs/deploy.md](docs/deploy.md): release workflow and artifacts (open questions inside).
- [docs/observability.md](docs/observability.md): logs, `/api/health`, statistics (open questions inside).
- [docs/decisions/](docs/decisions/0001-record-architecture-decisions.md): architecture decision records.
- [CONTRIBUTING.md](CONTRIBUTING.md): branches, commits, definition of done.
- Skills in `.agents/skills/` (also `.claude/skills/`): `implement-change`, `add-protocol-decoder`, `debug-local`, `add-schema-change`, `release`.
