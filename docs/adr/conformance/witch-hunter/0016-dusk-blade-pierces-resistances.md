# 0016. Dusk Blade pierces resistances

- Status: accepted
- Date: 2026-11-16

## Context

Dusk Blade 802258 reads: "Strike an enemy with both weapons, dealing Weapon Damage plus ${$m2+$sps*0.15} Shadow
damage, piercing resistances. Heals for $574334s1% of damage dealt." (Spell.dbc server set, Description[enUS]). The
spell and its off-hand strike 803502 are SchoolMask 32 (Shadow) and carry SPELL_ATTR5_NO_PARTIAL_RESISTS, a bit the
engine never reads, and the Witch Hunter contract set no resist bypass for them, so `Unit::CalcAbsorbResist` rolled
the Shadow partial resist (`Unit.cpp:2672`).

Measured in the c17-a2 pair 20261116-154748 / 20261116-155055 (build 53f65058f782, 46/46 scenarios each run): with
the dummy's resistance live against removed, the main hand read -12.04% / -12.10% and the off hand -11.98% / -12.40%,
the same as the Noctis Blade 680615 positive control (Shadow, no attribute: -12.37% / -11.34%, expected -12%). The
archived combat logs show 0 of 1132 Dusk Blade hits resisted (469 + 3 for 802258, 655 + 5 for 803502), against 266
of 4592 other player Shadow hits on creatures in the same five logs.

Both spells match the Desecrate profile of [ADR 0014](0014-desecrate-pierces-resistances.md): DmgClass MELEE,
Dispel 0, Mechanic 0, no aura effect (802258: NORMALIZED_WEAPON_DMG and TRIGGER_SPELL_WITH_VALUE 803502; 803502:
NORMALIZED_WEAPON_DMG). Their hit result goes through `MeleeSpellHitResult`, never the debuff resist of
`MagicSpellHitResult` (`Unit.cpp:4076`), and the Felsworn `ResistDebuff` (`AscensionFelsworn.cpp:79`) already
refuses them for their Dispel 0 and lack of an aura.

Mentor rulings D-297 and D-298: build the ADR 0014 route for both spells, Witch Hunter code only, no `Unit.cpp`
edit, no SQL, no client text.

## Options

- Set SPELL_ATTR4_NO_CAST_LOG ("Cannot be resisted") on 802258 and 803502 in the Witch Hunter contract: skips the
  partial-resist block only; absorbs still apply.
- Set `AscensionIgnoreAbsorbAndResistance`: also skips absorbs, which the tooltip does not claim.
- A resist-only flag read next to `Unit.cpp:2662`: a shared engine edit for a result the first option already gives.
- Honour SPELL_ATTR5_NO_PARTIAL_RESISTS in `Unit::CalcAbsorbResist`: changes 201 spells across 13 families at once,
  146 of them without tooltip text about resistances; outside this class.

## Decision

The first option, in `AscensionWitchHunterCompletion.cpp` next to the Desecrate contract.

## Consequences

- Dusk Blade's two strikes are not lowered by the target's Shadow resistance (the linear monster resistance in PvE,
  Shadow resistance and Shadow Protection in PvP); Shadow absorbs still absorb them.
- The lower Dusk Blade ranks 802020 and 802253-802257 carry the same attribute; the amendment below extends the
  contract to them.
- Regressions: `802258 behaviour_hit_ratio piercing_main` and `piercing_off` (ratio 1.0 with the resistance live),
  `802258 behaviour_hit_ratio piercing_control` (Noctis Blade still resisted, 0.88), `802258 behaviour_metric_delta
  absorb` (Shadow Ward 6229 still absorbs its 290 from the two strikes); the 321.0 damage entries
  (`dusk_main_base`, `dusk_off_base`, `dusk_main_power`, `dusk_off_power`) remove the resistance in both phases and
  are unchanged.

## Amendment (2026-11-16, mentor D-323): the lower ranks

The six lower ranks 802020, 802253, 802254, 802255, 802256 and 802257 (BaseLevel 13, 18, 26, 34, 42, 50) read the same
tooltip sentence as 802258 in the server Spell.dbc and match its profile: SchoolMask 32, AttributesEx5 0x800000
(SPELL_ATTR5_NO_PARTIAL_RESISTS), DmgClass MELEE, Dispel 0, Mechanic 0, Effect[0] NORMALIZED_WEAPON_DMG and Effect[1]
TRIGGER_SPELL_WITH_VALUE 803502, no aura effect. They differ only in EffectBasePoints (9, 19, 29, 49, 69, 99 against
119). All six trigger the same off-hand strike 803502, already covered. No rank was left out.

The contract line now keys on `Dusk()` (`AscensionWitchHunterCompletion.h`, 802020 and 802253-802258) and 803502.
The Spell.dbc readers of SPELL_ATTR4_NO_CAST_LOG are unchanged: the partial resist block of `Unit::CalcAbsorbResist`
(`Unit.cpp:2672`), the debuff resist of `MagicSpellHitResult` (`Unit.cpp:4076`, not reached by a melee spell) and the
Felsworn `ResistDebuff` (`AscensionFelsworn.cpp:79`, which already refuses these spells for their Dispel 0 and lack of
an aura). The ranks belong to the Witch Hunter only (class map: class 15, 7 ranks, no other class).

Regressions for the lowest rank, cast at level 60: `802258 behaviour_hit_ratio piercing_main_802020` and
`piercing_off_802020` (ratio 1.0 with the resistance live, the same arms and the same Noctis Blade control
`802258 behaviour_hit_ratio piercing_control`), and `802020 behaviour_metric_delta absorb` (Shadow Ward 6229,
its amount set to 100 because the rank 1 strikes total 150 to 174, still absorbs 100 from the two strikes).
