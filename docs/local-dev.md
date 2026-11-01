# Local development

## Prerequisites

- A JDK, version 21 or newer. CI builds with Temurin 21 (`.java-version`). Release builds and Docker images use JDK 25. The Makefile finds a JDK 21+ by itself (`tools/harness/java-home.sh`): `JAVA_HOME`, then `java` on `PATH`, then macOS registered JDKs, then Homebrew, SDKMAN and `/usr/lib/jvm`.
> [!WARNING]
> **Needs a human.** Which Java version should developers use: 21 (CI and build.gradle) or 25 (release builds and Docker images)? `.java-version` says 21 for now.
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/toolchain-pinned/
<!-- uw-harness:todo toolchain-pinned -->

- Network access to Maven Central for every Gradle run. `build.gradle` resolves Jersey transitive versions at configuration time, so even listing Gradle tasks needs the network until the dependencies are cached.
- `make`, `git`. Docker only if you want PostgreSQL or MySQL (`compose.yaml`).
- Python 3 only for the scripts in `tools/`.

> [!WARNING]
> **Needs a human.** Should local development check out the traccar-web submodule (relative URL `../traccar-web.git`), or is the backend usually run without the web UI?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/local-env/
<!-- uw-harness:todo local-env -->

## First run

```sh
make setup   # git hooks (core.hooksPath=.githooks) + ./gradlew assemble
make dev     # builds and runs java -jar target/tracker-server.jar debug.xml
curl localhost:8082/api/health   # prints OK
```

`debug.xml` is the local configuration. It uses an embedded H2 database in `target/database*`, the offline Plus codes geocoder, console logging with full stack traces, the H2 console and the MCP endpoint.

The web UI comes from the `traccar-web` submodule (`web.path` = `./traccar-web/simple`). In a checkout without the submodule, the server stops at startup with `NoSuchFileException .../traccar-web/simple`. `make dev` detects this and runs the server API-only: it sets `CONFIG_USE_ENVIRONMENT_VARIABLES=true` and `WEB_PATH=./target/web`. The REST API, WebSocket and device ports work; the browser UI does not.

The first user that registers through `POST /api/users` becomes the administrator. `tools/test-integration.py` expects a user `admin` with password `admin`.

## Daily run

```sh
make dev                     # run the server
make check-fast              # Checkstyle + unit tests (~30 s)
make test TESTS=org.traccar.protocol.Gt06ProtocolDecoderTest   # one test class
make check                   # full gate, same as CI
```

Every protocol listens on its own port (see `src/main/java/org/traccar/config/ProtocolConfig.java`, from 5001 up). A port already used by another program is skipped with a `WARN: Port ... disabled due to conflict` line; the server keeps running. To start only some protocols, add `<entry key='protocols.enable'>gt06,osmand</entry>` to a copy of `debug.xml`.

## Other databases

```sh
make db-up                   # PostgreSQL on 5432, MySQL on 3306 (local credentials traccar/traccar)
set -a; . ./.env; set +a     # after cp .env.example .env and uncommenting the PostgreSQL or MySQL block
make dev
make db-down
```

Liquibase creates the `tc_*` tables at startup on any of these databases.

## Reset

- H2 data: stop the server, then `rm -f target/database*`. `make clean` deletes all of `target/`.
- Compose data: `docker compose down -v`.

## Debug

- Logs go to the console (`logger.console=true` in `debug.xml`). Set `logger.level` to `all` or `fine` for more detail, and `logger.queries` to `true` to log SQL.
- H2 console: http://localhost:8082/console (JDBC URL `jdbc:h2:./target/database`, user `sa`, empty password).
- Send a sample message to a running server: `tools/hex.sh 5023 78780D01086471700328358100093F040D0A` (GT06 login packet on port 5023).
- Send one message per protocol and check the result: `python3 tools/test-integration.py` (needs the server and the `admin`/`admin` user).
- Breakpoints: open the project as a Gradle project in your IDE and run `org.traccar.Main` with the argument `debug.xml` and the repository root as the working directory. Or start the jar with `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005` and attach.
- Most decoder bugs are faster to reproduce in a unit test: copy the hex message into the matching `*ProtocolDecoderTest` and run `make test TESTS=...`.

## Common problems

| Symptom | Cause and fix |
| --- | --- |
| `invalid source release: 21` or `No JDK 21 or newer found` | Install Temurin 21 or set `JAVA_HOME` to a JDK 21+. |
| Gradle hangs or fails at configuration | No access to Maven Central. Gradle needs it on every run until the cache is warm. |
| `NoSuchFileException .../traccar-web/simple` | You ran `java -jar` directly without the submodule. Use `make dev`. |
| `Port 5xxx disabled due to conflict` | Another program uses that port. Harmless unless you test that protocol. |
| Tests pass locally but CI fails on style | Run `make lint`. Checkstyle rules are in `gradle/checkstyle.xml`. |
