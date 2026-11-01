# Product

Traccar is an open source GPS tracking server. It lets anyone track vehicles, assets or people with almost any GPS tracker on the market, without vendor lock-in. One self-hosted (or managed) server receives data from more than 2000 device models over 200+ protocols, keeps the history in a standard SQL database, and gives users live maps, reports, geofences, alarms and notifications through a REST API and the web dashboard.

This repository is the server (`tracker-server`). The web dashboard is the separate `traccar-web` repository; the mobile apps are also separate.

## Users

- **Fleet operators and dispatchers** follow vehicles in real time, read reports and receive alarms.
- **GPS tracking resellers** run a white-label Traccar platform for their own customers (users, groups, device limits, expirations).
- **Individuals** track their own devices.
- **Administrators** install and configure the server: `traccar.xml`, database, enabled protocols and ports.
- **Integrators** use the REST API (`openapi.yaml`), the WebSocket stream, the MCP endpoint or the forwarders (Kafka, MQTT, AMQP, Redis, HTTP).

## Use cases and entry points

Paths are under `src/main/java/org/traccar/` unless they start at the repository root.

| Use case | What happens | Entry points |
| --- | --- | --- |
| Receive and decode device data | Trackers connect over TCP, UDP, HTTP or MQTT to a per-protocol port. A Netty pipeline frames and decodes the messages into `Position` objects. | `ServerManager.java`, `TrackerServer.java`, `BasePipelineFactory.java`, `protocol/*ProtocolDecoder.java` (for example `Gt06ProtocolDecoder.java`) |
| Process and store positions | Handlers filter, compute distance, motion, engine hours, address, geofences, speed limits and computed attributes, then write to the database. | `ProcessingHandler.java`, `handler/`, `database/PositionBatchWriter.java`, `storage/DatabaseStorage.java` |
| Events and notifications | Event handlers detect alarms, geofence enter and exit, overspeed, ignition, maintenance and more. Notificators send them by email, SMS, Firebase push, Telegram, Pushover, WhatsApp or web. | `handler/events/`, `notification/`, `notificators/`, `templates/notifications/` |
| Manage accounts, devices and permissions | Jersey resources under `/api` for users, devices, groups, drivers, geofences, calendars, attributes, maintenance, notifications, permissions, sessions and shares. | `api/resource/`, `api/security/`, `openapi.yaml`, `web/WebServer.java` |
| Live tracking | Jetty serves the web app and a WebSocket (`/api/socket`) that pushes positions, events and device status. | `api/AsyncSocket.java`, `api/AsyncSocketServlet.java`, `session/ConnectionManager.java` |
| Reports and exports | Route, events, trips, stops, summary, geofence and combined reports; Excel, CSV, GPX and KML export; scheduled reports by email. | `api/resource/ReportResource.java`, `reports/`, `templates/export/`, `schedule/TaskReports.java` |
| Send commands to devices | Engine stop, reboot, custom commands. Encoders translate them per protocol; commands are queued when the device is offline. | `api/resource/CommandResource.java`, `database/CommandsManager.java`, `protocol/*ProtocolEncoder.java` |
| Forward data | Positions and events go to Kafka, MQTT, AMQP, Redis, Wialon or HTTP URLs. | `forward/`, `handler/PositionForwardingHandler.java` |
| Authentication and SSO | Password, TOTP, LDAP, OpenID Connect, OAuth clients, MCP endpoint for AI tools. | `api/resource/SessionResource.java`, `api/resource/OidcResource.java`, `database/LdapProvider.java`, `database/OpenIdProvider.java`, `web/McpServerHolder.java` |
| Background jobs and health | Inactivity checks, expirations, session timeout, temporary data cleanup, systemd watchdog, WebSocket keepalive; `GET /api/health`. | `schedule/ScheduleManager.java`, `api/resource/HealthResource.java` |

## Glossary

| Term | Meaning |
| --- | --- |
| Position | One decoded location fix from a device: time, coordinates, speed, course, plus free-form attributes. `model/Position.java`, table `tc_positions`. |
| Device | A tracker, identified by its `uniqueId` (usually the IMEI). |
| Protocol decoder / encoder | Per-protocol Netty handler. The decoder turns device bytes into Positions; the encoder turns commands into device bytes. |
| Frame decoder | Netty handler that splits the byte stream into complete messages before the protocol decoder. |
| Handler | Processing step applied to every Position after decoding (`handler/`), for example `FilterHandler`, `GeofenceHandler`. |
| Event | Something derived from positions: alarm, geofence enter or exit, overspeed, ignition on or off, device online or offline. Table `tc_events`. |
| Notificator | Delivery channel for event notifications (`notificators/`). |
| Forwarder | Sends positions or events to an external system (`forward/`). |
| Computed attribute | User-defined JEXL expression evaluated on each position to create derived attributes. |
| Geofence | Geographic area (circle, polygon, polyline) that triggers enter and exit events. |
| Server (model) | The single global settings record of the instance (`tc_servers`), not a host. |
| Keys | `config/Keys.java`: the documented catalogue of every configuration key. |
| debug.xml / traccar.xml | Java properties XML configuration files. `debug.xml` is the local development config, used by default by `Main`; `setup/traccar.xml` is the packaged default. |
| Broadcast service | Cache synchronisation between several Traccar nodes through Redis or multicast (`broadcast/`). |
| Plus codes | Open Location Code offline geocoder, used in `debug.xml` (`geocoder.type=pluscodes`). |
| MCP | Model Context Protocol endpoint (`/api/mcp`) that exposes the API to AI tools (`web.mcp.enable`). |
