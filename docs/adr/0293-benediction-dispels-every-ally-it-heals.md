# 0293. Benediction's Disciplined Mind dispel reaches every ally it heals

- Status: accepted
- Date: 2026-11-12
- Decision by: the owner, status-5 question Q1, option (a), "Benediction dispels every ally it heals"
  (method-study/owner-rulings-2026-11-10.md, "Owner rulings on the Templar status-5 questions")

## Context

Disciplined Mind 680399 / 681483 makes Benediction 801448 / 578276 dispel poison and disease effects. ADR 0159 casts
525052 once per trigger effect of the rank held, from `templar_casts::OnSpellCast`, at the spell's explicit unit target.
With Oath: Holy Cleave 804903 stacks, Benediction also heals jump targets (SPELLMOD_JUMP_TARGETS on 578276's family
mask), and those allies kept their debuffs. The owner ruled that the dispel reaches every ally Benediction heals.

## Options

1. Keep the dispel on the explicit target (ADR 0159). Rejected by the ruling.
2. Walk the spell's unit target list in `OnSpellCast`. Rejected: the jump targets are selected after the cast hook.
3. Cast the dispel from `templar_casts::OnSpellHitResult`, which the engine calls once per unit the spell hits. Chosen.

## Decision

Option 3. On a hit of Benediction (miss `SPELL_MISS_NONE`), the rank held, 681483 before 680399, casts 525052 at that
unit `DispelCasts(rank)` times. The dispel does not depend on the effective healing: an ally at full health, healed for
0, is still dispelled. On each unit the dispel now follows the heal instead of preceding it.

## Consequences

- Regression `templar-disciplined-mind-holy-cleave`: in both trials the cast target and the second healed ally lose
  all four debuffs. Its control trial, the same Holy Cleave stack without 681483, heals both and both keep all four.
- The rank's dispel counts (ADR 0159) are unchanged: conformance entries 680399 and 681483 `dispel_count` run again
  as the non-regression of the moved path.
- Gameplay change: under Holy Cleave stacks, Benediction cleanses each ally it heals.
