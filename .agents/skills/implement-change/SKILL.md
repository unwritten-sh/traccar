---
name: implement-change
description: Use for any code change in Traccar server, from reading the task to a change that passes the gates and is ready for review.
---

# Implement a change

1. Read `AGENTS.md`, then the part of `docs/architecture.md` that covers the code you will touch. For a device protocol, use the `add-protocol-decoder` skill. For a table or column, use `add-schema-change`.
2. Prepare the workspace once: `make setup` (installs the pre-push hook and builds `target/tracker-server.jar`).
3. Find the code and its test. Tests mirror the main package: `src/main/java/org/traccar/handler/FilterHandler.java` is tested by `src/test/java/org/traccar/handler/FilterHandlerTest.java`. Test helpers: `BaseTest` (injection, mocks) and `ProtocolTest` (decoder checks).
4. Write or update the test first and run only that class:
   `make test TESTS=org.traccar.handler.FilterHandlerTest`
5. Make the change. Follow the existing style: 4 spaces, 120 columns, single-class imports, Apache license header on new files. New configuration keys go into `src/main/java/org/traccar/config/Keys.java` with a Javadoc comment. New REST parameters or resources go into `openapi.yaml` too.
6. Run the fast gate: `make check-fast` (Checkstyle and all unit tests, about 30 seconds). Fix every Checkstyle error; do not add suppressions.
7. Run the full gate before you open the pull request: `make check` (same as CI).
8. If the change is user-visible, check it in the running server: `make dev`, then `curl localhost:8082/api/health` and the endpoint you changed.
9. Add an entry to `docs/harness/log.md` for a significant change (date, what changed, what you learned, what is left).
10. Commit with a short imperative subject and no prefix (see `CONTRIBUTING.md`). Open a pull request against `master`; never push to `master`.
