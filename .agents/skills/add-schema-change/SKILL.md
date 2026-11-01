---
name: add-schema-change
description: Use when a change needs a new table, column, index or data migration in the Traccar database.
---

# Add a schema change

Background: [docs/decisions/0003-liquibase-schema-for-several-databases.md](../../../docs/decisions/0003-liquibase-schema-for-several-databases.md).

1. Never edit a released changelog. Find the target version: `Implementation-Version` in `build.gradle`, and the last `<include>` in `schema/changelog-master.xml`.
2. If `schema/changelog-<version>.xml` for the version in development already exists and is not released yet, add a changeset to it. Otherwise create it by copying the structure of the last changelog (`logicalFilePath="changelog-<version>"`, one `changeSet` with `author="author"` and `id="changelog-<version>"`), and add `<include file="changelog-<version>.xml" relativeToChangelogFile="true" />` at the end of `schema/changelog-master.xml`.

   > [!WARNING]
   > Which version is "in development" and whether a changelog is already released is not written in the repository. Ask a maintainer when unsure.

3. Use portable Liquibase change types (`createTable`, `addColumn`, `createIndex`, `addForeignKeyConstraint`). Avoid raw `<sql>` unless you add `dbms`-specific variants. Table names start with `tc_`.
4. Update the model class in `src/main/java/org/traccar/model/` (`@StorageName` gives the table; getters and setters map to columns). Fields that are not columns get `@QueryIgnore`.
5. Run `make dev` once on H2: Liquibase applies the changelog at startup; check the log for `Liquibase` errors and the new column in the H2 console (http://localhost:8082/console).
6. Test on PostgreSQL and MySQL: `make db-up`, `cp .env.example .env`, uncomment the PostgreSQL block, `set -a; . ./.env; set +a`, `make dev`. Repeat with the MySQL block. Then `make db-down`.
7. Run `make check-fast`, then `make check`.
8. Note the schema change in the pull request description and in `docs/harness/log.md`: it affects rollback (see `docs/deploy.md`).
