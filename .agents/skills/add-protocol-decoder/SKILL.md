---
name: add-protocol-decoder
description: Use when adding a new device protocol or changing how an existing protocol decodes messages or encodes commands.
---

# Add or change a protocol decoder

Background: [docs/decisions/0002-one-netty-decoder-per-protocol.md](../../../docs/decisions/0002-one-netty-decoder-per-protocol.md).

1. Get a real sample message from the task or issue (hex for binary, text otherwise). Do not invent sample data: if there is none, stop and ask.
2. Look for an existing protocol with the same format first: `grep -ril "<vendor or keyword>" src/main/java/org/traccar/protocol`. Many devices reuse GT06, H02, Teltonika, Meitrack or similar formats; extending a decoder is better than adding a protocol.
3. To change an existing protocol, add the sample to `src/test/java/org/traccar/protocol/<Name>ProtocolDecoderTest.java` first, for example:
   ```java
   verifyDecode(decoder, binary("78780D01086471700328358100093F040D0A"));   // no position expected
   verifyDecode(decoder, binary("7979...0d0a"),
           position(Checks.ATTRIBUTES).attribute(Position.KEY_POWER, 4.05));
   ```
   The number of `position(...)` arguments is the number of positions expected. `position()` (= `Checks.ALL`) checks that time, coordinates, speed and course are in valid ranges; `Checks.ATTRIBUTES` checks the attributes only; `Checks.NONE` checks only what you chain (`.attribute(...)`). See `src/test/java/org/traccar/ProtocolTest.java`.
   Run it and see it fail: `make test TESTS=org.traccar.protocol.Gt06ProtocolDecoderTest`.
4. For a new protocol, create in `src/main/java/org/traccar/protocol/`, copying a similar protocol:
   - `<Name>Protocol.java` extends `BaseProtocol`; adds a `TrackerServer` (second argument `true` for UDP) and its handlers in `addProtocolHandlers`.
   - `<Name>FrameDecoder.java` if the transport is a stream with no simple delimiter (otherwise use `CharacterDelimiterFrameDecoder` or `LineBasedFrameDecoder` in the pipeline).
   - `<Name>ProtocolDecoder.java` extends `BaseProtocolDecoder`; use `getDeviceSession(...)`, `Parser`/`PatternBuilder` for text, `ByteBuf` and `BitUtil` for binary.
   - `<Name>ProtocolEncoder.java` only if the device accepts commands, and list them with `setSupportedDataCommands`.
5. Register a new protocol in `src/main/java/org/traccar/config/ProtocolConfig.java`: add the import and `put(<Name>Protocol.class, <port>);` with the next free port after the last entry.
6. Create `src/test/java/org/traccar/protocol/<Name>ProtocolDecoderTest.java` (extends `ProtocolTest`, `var decoder = inject(new <Name>ProtocolDecoder(null));`) and, if there is a frame decoder, `<Name>FrameDecoderTest.java`.
7. Use the standard keys in `src/main/java/org/traccar/model/Position.java` (`KEY_*`, `ALARM_*`) before inventing attribute names.
8. Run `make check-fast`. Checkstyle often flags line length and import order in decoders.
9. Optional end-to-end check: `make dev`, then send the sample with `tools/hex.sh <port> <hex>` and look for the decoded position in the console log.
10. Commit as `Decode <vendor> <message type>` or `Add <Name> protocol`, following `CONTRIBUTING.md`.
