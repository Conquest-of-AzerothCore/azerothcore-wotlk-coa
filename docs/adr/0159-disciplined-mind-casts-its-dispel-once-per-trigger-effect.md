# 0159. Disciplined Mind casts its dispel once per trigger effect of the rank

- Status: accepted; the explicit-target shape is superseded by ADR 0293
- Date: 2026-11-11

## Context

Disciplined Mind rank 1 680399 reads "causes it to dispel $525052s2 poison and disease effect" and rank 2 681483
"causes it to dispel 2 poison and disease effects". The owner ruled on 2026-11-11 that rank 2 dispels 2 poison and 2
disease effects per Benediction and rank 1 one of each (`method-study/owner-rulings-2026-11-10.md`, "Disciplined
Mind"). 525052 removes 1 disease (e0) and 1 poison (e1). The Benediction hook (`AscensionTemplarAbilities.cpp`) cast
it once for either rank, and the measurement of ADR 0158 read rank 2 at 1 + 1. In Spell.dbc the rank 2 count is
already there: 680399 has one aura 42 effect triggering 525052, 681483 two. `ApplyContracts` turns those effects into
dummies and zeroes their TriggerSpell in the live `SpellInfo`, because the cast is scripted. The mentor approved the
fix note (`lean/disciplined-mind-fix-note.md`).

## Options

- Cast 525052 a second time for rank 2. Rejected: a hard-coded count that does not follow the data.
- A rank-specific dispel spell with 2 points per effect. Rejected: no such spell exists in the data.
- Count the rank's trigger effects in its raw Spell.dbc entry and cast 525052 that many times. Chosen.

## Decision

`DispelCasts(rank)` counts the effects of `sSpellStore.LookupEntry(rank)` with `EffectApplyAuraName` 42 and
`EffectTriggerSpell` 525052 (the raw store, because the contracts zero the live TriggerSpell). The Benediction hook
takes the rank held, 681483 before 680399, and casts 525052 that many times at the spell's explicit target. Templar code
only; rank 1 is unchanged.

## Consequences

- Each cast is triggered and instant (CastingTimeIndex 1, Speed 0, `CastSpell(..., true)`), so it runs to its effects
  inside the call; `Spell::EffectDispel` builds its list from the target's auras at that moment, so a later cast never
  picks an aura an earlier one removed. The triggered cast skips `CheckCast`'s nothing-to-dispel refusal, so a kind
  with nothing left is removed silently.
- Measured (two runs on one build): rank 2 2 + 2 of 2 each; 1 disease and 2 poisons of 1 disease and 3 poisons;
  rank 1 1 + 1; control 0 + 0; 681483 casts 525052 twice per Benediction (`trigger_count`, `per_trigger` 2).
- Shape unchanged: the dispel still goes only to Benediction's explicit target. With Oath: Holy Cleave stacks healing
  a second ally, that ally keeps its debuffs, before and after the fix (catalog scenario
  `templar-disciplined-mind-holy-cleave`).
- Tool: a trigger entry may state a whole number of events per trigger above 1 (`triggers.py`).
