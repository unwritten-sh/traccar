# Harness brief: repo

Written by uw-harness 0.3.0 on 2026-11-01 with claude. One page for the people who decide what comes next. It is rewritten on every run: do not edit it by hand.

## What changed

Harness coverage went from 30 to 92 out of 100, level 0 to 2 (self-checking). The coverage score measures structure: the files exist with real content, the commands resolve, the gates ran tests. It does not measure how good the docs or the tests are.

## What was checked by running it

| Gate | Command | Result | Tests |
| --- | --- | --- | --- |
| fast | `make check-fast` | pass | 612 tests, 27 skipped |
| full | `make check` | pass | 612 tests, 27 skipped |

Before the harness, the project's tests could not be measured: `./gradlew test` ran no test (exit 1). This says nothing about whether the tests pass, and the gates could not be compared with a starting point.
4 test files only compare literals (for example `assert True`) and protect nothing: `src/test/java/org/traccar/forward/PositionForwarderUrlTest.java`, `src/test/java/org/traccar/handler/events/IgnitionEventHandlerTest.java`, `src/test/java/org/traccar/helper/LogTest.java`, `src/test/java/org/traccar/protocol/IotmProtocolEncoderTest.java`.

The test counts come from the output of the gates on the machine that ran uw-harness. They become proof when CI runs `npx uw-harness verify` on every pull request.

## What is left out or weaker

- env-example: uw-harness detect flags src/main/java/org/traccar/model/Command.java:78 (KEY_DEVICE_PASSWORD = "devicePassword") as a secret-looking value. It is an attribute name, not a secret. I left the product code unchanged, so env-example stays partial until the scanner is tuned or a human accepts it.
- full-gate: Not in any gate: tools/test-integration.py and the other Python tools (they need a running server), and tests on MySQL, PostgreSQL or SQL Server (unit tests use H2 or memory only). Recorded in docs/harness/log.md.
- local-env: debug.xml points web.path to ./traccar-web/simple, and the server stops at startup when that folder is missing (the submodule is empty in this checkout). make dev works around it with an API-only run (CONFIG_USE_ENVIRONMENT_VARIABLES=true, WEB_PATH=./target/web). The web UI cannot be served locally until the submodule question is answered.
- fast-gate: This machine has only JDK 17 (default) and Homebrew JDK 25. The gates were verified on JDK 25 through tools/harness/java-home.sh. CI uses Temurin 21. Every Gradle run also needs Maven Central, because build.gradle resolves versions at configuration time.

## Secret-looking values

1 file holds a value that looks like a secret. If they are real, a human must rotate them and remove them from the git history: `src/main/java/org/traccar/model/Command.java` (password or secret).

## Open questions

| Question | Who can answer | Where |
| --- | --- | --- |
| Should outside contributors and agents always open a pull request, while maintainers keep committing directly to master as the history shows? | tech lead | `CONTRIBUTING.md`, [guide](https://docs.unwritten.sh/harness/requirements/agreements/) |
| What is the definition of done for a protocol change: is a decoder test with a real device sample always required, and must tools/test-integration.py also pass? | tech lead | `CONTRIBUTING.md`, [guide](https://docs.unwritten.sh/harness/requirements/agreements/) |
| How is the managed hosting (traccar.org pricing) and the demo server deployed and updated: from the Docker images, installers, or another pipeline outside this repository? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| Who is allowed to run the 'Build Release' workflow, and how is a bad release rolled back (re-tag, previous Docker tag, schema rollback)? | whoever deploys to production | `docs/deploy.md`, [guide](https://docs.unwritten.sh/harness/requirements/deploy-explicit/) |
| Which Java version should developers use: 21 (CI and build.gradle) or 25 (release builds and Docker images)? `.java-version` says 21 for now. | tech lead | `docs/local-dev.md`, [guide](https://docs.unwritten.sh/harness/requirements/toolchain-pinned/) |
| Should local development check out the traccar-web submodule (relative URL `../traccar-web.git`), or is the backend usually run without the web UI? | tech lead | `docs/local-dev.md`, [guide](https://docs.unwritten.sh/harness/requirements/local-env/) |
| For the managed service, where are logs, metrics and alerts kept, and which signal tells you production is broken (only /api/health, or something else)? | whoever runs production | `docs/observability.md`, [guide](https://docs.unwritten.sh/harness/requirements/observability/) |

## The pilot task: Add unit tests for HealthResource

GET /api/health (src/main/java/org/traccar/api/resource/HealthResource.java) is what systemd and the Docker healthchecks use to restart Traccar, but it has no test. Add HealthResourceTest covering the database check and the web.healthCheck.dropThreshold message-ratio logic, using Mockito for Config, StatisticsManager and Storage.

- Done when: src/test/java/org/traccar/api/resource/HealthResourceTest.java exists and runs with make test TESTS=org.traccar.api.resource.HealthResourceTest
- Done when: Tests cover: 200 OK when storage answers, 500 when storage throws StorageException, 500 when stored messages drop below the configured threshold, 200 when no threshold is set
- Done when: No change to HealthResource.java, or a minimal change justified in the PR description
- Done when: make check-fast passes

Run it with `npx uw-harness prove`: an agent does the task with the harness, on its own branch, and the result is added to this page.

## What this does not prove

It does not prove that agents can work on this repository without supervision. It proves that the knowledge is written down and that the gates run and run tests. No pilot task has been run yet. One task is one data point. Review the branch, answer the open questions, and judge the result yourself.
