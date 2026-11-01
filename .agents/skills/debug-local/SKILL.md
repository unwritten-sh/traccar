---
name: debug-local
description: Use when a bug must be reproduced on a local Traccar server, or a test fails and the cause is not clear from its output.
---

# Debug locally

Details and common problems: [docs/local-dev.md](../../../docs/local-dev.md).

1. Reproduce with the smallest thing possible. For a decoding bug, put the raw message in the matching `*ProtocolDecoderTest` and run `make test TESTS=org.traccar.protocol.<Name>ProtocolDecoderTest`. The test summary prints failures with full stack traces.
2. For anything else, start the server: `make dev`. It uses `debug.xml`: H2 database in `target/`, console logs with full stack traces, port 8082. Without the `traccar-web` submodule it runs API-only.
3. Check that it is alive: `curl localhost:8082/api/health` must print `OK`.
4. Create the first user (it becomes administrator):
   `curl -H 'Content-Type: application/json' -d '{"name":"admin","email":"admin","password":"admin"}' localhost:8082/api/users`
5. Send device data. Binary: `tools/hex.sh <port> <hex>`. Text over HTTP (OsmAnd protocol, port 5055): `curl "localhost:5055/?id=123456&lat=48.85&lon=2.35"`. All protocols at once: `python3 tools/test-integration.py`. Ports are in `src/main/java/org/traccar/config/ProtocolConfig.java`.
6. Read the console log. Each message is logged with its connection id, protocol and payload. For more detail, copy `debug.xml` to `target/debug-local.xml`, set `logger.level` to `all` and `logger.queries` to `true`, and run `java -jar target/tracker-server.jar target/debug-local.xml`.
7. Inspect data in the H2 console: http://localhost:8082/console, JDBC URL `jdbc:h2:./target/database`, user `sa`, empty password. Main tables: `tc_devices`, `tc_positions`, `tc_events`.
8. Breakpoints: run `org.traccar.Main` from the IDE with argument `debug.xml` and the repository root as working directory, or add `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005` to the `java` command and attach.
9. Reset state: stop the server, `rm -f target/database*`, start again.
10. When fixed, turn the reproduction into a unit test and follow the `implement-change` skill.
