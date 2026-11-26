# 0015. Twilight Domination reduces Eldritch Obelisk cooldown by 2 sec per Tentacle hit

- Status: accepted (owner ruling O-15 Q-cu-30, 2026-11-25)
- Date: 2026-11-25

## Context

Twilight Domination 520405 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Damage dealt by your
Tentacles reduces the cooldown of Eldritch Obelisk by `$/1000;520872s1` sec. In addition, increases the effectiveness of
Eldritch Obelisk by `$s1%`."

Effective `Spell.dbc` and `pending_db_world` data:

- `520405` `Effect[0]`: `SPELL_AURA_ADD_PCT_MODIFIER` (108), `SPELLMOD_ALL_EFFECTS` `+25%` on mask `[0, 65536, 0]`
  (Eldritch Obelisk `560321`/`560322`).
- `520405` `Effect[1]`: `SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS` (190), `SPELL_AURA_PROC_TRIGGER_SPELL` (42,
  rewritten to `SPELL_AURA_DUMMY` by `AscensionCultistContracts.cpp:38-48`), `TriggerSpell = 520872`.
- `520872` `Effect[0]`: `SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN` (165), `BasePoints = -2001`, `DieSides = 1`
  (`-2000 ms`, `$/1000;520872s1` = `2 sec`), `MiscValue = 560321`.
- `560321` (Eldritch Obelisk): `RecoveryTime = 180000 ms`.
- `rev_20260909_12_cultist_completion.sql:18,198-199` registers `spell_proc` and `aura_ascension_cultist_event` on `520405`.

Before this fix, conformance pair `prove-part-b2` (build `89d8bfc1fc05`, server `c81a74761fd4`) measured
`520405 behaviour_metric_delta obelisk_cd` at `175988 ms` before and `175988 ms` after learning `520405` (gain `0 ms`
vs `-2000 +- 300 ms`), while `ally_arm` confirmed 1 Tentacle of Y'shaarj (`50096`) slam hit per phase.

Two bugs in CoA Cultist code caused the failure:

