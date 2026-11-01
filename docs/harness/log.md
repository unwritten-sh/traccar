# Implementation log

One entry per significant change: date, what changed, what was learned, what is left.

## Notes from the harness build

- Gates wrap Gradle through the `Makefile`: `make check-fast` runs the Gradle tasks checkstyleMain, checkstyleTest and test; `make check` runs build and test (see the `Makefile`). `--rerun` forces the test task to run so that the gate always prints a test count.
- Gradle prints no test summary by default. `tools/harness/test-summary.gradle` is an init script (`-I`) that prints `Tests run: N, Failures: F, Errors: 0, Skipped: S` without changing `build.gradle`.
- `tools/harness/java-home.sh` picks a JDK 21+ because some machines have an older default `java`. The harness build machine had only JDK 17 (default) and Homebrew JDK 25; gates passed on JDK 25. CI uses Temurin 21.
- First run on 2026-11-01: 612 tests, 0 failures, 27 skipped. All skips come from `@Disabled` annotations already in the code (9 files); no test was disabled by the harness build.
- `make dev` runs the server API-only when the `traccar-web` submodule is empty, because `debug.xml` points `web.path` to `./traccar-web/simple` and the server stops at startup when that folder is missing.
- Not in any gate: `tools/test-integration.py` and the other Python scripts in `tools/` (they need a running server), and tests against MySQL, PostgreSQL or SQL Server (unit tests use H2 or memory only).
- Every Gradle run needs Maven Central, even offline-looking ones: `build.gradle` resolves Jersey transitive versions at configuration time. The fast gate is offline only once the Gradle cache is warm.

## 2026-11-01: harness built by uw-harness 0.3.0 with claude

Score 30 → 92, level 0 → 2.

I added a thin Makefile over Gradle. It gives one entry point (setup, dev, test, lint, check-fast, check), picks a JDK 21+ by itself, and prints a test count through a Gradle init script, so build.gradle is unchanged. From a clean shell, make setup, make check-fast and make check all pass: 612 tests, 0 failures, 27 skipped by @Disabled annotations that were already in the code. CI keeps ./gradlew build and now also runs npx -y uw-harness verify. A pre-push hook runs the fast gate. The local env is make dev (H2, API-only when the traccar-web submodule is empty), with an optional compose.yaml for PostgreSQL and MySQL and a .env.example. I wrote docs (architecture, product, three ADRs, CONTRIBUTING, deploy, observability, local-dev), five skills and an 80-line AGENTS.md. Seven questions for a human remain as TODO blocks (deploy, rollback, production monitoring, PR rule, protocol definition of done, Java 21 vs 25, web submodule).

**Assessment.** Open source GPS tracking server in Java that decodes 200+ device protocols, stores positions in an SQL database and exposes a REST/WebSocket API for the Traccar web and mobile apps. Stack: Java 21 (build target; release builds use JDK 25), Python 3 (tools/ scripts for integration and performance testing), Shell, Gradle 9.8.2 (wrapper), Netty 4.2 (device networking), Jetty 12.1 + Jersey 4 (HTTP, REST, WebSocket), Guice 7 (dependency injection), Jackson, Liquibase 5 (schema migrations, schema/changelog-*.xml), HikariCP, jxls / Apache POI and Velocity (reports and notification templates), JUnit Jupiter 6 + Mockito 5, Checkstyle 14.4 (gradle/checkstyle.xml), Protocol Buffers. The full assessment stays in `.git/uw-harness/assessment.md` on the machine that ran uw-harness.

Risks seen before the harness:

- build.gradle resolves Jersey transitive versions at configuration time (resolveTransitiveVersion), so every Gradle invocation, even listing tasks, needs network access to Maven Central.
- ./gradlew test runs about 426 test classes; it may take minutes, which is slow for a 'fast' gate and a pre-push hook.
- Checkstyle is part of ./gradlew check and build: any style violation fails CI, so agents must follow gradle/checkstyle.xml.
- The traccar-web submodule uses a relative URL (../traccar-web.git) and is empty here; cloning it fails outside GitHub and the web UI will not load locally.
- Java version mismatch: CI builds on Java 21 while release and Docker images use JDK 25.

