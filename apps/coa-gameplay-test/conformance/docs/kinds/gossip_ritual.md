# Gossip ritual (`behaviour_metric_delta`, `kind: "gossip_ritual"`, ADR 1329, provisional)

ADR 1329 has a provisional number and is renumbered at merge (guide 14.4).

Proves a multi-player gossip-activated ritual creature end to end: `caster` casts `spell` (with optional reagent and
`destination_unit: "caster"` when `Spell.dbc` requires a destination target) to summon a gossip-interactable ritual
stone creature (`stone_entry`), activates it via `gossip_hello` to verify the channel aura (`channel_aura`) and health
drain (`hp_after_drain < pre_hp`) while no ritual summon has appeared yet, then has the remaining `channelers - 1`
grouped allies activate the stone via `gossip_hello` to verify that the stone is destroyed (`0`) and the ritual summon
(`summon_entry`) spawns (`nearby_creature_count == 1`). Zero harness C++ changes: reuses `group`, `add_item`, `cast`
(`destination_unit`), `gossip_hello`, `owned_creature_count`, `nearby_creature_count`, `aura`, `health`, and
`cast_failure`.

## Scenario and judgement

- **Players and schema:** `channelers` (`2..25`) grouped same-class players (`caster`, `ally1..ally{N-1}`) with
  `allow_regeneration: false` so out-of-combat health regeneration cannot mask life-force drain ticks. Uses `schema: 2`
  when `channelers > 8` (up to 25 players) and `schema: 1` otherwise. `group` converts the party to a raid
  automatically once it exceeds 5 members.
- **Pre-cast control:** Reads `owned_gameobject_count`-style `owned_creature_count(stone_entry) == 0`,
  `nearby_creature_count(summon_entry) == 0`, channel aura (`0`), and `health > 0` on `caster`. Dirty baselines return
  `unmeasured`.
- **Stage 1 (stone spawn):** Grants optional `reagent_item` (`reagent_count`, default `1`), sets optional `cast_power`,
  casts `spell` (adding `destination_unit: "caster"` when `Spell.dbc` uses `TARGET_DEST_DEST` /
  `TARGET_FLAG_DEST_LOCATION`), checks `cast_failure == 0`, waits `spawn_wait_ms` (default `1000`), and reads
  `owned_creature_count(stone_entry) == 1`.
- **Stage 2 (channel and drain):** `caster` runs `gossip_hello(entry: stone_entry)`, waits `drain_wait_ms` (default
  `2500`), then reads channel aura (`== 1`, measured on `stone_entry` via `owned_creature_count(entry, spell, caster)`
  for target-directed channels such as `800965`, or `aura` on `caster` for `TARGET_UNIT_CASTER` channels), `health` on
  `caster` (`< pre_hp`), and intermediate control `nearby_creature_count(summon_entry) == 0`.
- **Stage 3 (completion):** `ally1..ally{N-1}` each run `gossip_hello(entry: stone_entry)`, waits `complete_wait_ms`
  (default `2500`), then reads `owned_creature_count(stone_entry) == 0` (stone destroyed) and
  `nearby_creature_count(summon_entry) == 1` (unowned hostile summon present).
- **Chronological milestone judging:** Each stage is checked before requiring later measurements, so a broken stone
  spawn that aborts a subsequent `gossip_hello` alerts on the failing stage rather than falling back to `unmeasured`.
- **Evidence class:** `metric: "nearby_creature_count"`, exported as `EVENT` in `METRIC_EVIDENCE` (counted as
  `behaviour`).

Cultist: Eldritch Ritual `804777` (`stone_entry: 50298`, `channel_aura: 800965`, `summon_entry: 50263`,
`channelers: 10`, `reagent_item: 1210`).
