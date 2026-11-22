# 0011. Holy Giant doubles Vow of the Valkyr's auto attack damage bonus

- Status: accepted
- Date: 2026-11-22

## Context

Holy Giant 681337, Spell.dbc text: "Doubles the effectiveness of Vow of the Valkyr and Vow of Light." Its effect 0 is
`SPELL_AURA_ADD_PCT_MODIFIER`, `SPELLMOD_ALL_EFFECTS`, BasePoints 99 (+100%), on class mask word A 2 and word C
`0x20100000`. Vow of the Valkyr 807749 carries SpellFamilyFlags word A 3; its effect 1 (BasePoints 9 + 1 = 10) is the
auto attack damage bonus that the Sun Cleric melee hook adds (`AscensionSunClericContracts.cpp`, `ModifyMeleeDamage`).

The hook read `Amount(807749, 1)`, which is `SpellEffectInfo::CalcValue(nullptr)`. Without a caster, `CalcValue` skips
`Unit::ApplyEffectModifiers`, so no spell modifier reached the bonus and Holy Giant left it at 10%. Measured on batch 5a
(20 trials, both runs): main-hand plain hit ratio 1.0021 and 0.9999 against 1.0909 (1.20 / 1.10).

Passing the caster opens 807749 effect 1 to every spell modifier that matches it, the path that went wrong for Solemn
Priest (ADR 0004) and Sunwalker (ADR 0009). Server Spell.dbc scan (`/srv/coa/server-data/dbc`) of the auras 107 and 108
with `SPELLMOD_ALL_EFFECTS` or `SPELLMOD_EFFECT2`: in family 33 only Holy Giant 681337 matches 807749's flags; no script
applies or reads 681337, and its tooltip states no gate. The family 0 modifiers with a zero mask (Ripple Aura 281181,
Ripple in Time 281182, Fan the Flames 850000, the Primary Stat Food Buffs 968469 to 968476) already reach the second
effect of every spell read with a caster; they are not Sun Cleric auras. 807749 has no level scaling, no
`SPELL_ATTR3_IGNORE_CASTER_MODIFIERS`, no `SpellAffect.dbc` row, and no `ModifySpellEffectBaseValue` hook or
`IsAffectedBySpellMod` override handles it.

## Options

- Pass the caster: `Amount(807749, 1, player)`. The spell modifier doubles the bonus once, and any later modifier of
  807749 effect 1 applies the same way.
- The Solemn Priest design: keep `Amount(807749, 1)` and add Holy Giant's own share keyed to 681337 in the hook.

## Decision

The first option (mentor decision D-70, 2026-11-22), after the scan above found no second modifier, double count or
missing gate.

## Consequences

- With Vow of the Valkyr the auto attack bonus is 20% with Holy Giant and 10% without it.
- The Vow of Light half of the clause (807750, word C bit 29) is not part of this change and has no check yet.
- No other class reads 807749 or 681337.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-holy-giant-doubles-vow-of-the-valkyr-damage.json`, a control
  with Holy Giant and no Vow (ratio 1.0) and a Vow arm (1100 to 1200, ratio 1.0909).