1. `AscensionCultistEvents.cpp:188` (`aura_ascension_cultist_event::Proc`, since initial commit `e36bc50aad`) called
   `Reduce(player, 560322, std::abs(Amount(520872)))`, passing `560322` (the Obelisk's triggered aura spell, absent from
   `player->GetSpellMap()` and not in `560321`'s rank chain) instead of `560321` (Eldritch Obelisk).
2. `520405` `Effect[1]` (190) copies the aura to controlled summons only on `Aura::UpdateTargetMap` every
   `UPDATE_TARGET_MAP_INTERVAL = 500 ms` (`SpellAuras.cpp:46,545,746`), whereas Tentacle of Y'shaarj (`50096`) fires
   its summon slam at `+100 ms` (`AscensionCultistSummons.cpp:156,314-318`), before `520405` has been applied to
   `50096`. Thus `aura_ascension_cultist_event::Check` did not fire on the summon slam at all.

Live combat-log search (`ev2.md`): 0 events for `520405`/`520872`/`560321` in 186 logs; video archive (`q742IyqxrV0.csv`
10:06) matches the tooltip verbatim. The project owner ruled (`O-15` `Q-cu-30`, 2026-11-25): fix the cooldown reduction.

## Options

- Handle creature-attributed Tentacle damage synchronously in `cultist_summon_damage::OnDamage`
  (`AscensionCultistSummons.cpp`, alongside Twisted Sanity `706187`) calling `Reduce(player, 560321, std::abs(Amount(520872)))`,
  and narrow `aura_ascension_cultist_event` `case 520405` (`AscensionCultistEvents.cpp`) to player-attributed
  `Thoughtseize` (`806596`) calling `Reduce(player, 560321, ...)`.
- Change only `560322` -> `560321` in `AscensionCultistEvents.cpp:188`. Rejected: leaves the 500 ms `UpdateTargetMap`
  race broken on every `+100 ms` Tentacle of Y'shaarj summon slam and leaves `Thoughtseize` (`806596`) uncovered.
- Keep `case 520405: return dealt && tentacle` alongside `cultist_summon_damage::OnDamage`. Rejected: would double-proc
  (`-4 s` per hit) once `UpdateTargetMap` copies `520405` onto a Tentacle after 500 ms.

## Decision

1. In `src/server/coa/AscensionCultistSummons.cpp` (`cultist_summon_damage::OnDamage`), when
   `Tentacle(creature->GetEntry()) && player->HasAura(520405)`, call `Reduce(player, 560321, std::abs(Amount(520872)))`.
2. In `src/server/coa/AscensionCultistEvents.cpp` (`aura_ascension_cultist_event`), narrow `case 520405:` in `Check` to
   `dealt && info && info->Id == Thoughtseize` (disjoint from creature-attributed hits in `cultist_summon_damage`), drop
   the now-unused `entry`/`tentacle` locals, and fix `Proc` line 188 from `560322` to `560321`.

`520405` stays in `CultistEvents` (`AscensionCultistData.h:129`) so `ApplyContracts:38-48` continues to dummy
`Effect[1]` while leaving `Effect[0]` (`+25%` effectiveness) intact. No shared engine, DBC, SQL, or client text changes.

## Consequences

- Every Tentacle damage hit (`50096` `802046`, `50272` `804999`, `573311` Eldritch Command, and `806596` Thoughtseize)
  reduces Eldritch Obelisk (`560321`) cooldown by `2000 ms` once, including immediate `+100 ms` summon slams and
  subsequent Gaze-commanded slams past the 500 ms `UpdateTargetMap` interval.
- No other class is reached. Reached Cultist spells (`560321`, `706187`, `520405` `obelisk_effectiveness`) were rerun
  in `prove-B` (`20261125-091156` / `20261125-091226`, build `51e7b949bb5a`) with 0 readings moved.
- Regressions (`cu-fix41-rfix-primary`, runs `20261125-095634` and `20261125-095706`, build `9c723b19bf36`, 21/21 ok,
  0 flips; converted from `cooldown_ms` readbacks to behaviour-classed `cast_failure` + `after_trigger_casts`
  brackets matching Cultist `680579` / `300280`):
  - `520405 obelisk_cd`: 1 slam (`50096`, `1 -> 2` cumulative), re-cast `560321` at `178.3 s` refused (`67`) in control
    and succeeds (`0`, `spell_cast_count 1 -> 3`) in treatment (ok/ok),
  - `520405 obelisk_cd_held`: 1 slam, re-cast `560321` at `177.7 s` refused (`67`) in both phases, ruling out an
    over-cut `>= 2.3 s` (ok/ok),
  - `520405 obelisk_cd_gaze`: 2 slams across `3000 ms` (`> 500 ms` `UpdateTargetMap`), re-cast `560321` at `176.3 s`
    refused (`67`) in control and succeeds (`0`, `spell_cast_count 1 -> 3`) in treatment (ok/ok),
  - `520405 obelisk_cd_gaze_held`: 2 slams across `3000 ms`, re-cast `560321` at `175.5 s` refused (`67`) in both
    phases, ruling out a double-proc (`-6 s` -> `174.0 s`) after `UpdateTargetMap` (ok/ok),
  - `520405 obelisk_cd_thoughtseize`: Tentacle of N'Zoth (`572103`) delivers 4 `Thoughtseize` (`806596`) periodic ticks
    per phase (`4 -> 8` cumulative, `-8 s` -> `172.0 s`), re-cast `560321` at `172.5 s` refused (`67`) in control and
    succeeds (`0`, `spell_cast_count 1 -> 3`) in treatment, proving the player-attributed `AscensionCultistEvents.cpp:85,185`
    path at runtime (ok/ok),
  - `520405 obelisk_effectiveness`: `1.4 -> 1.5` (ok/ok).
- Ledger row `520405` (`"Damage dealt by your Tentacles reduces the cooldown of Eldritch Obelisk by $/1000;520872s1 sec."`)
  updated to the five cast-gate labels above; `cu-fix41-rfix-primary/fragment.json` audits row 141 as `behaviour`.
