# Observability

What the code shows about logs, health and metrics. Where production logs, dashboards and alerts live is not visible in this repository.

## Logs

- Library: SLF4J over `java.util.logging` (`org.slf4j:slf4j-jdk14`), set up by `src/main/java/org/traccar/helper/Log.java`.
- Configuration keys (`src/main/java/org/traccar/config/Keys.java`):
  - `logger.console`: log to stdout (on in `debug.xml`).
  - `logger.file`: log file, default `./logs/tracker-server.log`. Installers write to `/opt/traccar/logs` (mounted as a volume in `docker/compose/*.yaml`).
  - `logger.level`: default `info`.
  - `logger.rotate`, `logger.rotate.interval` (`day` by default): one log file per period.
  - `logger.fullStackTraces`: full stack traces instead of one line.
  - `logger.queries`: log SQL queries.
  - `logger.decodeTextData`, `logger.attributes`: what is logged for each decoded message (`helper/PositionLogger.java`).
- Format: one line per record, `YYYY-MM-DD HH:MM:SS LEVEL: message`. Each device message is logged with its connection id, protocol and hex or text payload.
- HTTP request log: `web.requestLog.path` and `web.requestLog.retainDays`.
- Under systemd the journal also holds stdout (`SyslogIdentifier=traccar` in `setup/traccar.service`).

## Health

- `GET /api/health` (`api/resource/HealthResource.java`, no login): returns `OK` with HTTP 200, or HTTP 500 when the database query on `tc_servers` fails, or when `web.healthCheck.dropThreshold` is set and the number of stored messages in the last period fell below that ratio of the previous period.
- `schedule/TaskHealthCheck.java`: under systemd (`WatchdogSec=600` in `setup/traccar.service`), the server calls `/api/health` and notifies the systemd watchdog only on HTTP 200 (always during the first hour after start). When systemd gets no notification for 600 seconds, it restarts the service. `web.disableHealthCheck` turns it off.
- The example compose stacks use the same endpoint as a Docker healthcheck, with `autoheal` restarting unhealthy containers.

## Metrics

- `StatisticsManager` (`database/StatisticsManager.java`) counts requests, messages received and stored, active users and devices, mail, SMS, geocoder and geolocation requests, and writes a daily row to `tc_statistics`. When `server.statistics` is set, it also posts the same anonymous numbers to that URL.
- `GET /api/statistics?from=...&to=...` (`api/resource/StatisticsResource.java`, administrators) returns those rows.
- There is no Prometheus or OpenTelemetry exporter on `master`. A remote branch `codex/add-prometheus-metrics-endpoint` exists but is not merged.

## Error reporting

No Sentry or similar client is in `build.gradle`. Errors go to the log only (`Thread exception`, `Main method error`).

## How to tell that something is wrong

1. `curl -fsS http://<host>:8082/api/health` does not return `OK`.
2. The number of stored messages drops (the `dropThreshold` check above, or `messagesStored` in `/api/statistics`).
3. `ERROR` or `WARN` lines in the log, for example `Port ... disabled due to conflict` at startup, or database errors.
4. Devices go offline in bulk (device status in the web UI, `deviceOffline` events).

## Production

> [!WARNING]
> **Needs a human.** For the managed service, where are logs, metrics and alerts kept, and which signal tells you production is broken (only /api/health, or something else)?
> Why it matters and how to do it: https://docs.unwritten.sh/harness/guides/observability/
<!-- uw-harness:todo observability -->