**Before the harness**: `./gradlew test`, ran no test (exit 1).

**Gates verified by the CLI**

- pass: `make setup`
- pass: `make check-fast` (612 tests, 27 skipped)
- pass: `make check` (612 tests, 27 skipped)

**Dependency and new files to review**

- A `tools/harness/java-home.sh`: new file outside the usual harness paths
- A `tools/harness/test-summary.gradle`: new file outside the usual harness paths

**Test files that only compare literals** (they protect nothing)

- `src/test/java/org/traccar/forward/PositionForwarderUrlTest.java`
- `src/test/java/org/traccar/handler/events/IgnitionEventHandlerTest.java`
- `src/test/java/org/traccar/helper/LogTest.java`
- `src/test/java/org/traccar/protocol/IotmProtocolEncoderTest.java`

**Secret-looking values already in the repository**

- `src/main/java/org/traccar/model/Command.java` (password or secret)

**First task to try with the harness:** Add unit tests for HealthResource. GET /api/health (src/main/java/org/traccar/api/resource/HealthResource.java) is what systemd and the Docker healthchecks use to restart Traccar, but it has no test. Add HealthResourceTest covering the database check and the web.healthCheck.dropThreshold message-ratio logic, using Mockito for Config, StatisticsManager and Storage.

- Done when: src/test/java/org/traccar/api/resource/HealthResourceTest.java exists and runs with make test TESTS=org.traccar.api.resource.HealthResourceTest
- Done when: Tests cover: 200 OK when storage answers, 500 when storage throws StorageException, 500 when stored messages drop below the configured threshold, 200 when no threshold is set
- Done when: No change to HealthResource.java, or a minimal change justified in the PR description
- Done when: make check-fast passes

**Changed files**

