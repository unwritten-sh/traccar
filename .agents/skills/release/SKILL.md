---
name: release
description: Use when preparing or checking a Traccar release build; it covers only what the repository shows and lists what is still unknown.
---

# Release

Source of truth: [docs/deploy.md](../../../docs/deploy.md). Several parts are still open questions there (who may release, rollback, how the managed service is updated). Do not guess them: stop and ask a human.

1. Confirm with a human that a release is wanted and which version number to use. Agents do not run the release workflow on their own.
2. Check that `master` is green: `make check` locally and the latest **Build Project** run in GitHub Actions.
3. Prepare the version bump in a pull request: change `Implementation-Version` in the `jar` manifest of `build.gradle`. If the release changed the schema, check that `schema/changelog-<version>.xml` is included from `schema/changelog-master.xml`.
4. After merge, a maintainer runs the **Build Release** workflow (`.github/workflows/release.yml`) with the `version` input. `preview` only uploads installers to DigitalOcean Spaces; any other value creates GitHub Release `v<version>` and pushes Docker images.
5. Watch the workflow test jobs: each installer is installed on a clean runner and `curl -fsS http://localhost:8082` must answer.
6. After publication, check a running instance with `curl -fsS http://<host>:8082/api/health` (see `docs/observability.md`).
7. Rollback and the managed-service rollout are open TODOs in `docs/deploy.md`. Report the gap instead of improvising.
