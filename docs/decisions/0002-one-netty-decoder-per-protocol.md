# 2. One Netty pipeline, decoder and test per device protocol

Date: 2026-11-01

Status: inferred from the code, to be confirmed by the team.

## Context

Traccar supports more than 200 device protocols. Devices speak binary or text formats over TCP, UDP, HTTP or MQTT, and many vendors change their formats over time. Each protocol needs its own framing and parsing, and a bug in one must not break the others.

## Decision

Each protocol is a set of classes in `src/main/java/org/traccar/protocol/`:

- `<Name>Protocol` extends `BaseProtocol`, declares supported commands and adds one or more `TrackerServer` listeners with their Netty handlers.
- `<Name>FrameDecoder` (when needed) splits the stream into messages.
- `<Name>ProtocolDecoder` extends `BaseProtocolDecoder` (or the HTTP/MQTT variants) and returns `Position` objects.
- `<Name>ProtocolEncoder` (when the device accepts commands).
- The protocol is registered with its default port in `src/main/java/org/traccar/config/ProtocolConfig.java`.
- `src/test/java/org/traccar/protocol/<Name>ProtocolDecoderTest` extends `ProtocolTest` and replays real messages as hex or text.

Every protocol runs on its own port, so a device never needs to be identified before decoding.

## Consequences

- A new protocol or a format change is local to a few files and one test class.
- The `protocol` package is very large (about 680 files). Shared parsing helpers live in `src/main/java/org/traccar/helper/` (`Parser`, `PatternBuilder`, `BitUtil`, `Checksum`, `UnitsConverter`); reuse them instead of writing new ones.
- A server opens hundreds of ports by default. `protocols.enable` limits them.
- Decoder tests are fast and offline, which makes `./gradlew test` a usable fast gate.
