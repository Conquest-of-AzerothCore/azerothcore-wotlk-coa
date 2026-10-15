# Captured item stats

The default item lift estimates stats from `RandomPropertiesPoints.dbc` and generic item curves.
The original CoA `ItemStat.dbc` contains explicit `(item, scaling level)` rows whose values can differ
substantially. For example, Brawler Gloves (720) at level 58 contain 10 strength, 8 stamina and 249 armor.
The table also contains required level 53, sell price 2676 and reborn armor 82 for that key.

To use the captured table for the existing loot and quest item lifts:

1. Place the original CoA `ItemStat.dbc` at `<DataDir>/dbc/ItemStat.dbc`.
2. Restart the server. The captured table loads automatically; no separate configuration flag is needed.
3. Check startup for `Loaded ... captured item-stat rows`. Invalid rows are skipped with a warning that
   counts invalid and duplicate rows. Duplicate keys retain the first valid row in file order. A missing,
   malformed or truncated file, or one with no valid rows, logs an error and leaves estimated scaling active.

The file used for the regression fixtures has SHA-256
`c09b91e67d97db5624f68a3de3cc0a3aa76e8672647cbf9bd924e343f918b237`: 1,513,931 records,
39 numeric fields, 156 bytes per row, no string block. It came from the original CoA client DBC archive
and matches the preserved `patch-M.MPQ` manifest. The CoA-Databank provenance is preserved in
[ascension-data](https://github.com/hertigservices/ascension-data/tree/main/supplemental/coa-databank).
The repository includes six byte-exact numeric regression rows, not the full client archive or DBC.

Lifted templates use the base item ID and `base.ItemLevel + lift` for exact lookup. Captured stats replace
the ten stat pairs, damage ranges, armor, resistances, block, random property, required level and sell price.
Buy price follows the captured sell-price ratio to the base template, with rounding and a cap at `INT32_MAX`.
When the base sell price is zero, buy price uses the existing estimated price ratio. Nonpositive base buy
prices retain their sentinel values. Item identity, weapon delay, damage schools and other fields absent
from this table retain the base template's values. Missing keys retain the existing estimates; they never
use a nearby captured row.
The table is loaded once at startup, before scaled templates are materialized, and requires a restart to
change. It is a sorted, contiguous row vector with binary lookup rather than a sparse DBC ID array or a
per-row hash allocation (approximately 236 MB for the original table, before allocator overhead).

The native Extensions request `CMSG_ITEM_STAT_QUERY` (`0x6FF`) is queued through the existing bounded
extension queue and handled during the player update. An eight-byte `(item ID, scaling level)` request
gets a 168-byte `0x700` reply when both the server item template and captured row exist. Synthetic item
IDs resolve to their base ID for lookup but keep the requested ID in the reply key. Malformed requests,
unknown items and missing rows receive no invented response.

The wire record contains the requested item and level at offsets `0x00` and `0x04`, the base item at
`0x08`, the captured scaling level at `0x0C`, ten stat pairs at `0x10`, and two damage records at `0x60`.
Damage schools come from the item template. Armor, reborn armor, six resistances, block, random property,
required level and sell price occupy `0x78` through `0xA4`. The `0x08` base-item field follows the recovered
client's `CacheRecord` builder; its broader meaning in original server replies remains unconfirmed.

Captured rows take precedence over estimates by default. The original server's row-selection rules have
not been captured; lookup supplies the existing fixed item lifts and explicit item-stat requests.
It does not implement continuous scaling of equipped items with player level, change lift selection,
apply reborn armor to combat, or set player addon field 87. Enabling field 87 would make the client choose
additional player-level scaling rows before the server has matching equip and level-change behavior.

Verify through `python -B tools/verify_all.py --stages source,build,harness --harness captured_item_stats
item_scaling extension_packets --base origin/main`. The harness exercises the production startup hooks,
template builder and query handler with the real `ItemTemplate` and `WorldPacket`, plus captured rows and
malformed input. When verification settings select a DBC directory containing `ItemStat.dbc`, it also
validates the complete original table. Server build and gameplay verification require the normal CoA
prerequisites.
