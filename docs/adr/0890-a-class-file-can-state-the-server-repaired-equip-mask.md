# 0890. A class file can state the server-repaired equip mask of a spell

- Status: accepted
- Date: 2026-11-16

## Context

Tormentor rank 6 501349 (Witch Hunter claim 309.0) has `EquippedItemClass` 2, `EquippedItemSubClassMask` 262156
(bow, gun, crossbow) and `EquippedItemInventoryTypeMask` 4194304 (bit 22 only) in the server DBC set. The server
repairs that mask at load: `RepairedRangedInventoryMask` (`src/server/coa/AscensionClassMechanics.cpp:1006-1019`) adds
`INVTYPE_RANGED` 15 and `INVTYPE_RANGEDRIGHT` 26 to a weapon mask whose subclasses are ranged only, for every spell of
`SpellFamilyName` 18 to 38 (`:1225-1227`; 501349 is 21). `profile.unfit_reason` read the raw DBC mask, so the
Boltslinger crossbow 15809 (inventory type 26) was refused and `501349 hit_mean` and `501349 effect_value #1` read
`unmodelled: EquippedItemInventoryTypeMask 4194304 excludes the reference weapon inventory type 26` (final17 pair
161010 / 163550). The same pair cast 501349 with 15809 worn in `value-501349` (`effect_value e2 #0`, 178 reads, and
`aura_duration_ms #2` ok in both runs).

## Options

- Reproduce the server repair in `profile.py` for every class: it changes which entries are modelled in every class
  and can move finished-class digests.
- Add an off-hand ranged item to the weapon set (mentor D-192): no item of inventory type 22 with a ranged subclass
  exists in the world data.
- An opt-in per-spell class-file field holding the effective mask and the server source of the repair (mentor D-309).

## Decision

A class file may hold `server_inventory_masks` {rank id: {`mask`, `source`}}. `profile.server_requirement` replaces
the rank's `EquippedItemInventoryTypeMask` with `mask` wherever the tool reads a weapon requirement:
`values.equip_requirement` and `values.weapon_requirement` (with the class file), so `armed_for`, `rank_hit`,
`script_normalized_value_model` and `weapon_note`, and `compare.read_tokens`. `check_server_inventory_masks` (run by
`class_file_among`) refuses an entry without a non-blank `source`, with another field, or with a mask that is not a
positive integer; `server_requirement` refuses a mask that drops a bit of the DBC mask. A rank without an entry, and a
class file without the field, keep the raw DBC mask.

## Consequences

- Witch Hunter: `501349` = 4194304 | 1 << 15 | 1 << 26 = 71335936, with the server source in the entry. Its two
  labels now stop at the next gate, `effects of several hit models: ['periodic_damage', 'school']` (the tooltip states
  a direct Twilight hit and a periodic total): a separate tool line, not part of this decision.
- Tests: `ServerInventoryMaskCheckTest` and `ServerInventoryMaskDataTest` (`test_profile.py`); the mutant mask without
  bit 26 keeps the mask reason, so the label stays unmodelled.
- Class 15 regenerates byte-identical scenarios; only the two manifest rules change. Templar and Necromancer digests
  are unchanged (source stage snapshot check).
- Number provisional (guide 14.4).
