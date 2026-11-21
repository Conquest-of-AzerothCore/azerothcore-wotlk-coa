# Static client data

The CoA client reads static rows (spells, items, displays, models, maps, world maps, vehicles) from the DBC files
inside its MPQ archives. Those files are the source of truth for that data. The server does not stream static rows
at login or on demand; it reads its own copy of the same tables from `<DataDir>/dbc` plus the world `*_dbc`
override tables. See [ADR 1012](../adr/1012-static-client-data-ships-in-the-client-mpqs.md) for the decision.

## Where each table lives

The client loads its archives in order and the last archive carrying a table wins (`archive_rank` in
`apps/coa-dbc/client_dbc.py`). The rows the server used to stream live in these winning files:

- `patch-M.MPQ`: CreatureModelData, CreatureDisplayInfo, Item, SoundEntries, SuperTrack, QuestSuperTrack,
  SkillLineAbility, Vehicle, VehicleSeat, WorldMapArea, WorldMapOverlay, Map, MapDifficulty,
  GameObjectDisplayInfo
- `patch-S.MPQ`: SpellVisual, SpellVisualKit, SpellVisualKitModelAttach, SpellShapeshiftForm
- `patch-ZG.MPQ`: Spell, SpellVisualEffectName, ItemDisplayInfo, VanityCollection (prices stream from the server,
  see below)

`patch-ZG.MPQ` loads after `patch-M.MPQ`, `patch-S.MPQ` and `patch-T.MPQ`, so it also wins for every other table
it carries, among them Achievement, AreaTable, ItemAddon, ItemSet, SkillLine and SpellMissileMotion. The copies of
those tables in the earlier archives are not read; edit the `patch-ZG.MPQ` copy.

`client_dbc.py extract` writes `client-dbc.manifest.json`, which records the archive each table came from; check it
when a later archive starts carrying one of these tables.

## What the server still sends

Rows that differ per player or over time cannot be baked and are still sent: spell notice rows (hidden flag) and
swap placement rows (rank text) for custom classes (0x092A, built from the server's Spell store and
`coa_client_spell_description`, the same row the client file carries), character advancement swap entries
(0x064A), spellbook custom attributes (0x05F4), Mythic+ data and `QuestSuperTrack` rows with race restrictions
(0x06BF; the client file carries the all-race version). The server owns Vanity Store prices: at login it streams a
`VanityCollection` row (0x0573) for every `coa_client_vanity_collection` item that has a client row, with the
realm's Donation Point, Seasonal Point and Bazaar Token prices in fields 4 to 6. The client file's prices are only
a fallback for a client that has not received the stream. Only Bazaar Token purchases are charged in game: the
server takes the price from `coa_client_vanity_collection` (or the DBC when the item has no row), never from the
client. A Donation Point request only delivers an item the account already owns, and Seasonal Point requests are
ignored. Lua hot patches, global strings, Tutorial, cosmetic pets, Destiny Weaver displays,
Manastorm rows and woodworking appearances still stream.
`CoA.SendDisplayPatches` gates the per-player rows.

## Adding or changing a client row

A change that adds or edits an item, spell, display, model, map or world map row is a client data change.
Registering an item with `ClientItemPatches::Register()` used to be enough; that registry no longer exists.

1. Change the row in the winning DBC of its table (above) and repack that archive. Edit a copy; the existing
   `apps/coa-spells/*.py` editors write candidate DBC files the same way. Never add an archive that outranks
   the winner for only some rows: the client reads one whole file per table.
2. Give the server the same row. Either extract the updated client into `<DataDir>/dbc`
   (`client_dbc.py extract`, see [the DBC tools](../../apps/coa-dbc/README.md)) or add the matching row to the
   world `*_dbc` table in `data/sql/updates/pending_db_world/`. Server-side data that is not a client row
   (`item_template`, `spell_dbc` rows for server-only spells) is unchanged.
3. Run the drift check below against the updated client and the world database. The PR names the archive and
   tables it changes and reports the drift result.
4. The changed archive ships through the CDN with the release; publishing the CDN content happens outside this
   repository.

The November 2026 migration (PR #12775) was a one-time bake: the rows were taken from a dump of exactly what the
server streamed at `ced81e8073` and merged into the winning files of the live client, the dev client and the CDN
content. That script needed the removed streams as input and is not kept; later changes edit the DBC files
directly as described above.

## Drift check

`client_dbc.py drift` compares a client set extracted from the shipped archives with what the server uses:

```sh
python apps/coa-dbc/client_dbc.py extract "C:/CoA/client/Data" out/client-dbc --mpqcli path/to/mpqcli.exe
python apps/coa-dbc/client_dbc.py drift out/client-dbc --server-dbc "<DataDir>/dbc" \
    --mysql path/to/mysql --defaults-file path/to/client.ini --database acore_world --ids
```

- `--server-dbc`: every table the core loads must be identical in the server's `<DataDir>/dbc` and the client.
- Each world `*_dbc` table: every row must exist in the client file with the same values. An empty string keeps
  the file's text, as the server's loader does. `spell_dbc` rows missing from the client are server-side spells and
  are listed as notes, not failures.
- `coa_client_spell_description`: each non-empty Description and ToolTip must equal the English text of that spell
  in the client's `Spell.dbc`.

It exits 1 when anything drifts; `--json` writes the full report. Run it before every CDN release and in any PR
that changes a client archive, a `*_dbc` table or `coa_client_spell_description`. It needs a client installation,
so it is not part of `tools/verify_all.py`. The gameplay harness seeds each test player with the Spell rows the
server would have sent, not with the archive contents, so passing scenarios do not prove the archives are current.

## Releasing

Publish the CDN update first, then deploy the server. A client without the current `patch-M.MPQ`, `patch-S.MPQ`,
`patch-T.MPQ` and `patch-ZG.MPQ` shows missing or wrong spells, items, models, map data and tooltips, because the
server no longer fills those rows in.

The migration `zzzz_rev_20261118_20_coa_drop_baked_client_tables.sql` drops `coa_client_world_map_area`,
`coa_client_world_map_overlay`, `coa_client_super_track`, `coa_client_skill_line_ability` and
`coa_client_shapeshift_form`. Once it is applied, a server binary from before PR #12775 can no longer stream those
rows; rolling back the server also needs those tables restored from a backup.
