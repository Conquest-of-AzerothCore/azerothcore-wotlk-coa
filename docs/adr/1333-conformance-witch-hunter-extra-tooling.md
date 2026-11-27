# 1333. Conformance tooling for Witch Hunter extra spells

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-27
- Rulings: Witch Hunter (class 15) extra-spell catch-up (`503679`, `562225`, `574343`, `578118`, `680230`, `680263`, `802281`, `804667`)

## Context

Catching up Witch Hunter's baseline and taught `extra_spells` (class 15, per ADR 1327) surfaced six conformance tooling
gaps that cannot be expressed cleanly without extending the shared tooling and harness:

1. **Repeated identical conditional prefix (`574343` *Dawn Blade*)**: `Description[enUS]` contains
   `$?s92094$?s92094[...][]`, which `tooltip.py` rejected because `SINGLE_CONDITION` matched only one `sN` atom.
2. **Permanent `$d` token (`802281` *Infiltrate*)**: `DurationIndex = 21` (`Duration = -1`, `MaxDuration = -1`,
   `DurationPerLevel = 0`) caused `tooltip.py` to emit `$d` as unreadable, and `802281`'s `2000 ms` cast time would
   also block an `aura_duration_ms` read in `values.py`.
3. **Ground-targeted hostile `PERSISTENT_AREA_AURA` (`503679` *Caltrops*)**: `503679` has `Effect[0] = 27`
   (`PERSISTENT_AREA_AURA`), `TargetA = 87` (`TARGET_DEST_DEST`), and `Speed = 40.0`. `value_reagents` only accepted
   `destination_unit = 'caster'`, so `values.py` spawned no dummy, did not wait for missile travel, and read the
   hostile area aura on `caster` instead of `dummy`.
4. **Tokenless `"Weapon Damage"` hits (`574343` *Dawn Blade* and `680230` *Saber Slash (Fire)*)**:
   - `574343` combines `Effect[0] = SCHOOL_DAMAGE` with `Effect[1] = NORMALIZED_WEAPON_DMG` and prose `"Weapon Damage
     plus ${$m1+0+$spfi*0.15+$AP*0.15}"`, so `hits.py` dropped `Effect[1]` and modelled only the school part.
   - `680230` has `Effect[0] = NORMALIZED_WEAPON_DMG` and prose `"Slashes an enemy for Weapon Damage"` with no `$`
     token on `Effect[0]`, causing `weapon_hit` to raise `Unmodelled`.
5. **Pet lifecycle behaviours (`578118` *Call From The Shadows*, `680263` *Dismiss Hound*)**: `CoAGameplayTest.cpp`
   already provides `pet_entry`, `pet_health`, and `set_health {"pet": true}`, but conformance had no `pet_dismiss` or
   `pet_resurrect` behaviour kinds.
6. **Reaction, ground-destination, dungeon-location, and missing `STATE` metrics (`802281` *Infiltrate*, `562225`
   *Night Hunter*, `804667` *Charming Conversation*, `503679` *Caltrops*)**:
   - `CoAGameplayTest.cpp` lacked a read-only `reaction_to` metric (`Unit::GetReactionTo(target)`) to contrast hostile
     vs friendly NPC reactions under `802281`.
   - `metric_delta` lacked options for trigger `destination_unit`, top-level `location` (for dungeon-map refusal), and
     a secondary `bystander` creature with explicit faction (for friendly-NPC preservation alongside a hostile target).
   - `coverage.py` lacked `METRIC_EVIDENCE` / `STATE_PROMISES` rows for `stealth_detection`, `reputation_gain`,
     `pet_entry`, `pet_health`, and `reaction_to`, and its `display_id` / `display_of_creature` regexes did not match
     `"Take on the form"`.

## Options

- Broaden `weapon_hit` unconditionally for tokenless `"Weapon Damage"` effects: rejected, because existing finished
  class files include unmodelled spells (`802258` *Dusk Blade*, `680615` *Noctis Blade*) whose snapshots would drift.
- Keep all new hit and value behaviours opt-in or strictly scoped (repeated identical `$?sN$?sN`, permanent
  `Duration = -1`, `destination_unit = 'dummy'` in `value_reagents`, `weapon_school_hits` normalized fallback,
  opt-in `plain_weapon_hits`, new `kinds/` and `metric_delta_options/` modules, and one read-only `reaction_to` metric
  in `CoAGameplayTest.cpp`). Chosen.

## Decision

1. **`apps/coa-gameplay-test/conformance/tooltip.py`**:
   - Widen `SINGLE_CONDITION` to `r'[sS](\d+)(?:\$\?[sS]\1)*'` so repeated identical `$?sN$?sN` prefixes parse cleanly
     while mismatched or composite operators stay unreadable.
   - Add `Records.is_permanent_duration` and return `PERMANENT_DURATION_MS` (`-1.0`) for `$d`/`$D` when
     `DurationIndex != 0`, `DurationPerLevel == 0`, and `Duration == MaxDuration == -1`.
2. **`apps/coa-gameplay-test/conformance/values.py`**:
   - Map permanent own `$d` (`-1.0`) to a `spell_duration_ms` read (`spell_duration` check against `-1`), bypassing the
     `cast_time_ms` live-aura restriction.
   - Extend `value_reagents` `destination_unit` to allow `'dummy'`: spawn the dummy at `cast_distance`, include
     `missile_wait_ms`, and route `PERSISTENT_AREA_AURA (27)` aura reads to `dummy`.
3. **`apps/coa-gameplay-test/conformance/hits.py`**:
   - Add `plain_school_weapon_part` under opt-in `weapon_school_hits` for `SCHOOL_DAMAGE` + `NORMALIZED_WEAPON_DMG`
     spells whose tooltip states `"Weapon Damage"` without a weapon token (`574343`).
   - Add opt-in `plain_weapon_hits` for single-effect flat weapon spells whose tooltip states plain `"Weapon Damage"`
     without a token (`680230`).
4. **`apps/coa-gameplay-test/conformance/coverage.py`**:
   - Register `stealth_detection`, `reputation_gain`, `pet_entry`, `pet_health`, and `reaction_to` as `STATE` metrics
     with matching `STATE_PROMISES`, and widen `display_id` / `display_of_creature` promises to match `"form"`.
5. **New `metric_delta_options/` and `kinds/` modules**:
   - `metric_delta_options/destination_unit.py` (`ORDER = 46`), `location.py` (`ORDER = 47`), and `bystander.py`
     (`ORDER = 48`).
   - `kinds/pet_dismiss.py` (`ORDER = 66`) and `kinds/pet_resurrect.py` (`ORDER = 67`).
6. **`src/server/coa/CoAGameplayTest.cpp`**:
   - Add read-only metric `reaction_to` returning `double(unit->GetReactionTo(GetUnit(step.get<std::string>("target"))))`.

## Consequences

- Zero drift across all seven committed finished-class snapshots (`13, 14, 15, 19, 23, 25, 27`).
- Every new module and parser/model path is covered by dedicated unit tests in `test_tooltip.py`, `test_values.py`,
  `test_hits.py`, `test_coverage.py`, `kinds/test_pet_{dismiss,resurrect}.py`, and
  `metric_delta_options/test_{destination_unit,location,bystander}.py`.
- Reusable across other classes with pet dismiss/resurrect spells, ground-targeted hostile `PERSISTENT_AREA_AURA`
  spells, plain `"Weapon Damage"` strikes, or faction-reaction disguise/neutrality effects.
