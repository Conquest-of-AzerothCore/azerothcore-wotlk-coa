# 0188. Silverhand Incantation removes Sacred Restraint from an ally

- Status: accepted; the hostile case is superseded by ADR 0292
- Date: 2026-11-12
- Decision by: the mentor, approving fix note FN-r1b-2 for the ally case (method-study/owner-rulings-2026-11-10.md,
  "Silverhand Incantation [801465], claim 329")

## Context

Silverhand Incantation 801465: "...charging you to them and removing Sacred Restraint from you and them if they are
an ally." Sacred Restraint 102208 is the Testaments' lockout. Nothing removed it: with 102208 on the Templar and on a
grouped ally, a cast at the ally landed (the Templar ended 1.5 yd from it and 801501 healed both) and both still
carried 102208 (diagnostics 20261111-233946 and -234032). 801465's effects are a trigger missile with value and a
charge, 801501's are damage and heal, and no script removed 102208.

## Options

1. A `spell_linked_spell` row removing 102208 on cast. It cannot tell a friendly target from a hostile one.
2. A spell script on 801501's heal. It would also run for every ally the area heal reaches.
3. In the Templar's `templar_casts::OnSpellCast`, after a cast of 801465 whose unit target is friendly and not the
   caster, remove 102208 from the caster and from that target.

## Decision

Option 3. OnSpellCast runs only for a cast that went through, so a refused cast (out of range, no power) removes
nothing. The removal takes every application of 102208 on the caster and on the target, whoever applied it: the
lockout belongs to the unit, and a Testament cast by another Templar on the ally puts its own copy there.

The hostile case keeps the earlier behaviour: nothing is removed from the caster or from the enemy. Whether the caster
should lose it then is owner question Q4.

## Consequences

- Regression `templar-silverhand-incantation-sacred-restraint`: a cast at the ally from 60 yd is refused (97,
  SPELL_FAILED_OUT_OF_RANGE) and both keep 102208; a cast at the ally from 10 yd clears both; a cast at the hostile
  dummy strikes it and both keep 102208.
- Gameplay change: a Templar can reopen Testaments for itself and an ally by charging to that ally.
