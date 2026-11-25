# 0020. Owner ruling Q-cu-16: Twisted Seal deflects hostile melee abilities via Cultist-scoped hook

- Status: accepted (owner ruling Cultist Q-cu-16 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

Twisted Seal `525065` (server `Spell.dbc`, `Description[enUS]`): "Create a warped sigil that bends hostile force away from
you, deflecting all spells and abilities for $d, but making you unable to attack or cast spells. Casters whose magic is
deflected are silenced for $525066d." (`$d = 5000 ms`, `Effect[0]` aura `287` `SPELL_AURA_DEFLECT_SPELLS` `bp=99+1=100%`).
Its buff tooltip `ToolTip[enUS]` currently reads `"Deflecting spells. Enemies who get deflected are also silenced for $525066d."`
(the requested client-text change to `"Deflecting spells and abilities."` is queued separately outside server C++ fixes).

`Unit::MagicSpellHitResult` (`src/server/game/Entities/Unit/Unit.cpp:4094-4100`) checks `SPELL_AURA_DEFLECT_SPELLS` for
magic spells, but `Unit::MeleeSpellHitResult` (`src/server/game/Entities/Unit/Unit.cpp:3810-3823`) checks it only inside
`if (attType == RANGED_ATTACK)`. Hostile melee abilities (`SPELL_DAMAGE_CLASS_MELEE`, `BASE_ATTACK`/`OFF_ATTACK`) therefore
bypassed deflection completely.

Before measurement (`batch2/cu-rg8/review.md` Alert 1, `prove-p2c` `20261124-213031` / `20261124-213103`, build
`b6e563ae7771`): `525065 deflect_magic` (`16067`) deflected `20/20` (`ok`), whereas `525065 deflect_melee_ability`
(Night Slaughter `23583`, `DmgClass=2`, `Attributes=0x00200000` `SPELL_ATTR0_NO_ACTIVE_DEFENSE`) landed `10/10` before
and `10/10` under `525065` (gain `10` against expected `0 ± 1`: `alert`).

The owner ruled (Cultist `Q-cu-16` / `O-15`, 2026-11-25): implement a Cultist-scoped workaround without modifying shared
engine code (`Unit.cpp`).

## Options

- Intercept hostile `SPELL_DAMAGE_CLASS_MELEE` casts in `cultist_spells::OnSpellBeforeEffects`
  (`src/server/coa/AscensionCultistAbilities.cpp`, following the `PaviseDeflectFromBehind` pattern in
  `AscensionWitchHunterAbilities.cpp:289-306`): when a living Cultist target carries `525065`'s `SPELL_AURA_DEFLECT_SPELLS`
  aura and satisfies the front-arc and not-stunned checks of `Unit.cpp:3813,4094`, roll the aura's deflect chance and set
  `target.missCondition = SPELL_MISS_DEFLECT`. Chosen: strictly Cultist-scoped and touches no shared engine file.
- Extend `Unit::MeleeSpellHitResult` (`Unit.cpp:3810-3823`) to check `SPELL_AURA_DEFLECT_SPELLS` for melee attacks.
  Rejected by owner ruling `Q-cu-16` (shared engine path affecting other classes).

## Decision

In `src/server/coa/AscensionCultistAbilities.cpp`, add helper `DeflectMeleeAbility(Spell* spell, SpellInfo const* info)`
invoked at the top of `cultist_spells::OnSpellBeforeEffects`. It exits immediately unless
`info && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE && !info->IsPositive() && !info->HasAttribute(SPELL_ATTR3_ALWAYS_HIT)`.
(Note: `SPELL_ATTR0_NO_ACTIVE_DEFENSE` disables physical dodge/parry/block, not deflection; Night Slaughter `23583` carries
that flag and must still be deflected.) For each hostile target in `*spell->GetUniqueTargetInfo()` whose
`missCondition == SPELL_MISS_NONE` and who is a living Cultist (`Owner(victim) == victim`) facing the attacker (or carrying
`HasIgnoreHitDirectionAura()`) and not stunned, it sums `SPELL_AURA_DEFLECT_SPELLS` amounts from spell `525065` and sets
`target.missCondition = SPELL_MISS_DEFLECT` on a successful roll. No shared engine, SQL, DBC, or other-class files are
changed.

## Consequences

- Hostile melee abilities targeting a Cultist under Twisted Seal `525065` from the front are deflected; non-Cultists,
  Cultists without `525065`, positive spells, and `SPELL_ATTR3_ALWAYS_HIT` spells are unaffected.
- Regressions (counted pair `prove-525065` `20261125-090856` / `20261125-090925`, build `3732deaa8812`, 0 flips; also
  confirmed in `prove-2` `20261125-090640` / `20261125-090726`):
  - `525065 behaviour_metric_delta deflect_melee_ability`: `10` hits before (control) -> `10` cumulative after (gain `0`
    of 10 strikes in both runs, `ok/ok`).
  - `525065 behaviour_metric_delta deflect_magic`: `20` before -> `20` after (gain `0` of 20 strikes in both runs, `ok/ok`).
  - `525065 behaviour_metric_delta silence_on_deflect`: `0 -> 1` and `0` after expiry in both runs (`ok/ok`).
  - Sibling checks `duration`, `no_cast`, `no_attack`, `no_attack_applied`: all `ok/ok`.
