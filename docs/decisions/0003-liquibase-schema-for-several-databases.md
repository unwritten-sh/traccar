# 3. Liquibase changelogs for a schema shared by several databases

Date: 2026-11-01

Status: inferred from the code, to be confirmed by the team.

## Context

Self-hosted users run Traccar on the database they already have. `build.gradle` ships JDBC drivers for H2, MySQL, MariaDB, PostgreSQL and SQL Server. The server must create and upgrade its schema by itself during an upgrade, without a manual migration step.

## Decision

The schema is defined by Liquibase XML changelogs in `schema/`. `schema/changelog-master.xml` includes one `changelog-<version>.xml` per release that changed the schema. `src/main/java/org/traccar/storage/DatabaseModule.java` runs Liquibase at startup. Queries are built by `storage/QueryBuilder` and `storage/DatabaseStorage` from the model classes (`@StorageName` gives the table), not hand-written per database.

## Consequences

- Upgrading is "install the new version and start it".
- Released changelogs must never be edited: Liquibase stores checksums. Changes go into a new changeset.
- A changeset must work on every supported database. The unit tests do not run against MySQL, PostgreSQL or SQL Server, so cross-database breakage is not caught by CI. `compose.yaml` gives local PostgreSQL and MySQL to test by hand.
- Rolling back a release that changed the schema is not automatic.