- `Makefile` (task-runner): Thin wrapper over Gradle with help (default), setup, hooks, dev, build, test (TESTS= filter), lint, check-fast, check, db-up, db-down, clean. It picks a JDK 21+ through tools/harness/java-home.sh.
- `tools/harness/java-home.sh` (fast-gate): Finds a JDK 21 or newer (JAVA_HOME, PATH, macOS java_home, Homebrew, SDKMAN, /usr/lib/jvm) so the gates work on machines where the default java is older.
- `tools/harness/test-summary.gradle` (fast-gate): Gradle init script (-I) that prints failed tests with full traces and a Surefire-style 'Tests run: N, Failures: F, Errors: 0, Skipped: S' line. build.gradle is not changed.
- `.githooks/pre-push` (hooks): Pre-push hook that runs make check-fast. make setup installs it with git config core.hooksPath .githooks.
- `.github/workflows/gradle.yml` (ci): Keeps ./gradlew build and adds setup-node 20 plus npx -y uw-harness verify on push and pull_request to master.
- `compose.yaml` (local-env): Optional PostgreSQL 17 and MySQL LTS services for testing schema and queries on other databases. H2 needs nothing.
- `.env.example` (env-example): Documents CONFIG_USE_ENVIRONMENT_VARIABLES, the key-to-variable mapping of Config.java and the DATABASE_* settings for H2, PostgreSQL and MySQL.
- `.java-version` (toolchain-pinned): Pins Java 21, the version CI uses.
- `.gitignore` (env-example): Ignores .env and logs/.
- `docs/local-dev.md` (local-env): Prerequisites, first run, daily run, other databases, reset, debugging (H2 console, hex.sh, test-integration.py, JDWP), common problems. Includes the submodule and Java version TODOs.
- `docs/architecture.md` (architecture): Mermaid diagram plus one section per component, with folders, tc_* tables, Liquibase entry point and what is not visible in the repository.
- `docs/product.md` (product): Value proposition, user roles, use cases with code entry points, glossary.
- `docs/decisions/0001-record-architecture-decisions.md` (decisions): ADR format and rules.
- `docs/decisions/0002-one-netty-decoder-per-protocol.md` (decisions): Inferred decision: one Netty pipeline, decoder and test per protocol, each on its own port.
- `docs/decisions/0003-liquibase-schema-for-several-databases.md` (decisions): Inferred decision: Liquibase changelogs run at startup for one schema across H2, MySQL, MariaDB, PostgreSQL and SQL Server.
- `CONTRIBUTING.md` (agreements): Branches, squash-merge and commit style seen in history (marked inferred), code style, protocol and schema rules, definition of done with make check-fast. Two TODOs.
- `docs/deploy.md` (deploy-explicit): Environments, how release.yml builds, tests and publishes installers and Docker images, rollback notes, post-release checks. Two TODOs.
- `docs/observability.md` (observability): Logging keys and format, /api/health semantics, systemd watchdog, statistics API, no error reporter, how to tell something is wrong. One TODO for production.
- `docs/harness/log.md` (implementation-log): 'Notes from the harness build' section: how the gates work, JDK detection, test counts (612 run, 27 skipped by existing @Disabled), what is left out of the gates.
- `.agents/skills/implement-change/SKILL.md` (skills): From task to verified change using make test TESTS=..., make check-fast, make check.
- `.agents/skills/add-protocol-decoder/SKILL.md` (skills): Add or change a protocol: real samples, ProtocolTest verifyDecode API, ProtocolConfig registration, hex.sh end-to-end check.
- `.agents/skills/debug-local/SKILL.md` (skills): Reproduce in a decoder test or a local server, first admin user, send data, logs, H2 console, breakpoints, reset.
- `.agents/skills/add-schema-change/SKILL.md` (skills): New Liquibase changeset, model update, test on H2 then PostgreSQL and MySQL from compose.yaml.
- `.agents/skills/release/SKILL.md` (skills): Release steps visible in the repository (version bump, Build Release workflow), with the open deploy questions pointed to docs/deploy.md.
- `.claude/skills` (skills): Relative symlink to ../.agents/skills.
- `AGENTS.md` (agents-file): 80-line index: what this is, commands, layout, conventions, how to verify (make check-fast, log entry), what never to do, links to docs and skills.
- `CLAUDE.md` (agents-file): Symlink to AGENTS.md.

**Open questions for a human**

- How is the managed hosting (traccar.org pricing) and the demo server deployed and updated: from the Docker images, installers, or another pipeline outside this repository? (in `docs/deploy.md`)
- Who is allowed to run the 'Build Release' workflow, and how is a bad release rolled back (re-tag, previous Docker tag, schema rollback)? (in `docs/deploy.md`)
- For the managed service, where are logs, metrics and alerts kept, and which signal tells you production is broken (only /api/health, or something else)? (in `docs/observability.md`)
- Should outside contributors and agents always open a pull request, while maintainers keep committing directly to master as the history shows? (in `CONTRIBUTING.md`)
- What is the definition of done for a protocol change: is a decoder test with a real device sample always required, and must tools/test-integration.py also pass? (in `CONTRIBUTING.md`)
- Which Java version should developers use: 21 (CI and build.gradle) or 25 (release builds and Docker images)? .java-version says 21 for now. (in `docs/local-dev.md`)
- Should local development check out the traccar-web submodule (relative URL ../traccar-web.git), or is the backend usually run without the web UI? (in `docs/local-dev.md`)

**Left undone**

- env-example: uw-harness detect flags src/main/java/org/traccar/model/Command.java:78 (KEY_DEVICE_PASSWORD = "devicePassword") as a secret-looking value. It is an attribute name, not a secret. I left the product code unchanged, so env-example stays partial until the scanner is tuned or a human accepts it.
- full-gate: Not in any gate: tools/test-integration.py and the other Python tools (they need a running server), and tests on MySQL, PostgreSQL or SQL Server (unit tests use H2 or memory only). Recorded in docs/harness/log.md.
- local-env: debug.xml points web.path to ./traccar-web/simple, and the server stops at startup when that folder is missing (the submodule is empty in this checkout). make dev works around it with an API-only run (CONFIG_USE_ENVIRONMENT_VARIABLES=true, WEB_PATH=./target/web). The web UI cannot be served locally until the submodule question is answered.
- fast-gate: This machine has only JDK 17 (default) and Homebrew JDK 25. The gates were verified on JDK 25 through tools/harness/java-home.sh. CI uses Temurin 21. Every Gradle run also needs Maven Central, because build.gradle resolves versions at configuration time.

