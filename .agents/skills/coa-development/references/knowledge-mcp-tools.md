# CoA Knowledge MCP — Tool Reference

## Read Tools (No Login Required)

### `status`
Lists loaded knowledge layers (`bisbeard`, `spells`, `paths`, `dbc`, `notes`, `cache`), their versions and source dates, whether writes are enabled, and known gaps.

### `items_find`
Filter structured BisBeard items and item stats.
- `realm`: `coa`, `classic`, `s10`, `wotlk`, or `octo` (`coa` matches the shared `coa,classic,s10` main list, shown as unproven).
- `name`: Substring match on item name (case-insensitive).
- `slot`: e.g. `Head`, `Chest`, `Legs`, `Hands`, `Feet`, `Shoulders`, `Waist`, `Wrists`, `Back`, `Neck`, `Finger`, `Trinket`, `Two-Hand`, `One-Hand`, `Main Hand`, `Off Hand`, `Held In Off-hand`, `Shield`, `Ranged`.
- `quality`: `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary`.
- `type`: e.g. `Cloth`, `Leather`, `Mail`, `Plate`, `Swords`, `Maces`, `Axes`, `Daggers`, `Staves`, `Polearms`, `Bows`, `Guns`, `Crossbows`, `Wands`, `Fist Weapons`, `Shield`, `Totem`, `Idol`, `Libram`.
- `item_class`: Class restriction (e.g. `Druid`, `Priest`, `Warrior`); automatically includes items wearable by `All`.
- `category`: `bloodforged`, `affixed`, `dungeon`, `worldforged`, `raid`, `pvp`, `crafting`, `worldboe`, `worldboss`, `enchants`, `reputation`, `quests`, `events`, `vendor`.
- `stat`: Stat key (e.g. `stamina`, `intellect`, `strength`, `agility`, `spirit`, `armor`, `spellPower`, `attackPower`, `feralAttackPower`, `critRating`, `hitRating`, `hasteRating`, `resilienceRating`, `armorPenetration`, `spellPenetration`, `expertise`, `defense`, `dodge`, `parry`, `block`, `blockValue`, `mp5`, `hp5`, `fireResist`, `shadowResist`, `natureResist`, `frostResist`, `arcaneResist`).
- `min_value`: Minimum value for `stat`.
- `limit` (1–100, default 20), `offset` (0–1000).

### `search`
Full-text search across all layers and written entries.
- `query`: Words to match (all words must appear).
- `topic`: `spells`, `items`, `classes`, `dungeons`, `npcs`, `notes`, or `dbc`.
- `realm`: e.g. `coa`, `wotlk`, `octo`, `classic`, `s10`.
- `limit` (1–100, default 10), `offset` (0–1000).

### `get`
Read a single entity page or written entry by ID, plus any attached written entries.
- `id`: e.g. `item:10012`, `item:wotlk:40207`, `spell:133`, `class:coa:barbarian`, `talents:coa:barbarian`, `spec:coa:barbarian-headhunting`, `dbc:Spell`, `dbc:Spell:133`, `path:DBFilesClient/Spell.dbc`, `entry:1`.
- `sections`: Optional array of section titles when a large page lists sections.
- `entries_offset`: Offset for paging attached written entries.

### `dbc_tables` & `dbc_rows`
- `dbc_tables(filter?, limit?, offset?)`: Lists client DBC tables, row/field counts, winning MPQ archive, and archive origin. Passing an exact table name lists all of its fields and `[indexed]` markers.
- `dbc_rows(table, where?, columns?, limit?, offset?)`: Queries rows of a DBC table. `where` takes up to 8 `{field, op, value}` conditions (`op`: `=`, `!=`, `<`, `>`, `<=`, `>=`, `contains`).

### `client_paths`
Browse or search file paths in the CoA client MPQs (paths and byte sizes only).
- `query`: Words (3+ chars each) that must appear in the path.
- `dir`, `ext`, `archive`, `origin`, `include_deleted`, `limit`, `offset`.

### `spell_compare`, `spell_scaling`, `decode_flags`
- `spell_compare(id_a, id_b)`: Shows only fields that differ between two spells.
- `spell_scaling(id, level)`: Computes scaled spell values at `level` (1–80).
- `decode_flags(kind, mask)`: Decodes a hex or decimal bitmask (`Attributes`, `AttributesEx`..`ExG`, `Targets`, `ProcFlags`, `InterruptFlags`, `AuraInterruptFlags`, `ChannelInterruptFlags`, `SchoolMask`, `DmgClass`, `PreventionType`, `Stances`).

---

## Write Tools (Bearer Token Required)

### `write_entry`
```json
{
  "author": "dev-name",
  "subject": "encounter:flame-leviathan",
  "kind": "observation",
  "trust": "observed",
  "realm": "coa",
  "content": "Pylon activation reduces Flame Leviathan damage taken by 50% and grants spell ID 62475.",
  "evidence": {
    "description": "Verified on live CoA realm via combat log and aura inspection on 2026-11-05.",
    "url": "https://youtu.be/example?t=142",
    "timestamp": "2:22",
    "video": true
  },
  "field": "pylonAuraSpellId",
  "value": "62475",
  "position": {
    "map": "Ulduar",
    "x": 312.5,
    "y": -48.2,
    "z": 409.8
  }
}
```

### `undo_entry`
```json
{
  "id": 12,
  "author": "dev-name"
}
```
