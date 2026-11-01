# Deploy and release

This repository builds and publishes release artifacts. It does not deploy any running server. How the managed service and the demo servers are updated is not visible here.

## Environments

What the repository shows:

- **Self-hosted installs.** Users download installers (Linux 64-bit, Linux ARM, Windows, and a generic "other" zip) and run them on their own machines. The Linux installer installs to `/opt/traccar` with the systemd unit `setup/traccar.service`. `setup/cloud-init.yaml` installs Traccar on a cloud VM.
- **Docker.** Images `traccar/traccar` (Docker Hub) and `ghcr.io/traccar/traccar`, in Alpine, Debian and Ubuntu flavours (`docker/Dockerfile.*`). `docker/compose/` has example stacks with MySQL and TimescaleDB.
- **Preview builds.** Installers uploaded to DigitalOcean Spaces (`s3://traccar/builds/`).

> [!WARNING]
> **Needs a human.** How is the managed hosting (traccar.org pricing) and the demo server deployed and updated: from the Docker images, installers, or another pipeline outside this repository?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->

## How a release is built

1. Bump `Implementation-Version` in the `jar` manifest of `build.gradle` (for example commit `Update project version`).
2. If the release changes the schema, its changeset is in `schema/changelog-<version>.xml`, included from `schema/changelog-master.xml`.
3. Make sure `make check` passes on `master` (CI does the same with `./gradlew build`).
4. Run the GitHub Actions workflow **Build Release** (`.github/workflows/release.yml`, `workflow_dispatch`) with input `version` (default `preview`).

The workflow then:

- `build-server`: `./gradlew assemble` on Temurin 25, and stages `tracker-server.jar`, `lib/`, `schema/`, `templates/` and `setup/traccar.xml` as `conf/traccar.xml`.
- `build-web`: checks out `traccar/traccar-web` at the same ref and runs its npm install and build scripts (Node 22).
- `build-linux-64`, `build-linux-arm`, `build-windows`, `build-other`: bundle a `jlink` runtime and build `traccar.run` (makeself), `traccar-setup.exe` (Inno Setup, `setup/traccar.iss`) and the zips.
- Test jobs install each installer on a clean runner, start the service and probe `http://localhost:8082` with `curl`.

## How it is published

- `version` = `preview`: installers go to DigitalOcean Spaces with `s3cmd` (secrets `S3_ACCESS_KEY`, `S3_SECRET_KEY`).
- Any other `version`: a GitHub Release `v<version>` with the installers, then Docker images for Alpine, Debian and Ubuntu pushed to Docker Hub and ghcr.io. Tags: `<major>.<minor>.<patch>`, `<major>.<minor>`, `<major>`, each with a `-<os>` suffix; the Alpine image also gets the plain tags and `latest`.

## Roll back

Self-hosted users roll back by installing the previous installer or Docker tag. Liquibase migrations already applied by the new version are not reverted automatically, so a rollback across a schema change needs a database backup.

> [!WARNING]
> **Needs a human.** Who is allowed to run the 'Build Release' workflow, and how is a bad release rolled back (re-tag, previous Docker tag, schema rollback)?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/deploy/
<!-- uw-harness:todo deploy-explicit -->

## Checks after a release

- The release workflow itself installs each installer and checks that the web port answers.
- On a running server, `GET /api/health` returns `OK` (database reachable, no drop in stored messages). See [observability.md](observability.md).
