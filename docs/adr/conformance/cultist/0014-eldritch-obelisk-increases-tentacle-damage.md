# 0014. Eldritch Obelisk increases Tentacle damage by 100%

- Status: accepted (owner ruling O-15 Q-cu-29, 2026-11-25)
- Date: 2026-11-25

## Context

Eldritch Obelisk 560321 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Create an Eldritch Obelisk
beneath you for `$560322d`, increasing the damage of your Tentacles by `$560322s1%` and the movement speed of allies by
`$560322s3%` while near it."

Effective `Spell.dbc` data (no pending SQL overrides for 560321 or 560322):

- `560321` triggers `560322` (`DurationIndex` 18 = `20000 ms`).
- `560322` `Effect[0]`: `SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS` (190), `SPELL_AURA_MOD_DAMAGE_PERCENT_DONE` (79),
  `BasePoints` 99 + `DieSides` 1 (`+100%`), `MiscValue` 127 (all schools), `RadiusIndex` 12 (`100 yd`), `TargetA` = 1
  (`TARGET_UNIT_CASTER`). `SpellFamilyFlags = [0, 65536, 0]`, matched by Twilight Domination `520405` `Effect[0]`
  (`SPELLMOD_ALL_EFFECTS` `+25%` -> `+125%`).
- `560322` `Effect[2]`: `SPELL_EFFECT_PERSISTENT_AREA_AURA` (27), `SPELL_AURA_MOD_INCREASE_SPEED` (31), `+40%` within
  `15 yd` (`RadiusIndex` 18).

Before this fix, conformance pairs `prove-part-b1b` and `prove-part-b1c` (build `89d8bfc1fc05`, server `c81a74761fd4`)
measured `560321 behaviour_hit_ratio tentacle_damage` at `107` treatment vs `107` control over 40 non-crit hits of
Tentacle of Y'shaarj (`50096`) slam (`802046`) — a `+0%` bonus against the stated `+100%` (band `[95%, 105%]`).

Root cause:

1. `AscensionCultistSummons.cpp:39-45` summons Old God Tentacles (`50096`, `50272`, `501464`, `500465`) with
   `SummonProperties` 63 (`SUMMON_TYPE_TOTEM`), setting `UNIT_MASK_TOTEM` (`Object.cpp:2274-2277`).
2. `560322` `Effect[0]` (190) creates a `UnitAura` owned by the Cultist (`player->GetOwnedAura(560322)`) that copies
   `Effect[0]` only to `owner->m_Controlled` summons (`SpellAuras.cpp:2975-2994`, refreshed every
   `UPDATE_TARGET_MAP_INTERVAL = 500 ms`), never to the owner.
3. For Totems, `Unit::SpellDamageBonusDone` (`Unit.cpp:9798-9804`) and `Unit::SpellPctDamageModsDone`
   (`Unit.cpp:9366-9372`) delegate to `owner`, reading the owner's percent-damage auras instead of the Totem's, so
   `560322` on the Totem is ignored. In addition, `50096` fires its summon slam at `+100 ms`
   (`AscensionCultistSummons.cpp:156`), before the 500 ms `UpdateTargetMap` interval, and Tentacle of N'Zoth / Presence
   of N'Zoth apply `Thoughtseize` (`806596`) via `player->AddAura` (`AscensionCultistSummons.cpp:305`).

Live combat-log search (`ev2.md`): 0 events for `560321`/`560322` across 186 logs; video archive (`q742IyqxrV0.csv`
10:00) matches the tooltip verbatim. The project owner ruled (`O-15` `Q-cu-29`, 2026-11-25): apply the `+100%` bonus.

## Options

- Dummy `560322` `Effect[0].ApplyAuraName` (`dummy(0)`) in `AscensionCultist::ApplyContracts` while keeping
  `Effect[0].Effect = 190`, and apply the `Effect[0]` bonus of `player->GetOwnedAura(560322, player->GetGUID())` to
  Cultist Tentacles (and `Thoughtseize` `806596`) inside `cultist_scaling::Factor`.
- Edit `Unit::SpellDamageBonusDone` / `Unit::SpellPctDamageModsDone` to read Totem auras. Rejected: touches shared
  engine code (`src/server/game/`), affects Shaman totems and other classes, and would still miss the `+100 ms` summon
  slam (`500 ms` `UpdateTargetMap` delay) and player-owned `Thoughtseize` (`806596`).
- Change Old God Tentacles from `SummonProperties` 63 to 61. Rejected: breaks the shared one-per-slot Totem bar
  contract (`Totem.cpp:62-73`) and `max_one` / `replaces_*` behaviour.

## Decision

In `src/server/coa/AscensionCultistContracts.cpp`:

1. `ApplyContracts` calls `dummy(0)` for spell `560322`, converting `Effect[0]` from `SPELL_AURA_MOD_DAMAGE_PERCENT_DONE`
   to `SPELL_AURA_DUMMY` while preserving `Effect[0].Effect = 190`, its `BasePoints`/`DieSides` (`+100%`, scaling to
   `+125%` under Twilight Domination `520405`), its `100 yd` radius, and `Effect[2]` (`+40%` ally speed).
2. `cultist_scaling::Factor` checks `player->GetOwnedAura(560322, player->GetGUID())` `EFFECT_0` for non-healing damage
   dealt by owned Cultist Tentacles (`50272`, `501464`, `500465`, `50096`, `500464`) within `Radius(560322, 0)` (`100 yd`)
   and for `Thoughtseize` (`806596`), multiplying `factor` by `1 + bonus->GetAmount() / 100.0f`.

No shared engine file, DBC, SQL, or client text changes.

## Consequences

- Eldritch Obelisk increases damage dealt by Cultist Tentacles by `+100%` (`+125%` with Twilight Domination `520405`),
  including on the immediate `+100 ms` Tentacle of Y'shaarj summon slam and on `Thoughtseize` ticks.
- Dummying `Effect[0].ApplyAuraName` prevents Guardian `500464` from double-counting aura 79 and prevents non-Tentacle
  summons (`397771` Manifestation of Y'shaarj, `533030` Void Portal) from receiving a Tentacle-only bonus, while
  preserving `560322` aura presence on owned summons (verified by catalog scenario `cultist-eldritch-obelisk.json`).
- No other class is reached (`Owner(caster)` requires `CLASS_CULTIST`, `SpellFamilyName == 31`, keyed to `560322`).
- Regressions (`prove-A`, runs `20261125-090708` and `20261125-090740`, build `e6fddac7d0eb`, 13/13 ok, 0 flips):
  - `560321 behaviour_hit_ratio tentacle_damage`: `214` vs `107` over 40 hits per arm (`+100.0%` exact, both runs),
  - `560321 duration` (`1` at `18509 ms`, `0` at `21518 ms`, both runs),
  - `560321 ally_speed` (`1.0 -> 1.4` at 10 yd, `1.0 -> 1.0` at 20 yd, both runs),
  - Reached spells unchanged: `802044` (7/7 ok), `802048` (`+20.56%`, ok/ok), `706187` (2/2 ok).
- Ledger row `560321` (`"increasing the damage of your Tentacles by $560322s1%"`) updated from `560321 effect_value 560322e0 #1`
  to `560321 behaviour_hit_ratio tentacle_damage`.
