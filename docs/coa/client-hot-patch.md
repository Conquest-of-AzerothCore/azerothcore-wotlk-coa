# Server-sent interface Lua

Some features send interface Lua to the client: the Manastorm UI fixes and the Fel Commutation
window at login (`Manastorm.ClientUIFixes`), and the Extra Quests window once a quest goes past the
25-slot log (`Quests.LogSize`). Each builds an `AscensionClientLuaChunk` and calls `RunAscensionClientLua`
(`src/server/coa/AscensionClientLua.{h,cpp}`).

## Only the hot-patch channel

Chunks go to the client only over the hot-patch channel below. Earlier versions fell back to a
`ChallengeRequirementTypes` row patched over SMSG `0x5BC`, whose formatter smuggled the chunk in
and was triggered by completing a fake criterion of challenge 5 ("Partner Up!"). That route is
gone: hot-patch clients refuse such rows, so on them it ran nothing and left a stray
"Partner Up! <token> Completed!" banner. Clients without the channel, including the genuine
Ascension DLL, receive no interface Lua, so the Fel Commutation window, the Manastorm UI fixes,
the Extra Quests window and the Bazaar Token cap quest rewards are unavailable to them.

The `RequirementTypeId` and `RequirementId` of a chunk are unused by the sender. The
`.clientpush reqtype` GM command still sends a raw `0x5BC` formatter row on request,
for testing clients that accept one.

## Hot-patch channel

A client DLL that supports a dedicated channel announces it after every world entry:

| Opcode | Direction | Payload |
|---|---|---|
| `0x8F1` | client to server | u32 protocol version (1), u8 player mode (0 off, 1 ask per realm, 2 allow) |
| `0x8F0` | server to client | sized patch id, sized target addon, sized Lua |
| `0x8F2` | client to server | sized patch id, u8 outcome, sized detail (at most 255 bytes) |

Sized strings are a u32 length followed by the bytes, without a terminator. The patch id is
the chunk's token and the Lua is the chunk exactly as built. An empty target addon means "run now"; a named one asks the client to run
the patch when that addon loads, with that addon's trust. Outcomes are 0 ran, 1 applied,
2 deferred, 3 skipped, 4 duplicate, 5 refused by the player, 6 refused by the client's guards,
7 error; the server logs each one under `coa.hotpatch` at Info.

The server forgets an account's capability at logout. `0x8F1` is handled on the network thread
as it arrives, so it can land before the world thread runs the login hook; the login hook therefore
keeps a capability that is already known. A chunk sent before the client has announced itself is
queued in arrival order, up to 128 KB of chunks per account, and sent as soon as `0x8F1`
arrives, however late; logout discards the queue. Every chunk is kept, because a later one may
depend on an earlier one (the Manastorm reward clock refresh needs the full reward state first).
Queueing, flushing and direct sends share one lock, so a chunk sent while the queue is flushed
never overtakes a queued one. The protocol version is the switch:
the server only sends `0x8F0` to clients announcing version 1 or later, and drops the queue of a
client announcing 0. A client that never sends `0x8F1` is sent nothing.

Regressions: `apps/coa-tests/client_hot_patch` (queueing, route choice and packet layout) and
`apps/coa-tests/manastorm_ui_fixes` (the Manastorm chunks).
