# 0022. Glaring Rays haste stacks as two multipliers

- Status: accepted
- Date: 2026-11-22

## Context

Glaring Rays 804257, Spell.dbc text: "Increases the spell haste of all party and raid members by $s1% and your spell
haste by an additional $s2%." Both effects are aura 216 `SPELL_AURA_HASTE_SPELLS` with BasePoints 2 (3%). Effect 0
is the raid area aura, effect 1 applies to the caster alone.

`AuraEffect::HandleModCastingSpeed` (`SpellAuraEffects.cpp:5035-5056`) calls `Unit::ApplyCastTimePercentMod`
(`Unit.cpp:14991-14999`) once per aura effect, and `ApplyPercentModFloatVar` multiplies the cast speed by
100 / (100 + 3) for each (`Unit.cpp:14967-14970`). Glaring Rays is a member of the CoA raid haste group 2000182
(stack rule 3, `rev_20260908_05_guardian_completion.sql:332-364`). In the stock engine that group would block the
second effect (`SpellAuraEffects.cpp:5049-5051`, `GetHighestExclusiveSameEffectSpellGroupValue`) and the caster would
read 0.970874. The CoA exception in `SpellMgr::IsEffectInSameEffectStackGroup` (`SpellMgr.cpp:826-828`, 4ced460235)
keeps groups 2000180-2000184 to area aura effects, so a talent's separate personal effect is not swallowed.
The caster therefore reads 1 / 1.03^2 = 0.942596 and a grouped ally
1 / 1.03 = 0.970874. A literal additive reading of the tooltip, 6%, would give 1 / 1.06 = 0.943396 for the caster, which
is 0.0008 above the engine value and eight times the 0.0001 tolerance of the `caster_haste` entry.

The independent review of batch 8 (b8c, finding I3) held the claim: the entry conceded the tooltip's additive wording
and the closed list of accepted engine behaviours (guide section 5) has no rule for haste stacking.

## Options

- Keep the multiplicative expectation and record a mentor ruling for it.
- Expect the additive value 0.943396 and change the server so two aura 216 effects of one spell add.
- Ask the owner (status 5).

## Decision

The first option (mentor decision D-119). A separate "additional $s2%" effect is its own aura 216. The CoA stack
group exception lets it apply next to the raid effect, and the engine stacks it as a second multiplier, through the
same engine function that the Swift Justice 300327 and 300322 entries read.
`caster_haste` expects 0.942596 and `ally_haste` 0.970874, both from the engine rule with its cited lines.
The claim is status 1 under that ruling. No server change.

## Consequences

- The ledger row of the claim cites D-119 and this ADR.
- The ruling covers the multiplicative stacking of separate aura 216 effects of one spell only. Another claim whose
  tooltip implies an additive total needs its own ruling.
- A change to haste stacking in the engine, or to the CoA raid group exception, would turn `caster_haste`
  non-conformant, which is the regression guard.
