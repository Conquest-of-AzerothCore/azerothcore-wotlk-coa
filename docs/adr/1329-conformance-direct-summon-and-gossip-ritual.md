# 1329. 1-stage `summon_ritual` mode and `gossip_ritual` kind for Cultist rituals

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-27
- Rulings: Cultist (class 25) extra-spell catch-up (`1200011` *Summoning Obelisk* and `804777` *Eldritch Ritual*)

## Context

Catching up Cultist's server-granted `extra_spells` (class 25, per ADR 1327) surfaced two multi-player ritual shapes
not yet modelled by existing conformance kinds:

1. **1-stage direct summoning ritual (`1200011` *Summoning Obelisk*)**: unlike Bloodmage's 2-stage *Blood Covenant*
   (`1200012`, ADR 1326), where two allies carve a stone (`194114`) before opening a meeting-stone portal (`179944`),
   *Summoning Obelisk* places a single summoning-ritual gameobject (`194110`) after the caster selects the distant party
   member; one grouped ally clicking `194110` directly leaves the distant target with `summon_pending == 1`.
2. **Multi-player gossip-activated ritual creature (`804777` *Eldritch Ritual*)**: casting `804777` (`TARGET_DEST_DEST`,
   reagent `1210` Shadowgem) summons an owned gossip creature (`50298`, Ritual Stone). Each grouped raid member who
   activates `50298` via `gossip_hello` channels `800965` (*Ritual Beam*, `TARGET_UNIT_TARGET_ANY` with
   `SPELL_ATTR3_DOT_STACKING_RULE`, placing each channeler's aura instance on `50298`) while `npc_ascension_cultist_summon`
   drains 1% of each channeler's maximum health per second (`AscensionCultistSummons.cpp:315-352`). Once 10 grouped
   allies channel simultaneously, `50298` despawns and spawns an unowned hostile Faceless Destroyer (`50263`, summoned
   with `summoner = nullptr` at `AscensionCultistSummons.cpp:50-52`, therefore measured via `nearby_creature_count`
   rather than `owned_creature_count`).

## Options

- Duplicate `summon_ritual.py` into a separate `direct_summon_ritual.py` kind: rejected, because both share the same
  `summon_pending` evidence, location validation, baseline guards, and chronological milestone judging; making
  `stone_entry` and `portal_entry` jointly optional preserves byte-identical output for 2-stage rituals while avoiding
  duplication.
- Extend `kinds/summon_ritual.py` with an opt-in 1-stage direct mode (`stone_entry` and `portal_entry` both omitted or
  `None`) and add reusable `kinds/gossip_ritual.py` (`ORDER = 65`) with `schema: 2` support when `channelers > 8`.
  Chosen.

## Decision

1. **Extend `apps/coa-gameplay-test/conformance/kinds/summon_ritual.py`**
   ([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/summon_ritual.md)):
   - Allow `stone_entry` and `portal_entry` to both be omitted (`None`); reject mixed specs where only one is set.
   - Keep the 2-stage path 100% byte-identical whenever both `stone_entry` and `portal_entry` are present.
   - In 1-stage direct mode, spawn three grouped players (`caster`, `first`, `faraway`), teleport `faraway` to
     `faraway_location`, verify clean `0` baselines (`pre_ritual`, `pre_summon`), have `caster` select `faraway` and
     cast `spell` (with optional `cast_power`), verify `cast_failure == 0`, `ritual_created == 1`, and premature
     control `summon_before_click == 0`, then have `first` click `ritual_entry` and verify `summon_final == 1`.
2. **Add `apps/coa-gameplay-test/conformance/kinds/gossip_ritual.py`** (`ORDER = 65`,
   [doc](../../apps/coa-gameplay-test/conformance/docs/kinds/gossip_ritual.md)):
   - Spawn `channelers` (`2..25`) grouped same-class players (`caster`, `ally1..ally{N-1}`) with
     `allow_regeneration: false` so out-of-combat health regeneration cannot mask life-force drain, selecting
     `schema: 2` whenever `channelers > 8` (25-player cap) and `schema: 1` otherwise.
   - Grant optional `reagent_item` (`reagent_count`, default `1`) via `add_item` and optional `cast_power`, then cast
     `spell` with `destination_unit: "caster"` whenever `Spell.dbc` requires a destination (`TARGET_DEST_DEST` /
     `TARGET_FLAG_DEST_LOCATION`).
   - Verify clean baselines (`pre_stone == 0`, `pre_summon == 0`, `pre_aura == 0`, `pre_hp > 0`), stone spawn
     (`cast_failure == 0`, `owned_creature_count(stone_entry) == 1`), single-channeler drain (`gossip_hello` by
     `caster`, channel aura `== 1` via `owned_creature_count(entry, spell, caster)` for target-directed channels or
     `aura` for `TARGET_UNIT_CASTER` channels, `hp_after_drain < pre_hp`, premature `summon_before_full == 0`), and
     completion (`gossip_hello` by `ally1..ally{N-1}`, `stone_after_complete == 0`,
     `nearby_creature_count(summon_entry) == 1`).
   - Export `METRIC_EVIDENCE = {'nearby_creature_count': 'event'}` (matching `kinds/corpse_per_raise.py`) so verdicts
     count as `behaviour` evidence in `coverage.py`.
3. **Add opt-in `value_reagents` to `apps/coa-gameplay-test/conformance/values.py`**:
   - Allow a class file to declare `value_reagents` entries (`{"spell", "items": [[item_id, count], ...], "destination_unit": "caster"}`) so `value_scenario` grants required reagents and sets `destination_unit` before casting spells like `804777` (*Eldritch Ritual*) to measure `cooldown_ms`. Omitting the key preserves 100% byte-identical output for all other classes.
4. **Extend `trigger_with_value` in `apps/coa-gameplay-test/conformance/compare.py` to `Effect == 142` (`SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE`)**:
   - Mirror `PERIODIC_TRIGGER_SPELL_WITH_VALUE` (`227`, D-292) for `SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE` (`142`, `SpellEffects.cpp:1862-1868`), which hands `CalcValue` (fixed or rolled) directly as `BASE_POINT0` to its triggered spell while the triggered spell carries the SP/AP scaling (e.g., *Gaze of C'Thun* `500110`/`502135..502143` -> `520334` -> `520332`). When the carrier itself has no `spell_bonus_data` / coefficient entry and its tooltip includes a power term, `judge_roll` and `judge_trigger_with_value` judge `CalcValue` against the unpowered tooltip range while the triggered spell's behaviour checks prove the power terms.

## Consequences

- Zero SQL edits and zero diff on all six other finished class snapshots.
- One small harness cleanup fix in `src/server/coa/CoAGameplayTest.cpp` (`RemoveFixtureDescendants`): when a lane runs in a private phase (`_phase > PHASEMASK_NORMAL`), `Dismiss()` also despawns unowned `TempSummon` creatures in that exact `_phase` so hostile unowned ritual spawns (e.g. `50263` *Faceless Destroyer*) cannot linger into subsequent scenarios on the same lane.
- Reusable for any 1-stage summoning ritual, any multi-player gossip-activated ritual creature up to 25 players, reagent/destination `value_scenario` casts, and rolled `SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE` carriers.
- Unit tests in `kinds/test_summon_ritual.py`, `kinds/test_gossip_ritual.py`, `test_values.py`, and `test_compare.py` cover schema validation, both modes, `EVENT` evidence classification, per-stage mutants (including truncated runs), baseline guards, `value_reagents`, `Effect == 142` carrier roll judging, and input refusals.