## 2026-11-01: unit tests for HealthResource

Added `src/test/java/org/traccar/api/resource/HealthResourceTest.java` (5 tests) for `GET /api/health`: 200 when storage answers, 500 when storage throws `StorageException`, 500 when the stored message count drops below `web.healthCheck.dropThreshold`, 200 when it stays above, 200 when no threshold is set. `HealthResource.java` is unchanged. `make check-fast` passes with 617 tests (612 + 5), 0 failures, 27 skipped (the same `@Disabled` tests as before).

Learned:

- `HealthResource` keeps its message counters in static fields, so the test resets them with reflection before each test. The first call after a reset never runs the ratio check (no previous interval), so the threshold tests call `health()` twice.
- `HealthResource` declares its own `storage` field that hides `BaseResource.storage`. Mockito `@InjectMocks` would be ambiguous here, so the test sets the private fields of `HealthResource` with reflection. There is no `mockito-junit-jupiter` dependency and no existing REST resource test to copy from.
- Checkstyle import order is third-party (`org.*`), then `java`/`javax`/`jakarta`, then static imports. AGENTS.md says only "single-class imports"; the order is in `gradle/checkstyle.xml` (`CustomImportOrder`).

Left: no test covers the full Jersey stack (`@PermitAll`, path, media type) for `/api/health`; `make dev` plus `curl localhost:8082/api/health` is the manual check.

## 2026-11-01: pilot task done with the harness by claude

**Task:** Add unit tests for HealthResource. GET /api/health (src/main/java/org/traccar/api/resource/HealthResource.java) is what systemd and the Docker healthchecks use to restart Traccar, but it has no test. Add HealthResourceTest covering the database check and the web.healthCheck.dropThreshold message-ratio logic, using Mockito for Config, StatisticsManager and Storage.

I added HealthResourceTest with 5 Mockito-based tests for GET /api/health. They cover the database check (200 when storage answers, 500 on StorageException) and the web.healthCheck.dropThreshold ratio logic (500 below the threshold, 200 above it, 200 when no threshold is set). HealthResource.java is unchanged. The test resets the static message counters and injects the private fields with reflection, because HealthResource.storage hides BaseResource.storage and no @InjectMocks or mockito-junit-jupiter setup exists in the repo. make check-fast passes with 617 tests (612 + 5), 0 failures and the same 27 skipped as before.

- Status reported by the agent: done. Acceptance criteria met: 4 of 4.
- Gates after the task: pass. Tests before: 612 tests, 27 skipped. After: 617 tests, 27 skipped.
- Fix rounds after a gate failed: 0. Questions for a human: 0. Unattended: yes.
- Harness gap: `AGENTS.md`: Conventions mention only 'single-class imports'. The import order that Checkstyle enforces (third-party org.*, then java/javax/jakarta, then static, alphabetical, with one blank line between groups) is not documented, so my first check-fast failed with 10 CustomImportOrder errors. Note that main code puts jakarta after org.* with a blank line, which is easy to copy wrongly into a test.
- Harness gap: `AGENTS.md`: Layout says tests mirror main packages and points to BaseTest, but there is no src/test/java/org/traccar/api package and no example of testing a Jersey resource. A short note on how to unit-test a resource (private @Inject fields, no mockito-junit-jupiter, BaseResource.storage hidden by subclass fields) would save searching.
- Harness gap: `.agents/skills/implement-change/SKILL.md`: make check-fast output on Checkstyle failure prints only 'violations by severity: [error:10]'; the skill could say the details are in build/reports/checkstyle/test.xml (or main.xml).
