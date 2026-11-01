# Contributing

How changes get into Traccar server. Rules marked *(inferred)* come from the git history and the build, not from a written team rule.

## Branches and pull requests

- The default branch is `master`. CI (`.github/workflows/gradle.yml`) runs on every push and pull request to `master`.
- Agents and outside contributors never push to `master`. They work on a branch and open a pull request that a human reviews.
- Maintainers also commit directly to `master` today: most of the last 500 commits have no pull request number. *(inferred)*
- Since about September 2025, pull requests land as single commits with the PR number in the subject, for example `Add JMAK commands (#6095)`. The last merge commit (`Merge pull request #5643`) is from 2025-08-20. *(inferred: squash merge is the current strategy)*

> [!WARNING]
> **Needs a human.** Should outside contributors and agents always open a pull request, while maintainers keep committing directly to master as the history shows?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/agreements/
<!-- uw-harness:todo agreements -->

## Commit messages

Seen in the history *(inferred)*:

- Short imperative subject, capitalised, no prefix, no trailing period: `Decode GT06 temperature info packet`, `Reject empty passwords in LDAP auth`.
- `(#1234)` at the end when the commit comes from a pull request; `(fix #1234)` when it closes an issue.
- One logical change per commit.

## Code style

- Checkstyle (`gradle/checkstyle.xml`) runs in `./gradlew check` and fails CI on any violation. Run `make lint`.
- `.editorconfig`: 4 spaces, 120 columns, LF, final newline, single-class imports (no wildcards).
- New Java files start with the Apache License 2.0 header used by the other files.
- New configuration keys go into `src/main/java/org/traccar/config/Keys.java` with a Javadoc comment: that comment is the user documentation (`tools/config-doc.py` reads it).

## Protocol changes

- Every decoder change comes with a new or updated case in `src/test/java/org/traccar/protocol/<Name>ProtocolDecoderTest.java`, using a real message from the device as hex or text. *(inferred: every decoder has a test class)*
- Reuse the helpers in `src/main/java/org/traccar/helper/` and the base classes (`BaseProtocolDecoder`, `BaseFrameDecoder`).

> [!WARNING]
> **Needs a human.** What is the definition of done for a protocol change: is a decoder test with a real device sample always required, and must tools/test-integration.py also pass?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/requirements/agreements/
<!-- uw-harness:todo agreements -->

## Schema changes

- Never edit a released `schema/changelog-*.xml`. Add a changeset to `schema/changelog-<next version>.xml` and include it from `schema/changelog-master.xml`. See [docs/decisions/0003-liquibase-schema-for-several-databases.md](docs/decisions/0003-liquibase-schema-for-several-databases.md).
- The changeset must work on H2, MySQL, MariaDB, PostgreSQL and SQL Server.

## Definition of done

1. `make check-fast` passes (Checkstyle and unit tests). The pre-push hook runs it.
2. `make check` passes (same as CI: `./gradlew build`).
3. New behaviour has a test. Protocol changes have a decoder test with a real message.
4. API changes are reflected in `openapi.yaml`.
5. A significant change has an entry in `docs/harness/log.md`.
6. A human reviewed the pull request.
