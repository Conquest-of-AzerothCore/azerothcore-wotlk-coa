# Server-sent interface Lua

Some features send interface Lua to the client at login: the Manastorm UI fixes
(`Manastorm.ClientUIFixes`) and the Fel Commutation window. Both build an
`AscensionClientLuaChunk` and call `RunAscensionClientLua`
(`src/server/coa/AscensionClientLua.{h,cpp}`), which picks one of two routes per client.

## Formatter route (every client)

The genuine Ascension client has no opcode for interface code. The chunk rides a
`ChallengeRequirementTypes` row patched over SMSG `0x5BC`: its first formatter closes the
client's `return function(value) %s end` template early, runs the chunk, and reopens a
function. The server then defines the requirement row, activates challenge 5 and completes
its criteria so the client compiles the formatter, and finally restores the player's real
challenge list (`mod-coa-challenges` registers the restore). The completion banner for the
chunk's token is filtered on the client.

Each chunk needs its own requirement type and requirement row:

| Feature | Requirement type | Requirement row | Token |
|---|---|---|---|
| Fel Commutation window | 23 | 16263 | `FEL_COMMUTATION_WINDOW` |
| Manastorm UI fixes | 24 | 16262 | `MANASTORM_UI_FIXES` |

## Hot-patch route (clients that announce it)

A client DLL that supports a dedicated channel announces it after every world entry:

| Opcode | Direction | Payload |
|---|---|---|
| `0x8F1` | client to server | u32 protocol version (1), u8 player mode (0 off, 1 ask per realm, 2 allow) |
| `0x8F0` | server to client | sized patch id, sized target addon, sized Lua |
| `0x8F2` | client to server | sized patch id, u8 outcome, sized detail (at most 255 bytes) |

Sized strings are a u32 length followed by the bytes, without a terminator. The patch id is
the chunk's token and the Lua is the chunk exactly as built, without the formatter wrapper or
the banner filter. An empty target addon means "run now"; a named one asks the client to run
the patch when that addon loads, with that addon's trust. Outcomes are 0 ran, 1 applied,
2 deferred, 3 skipped, 4 duplicate, 5 refused by the player, 6 refused by the client's guards,
7 error; the server logs each one under `coa.hotpatch` at Info.

The server resets an account's capability at login and forgets it at logout. A chunk sent
before the client has announced itself is retried every 2 seconds; after 30 seconds without an
announcement the formatter route is used. Clients that never send `0x8F1`, such as the
genuine Ascension DLL, always get the formatter route, so nothing changes for them.

A client with the hot-patch channel may refuse `0x5BC` rows whose formatters are anything but
a display expression, which closes the formatter route on that client. The protocol version is
the switch: the server only sends `0x8F0` to clients announcing version 1 or later.

Regressions: `apps/coa-tests/client_hot_patch` (route choice and packet layout) and
`apps/coa-tests/manastorm_ui_fixes` (the formatter route and the Manastorm chunks).
