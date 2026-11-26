# Streamed client DBC rows

The world tables `gameobjectdisplayinfo_dbc`, `map_dbc` and `mapdifficulty_dbc` already add rows to (or
replace rows in) the server's own `GameObjectDisplayInfo.dbc`, `Map.dbc` and `MapDifficulty.dbc`. With the
display-patch stream on (`CoA.SendDisplayPatches`), the same rows are now also sent to each player
when the client asks for the character list (`CMSG_CHAR_ENUM`), ahead of the list itself. Server and client
read them from one place.

They must arrive before the player presses Enter World: the client starts loading the map the character list
names right away, before the server answers the login, and a map its `Map.dbc` lacks is a fatal
"MapID = N does not exist in Map.dbc" assert. Sending them later (with the login patch stream, or on
`CMSG_PLAYER_LOGIN`) crashed a character logging in on a streamed map.

A realm whose `SMSG_REALM_INFO` names a different realm data path (only Area 52 does) makes the client reload
every DBC a few seconds later, which drops the streamed rows; they come back with the next character list.

Code: `src/server/coa/AscensionClientDbcStream.{h,cpp}`, called from the `CMSG_CHAR_ENUM` branch of
`CanPacketReceiveEarly` in `AscensionCompat.cpp`.

## Client requirement

The genuine Ascension client has no handler for these tables. The rows apply only on a client whose
`Extensions.dll` is built with `ASCENSION_DBC_STREAM` (client-ext `AscDbcStream`). Other clients ignore the
opcodes.

| Opcode | Table | Client row |
|---|---|---|
| `0x8F3` | GameObjectDisplayInfo | 19 fields |
| `0x8F4` | Map | 18 fields |
| `0x8F5` | MapDifficulty | 7 fields |

A packet is a batch: u32 count, then each row's fields in table column order. Numbers are u32 (floats as
their bits). Strings are a u32 length plus bytes. Localized columns send the player's locale (the
`*_Lang_*` columns are positional, slot n = `LocaleConstant` n), else enUS. A batch holds at most 512 rows
or 16 KB. The client grows each table's index once per batch, so streams of many new rows stay cheap.

## What streaming a row does not do

- **New maps need much more than a `map_dbc` row.** The client needs the map's terrain (ADT/WDT/WMO) in its
  archives. The server needs `maps/`, `vmaps/` and `mmaps/` extracted from those same archives, plus
  `instance_template`, area triggers, graveyards, spawns and scripts. A Map row alone gives a map
  the client cannot load.
- **Objects already spawned keep their display.** A changed `gameobjectdisplayinfo_dbc` row applies to
  objects the client creates after the stream, for example on leaving and re-entering view.
- Rows are loaded once, at worldserver startup. Restart the worldserver after editing
  the tables; the server's own stores also read them only at startup.
