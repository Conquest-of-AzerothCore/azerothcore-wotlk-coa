# Scaffolding a class file

`scaffold.py` writes a minimal `classes/<name>.json` for any CoA class (12-32) from data, so a new class starts
from a generated file instead of ~150 hand-written entries. `conformance.py scaffold --class N --out FILE --config
WORLDSERVER_CONF --mysql MYSQL [--dbc-dir DIR] [--level N] [--shared-defines HEADER] [--live-baseline HEADER]`
fills every mandatory field of
[Reference character](reference-character.md#reference-character) plus `skill_lines`, leaves every optional coverage field (`procs`,
`triggers`, `behaviours`, `extra_spells`, the override lists, …) empty, and leaves `reference_stats` empty: no
coverage field is mechanically derivable (`scale-out-sweep.md`'s own finding), and the reference stats need a
gameplay measurement (below), not a lookup.

- `name`: the `// TITLE` comment of the class's `CLASS_*` enumerator in `SharedDefines.h` (`class_title`).
- `race`: the lowest `race` of `WORLDSERVER_CONF`'s `WorldDatabaseInfo` database's `playercreateinfo` rows for the
  class (`lowest_race`, `playercreateinfo_sql`) — a choice, not a derivation; Templar's own file also picked race 1,
  the lowest allowed race for every CoA class on this server's current `playercreateinfo` table.
- `weapon`/`alternate_weapons`: `AscensionLiveBaselineData.h`'s `Proficiencies` rows for the class
  (`class_proficiencies`), resolved to an item subclass through `tooltip.weapon_skill_spells` (`select_weapon_rows`):
  the lowest `SkillId` row that resolves a subclass is `weapon`, the next row with a *different* subclass (if any)
  is `alternate_weapons[0]`. For each, the `item_template` row of that subclass with `Quality` 1, `ItemLevel > 0`,
  no stat (`stat_type1`..`10` all 0) and no proc (`spellid_1`..`5` all 0), lowest `ItemLevel` then `entry`
  (`item_candidate_sql`), gives `min_damage`/`max_damage`/`speed_ms`/`inventory_type`; `normalized_speed` is the
  fixed `Unit::GetAPMultiplier` table (3.3 two-hand, 2.8 ranged/thrown, 1.7 one-hand dagger, 2.4 one-hand otherwise;
  `normalized_speed`). `skill_lines` is `classes.class_skill_lines` of the class's spells and the chosen `weapon`.
  `ratings` is the fixed fixture of [Reference character](reference-character.md#reference-character) (hit/expertise never desync a
  measurement); it is not class-specific.
- This weapon rule is a stated, unverified default (`scale-out-sweep.md` part 3): it need not match a prior
  hand choice. Scaffolding class 19 picks the lowest-`SkillId` Proficiencies row, a Sword (skill 43, subclass 7),
  not Templar's hand-picked Staff (skill 136, subclass 10); `skill_lines` differs the same way (`[43, 70, 71, 72]`
  vs. `[70, 71, 72, 136]`). `item_candidate_sql`'s `ItemLevel > 0` excludes the zero-level NPC reuse weapons found
  while building this (`axe_1h_murloc` 558847, `sword_2h_rayner_red` 558872: `ItemLevel` 0, otherwise a clean match),
  but not every `ItemLevel` 1 row: several subclasses still surface a `Monster - `/`Placeholder ` dev prop ahead of
  a real starter weapon (verified on `acore_world`, class 19 subclass 7 picks item 49340 "Monster - Icecrown - 1H
  Sword - D03 - Blue" over "Worn Shortsword" 25). No `item_template` column distinguishes these from real starter
  gear (checked `ScriptName`, `VerifiedBuild`, `bonding`, `RequiredLevel`, `SellPrice`/`BuyPrice`: none separates
  them cleanly), so this is left as a known, explained gap of the stated rule rather than a name-based heuristic.
  The item is still a valid equippable weapon with a positive `dmg_min1`/`dmg_max1`, so `base_steps` and `generate`
  are unaffected.

`reference_stats` needs one measurement, since `base_steps` (equip the weapon, set each skill line, read
`attack_power`, `ranged_attack_power`, `spell_power 1`..`6`, `stat 0`..`4`, `weapon_damage_min`) depends on a
running worldserver. This was previously undocumented as a repeatable step; `scaffold.py` adds it in two calls:

```sh
python3 -c "import json, scaffold; cf = json.load(open('FILE')); \
  json.dump(scaffold.naked_scenario(cf), open('NAKED.json', 'w'), indent=2)"
python -B ../../../tools/verify_all.py --stages gameplay --scenario NAKED.json
python3 -c "import json, scaffold; cf = json.load(open('FILE')); \
  result = json.load(open('.cache/verify-all/STAMP/gameplay/exploratory/<key>/result.json')); \
  cf['reference_stats'] = scaffold.reference_stats_from_result(result, cf); \
  json.dump(cf, open('FILE', 'w'), indent=2)"
```

`naked_scenario(class_file)` wraps `profile.base_steps`/`player_fixture` into a schema-1 scenario named after the
class; `reference_stats_from_result(result, class_file)` reads the run's `result.json` with `compare.measured_values`
and keeps only `attack_power`, `ranged_attack_power`, `spell_power 1`..`6`, `stat 0`..`4` and one `skill <line>` per
`skill_lines` entry present in the result — the same fields Templar's own `reference_stats` holds, never
`weapon_damage_min` or an aura label. Run for class 19 on 2026-11-09 (stamp `20261109-140931`): `attack_power` 313,
`ranged_attack_power` 182, `stat 0`..`4` 81/132/79/32/50, `spell_power 1`..`6` all 0 — identical to Templar's own
measured values (the character's race/class/level are the same; only the weapon and its skill line differ), with
`skill 43` 300 in place of `skill 136` 300. `conformance.py generate --class 19` ran against this scaffolded file
(classes dir redirected to isolate it from `classes/templar.json`) without error: 298 scenarios (221 value, 145
passive, 33 hit, 1 melee), 102 entries without a scenario — the value/hit/passive/melee categories `scale-out-sweep.md`
expects from the mandatory fields alone, and none of the proc/trigger/behaviour/stack categories the scaffold
leaves empty.
