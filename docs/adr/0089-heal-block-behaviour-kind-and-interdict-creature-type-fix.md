# 0089. Heal-block behaviour kind, and a Templar server fix for Interdict's creature-type gate

## Context

Interdict's tooltip ends "If they are an Undead or Demon they are unable to be healed for the duration."
Its own DBC record applies a silence (`Effect[0]`, `SPELL_AURA_MOD_SILENCE`) and triggers a second spell,
561309 "Atone for your Sins!" (`Effect[1]`, `SPELL_EFFECT_TRIGGER_SPELL`), whose own `Effect[0]` applies
`SPELL_AURA_MOD_HEALING_PCT` with `EffectBasePoints` -101 (a full healing block). `Spell::EffectTriggerSpell`
(`SpellEffects.cpp`) has no generic per-spell creature-type gate for any `SPELL_EFFECT_TRIGGER_SPELL`, and
grepping `src/server/coa` for `560116`/`561309` found no CoA script referencing either id before this round:
561309 was applying to every Interdict target, not only Undead and Demon ones, over-applying the tooltip's
conditional heal-block to all enemies. This is a Templar server defect, confirmed by reading the generic
trigger-spell handler and by the absence of any creature-type check anywhere this spell pair is referenced.

No existing behaviour kind measured whether a conditional heal-block aura actually lands on a specific
target type. An earlier design in this round measured a health delta around a creature's own self-cast of a
direct heal spell, but a bare `cast` of a heal spell by an owned, non-player `TempSummon` fixture was found,
by direct investigation (temporary, reverted `LOG_ERROR` tracing through `Unit::CastSpell`, `Spell::prepare`,
`Spell::_cast` and `Spell::EffectHeal`), to never actually apply any healing in this harness at all --
independent of Interdict, independent of creature type, and reproducing identically under both the simulated
and the `--gameplay-clock real` clock, with no error ever reported (`CastSpell` itself returns `SPELL_CAST_OK`,
but `Spell::_cast`/`Spell::EffectHeal` are never entered for the self-cast, even for a plain stock heal spell
with no Templar involvement) -- a harness limitation unrelated to this clause, not chased further here since a
more direct measurement sidesteps it entirely.

## Decision

- Fixed `AscensionTemplarAbilities.cpp`'s `templar_casts::OnSpellCalculatedTarget`: for the 561309 trigger
  cast, set `hit.missCondition = SPELL_MISS_IMMUNE` when the target's `GetCreatureType()` is neither
  `CREATURE_TYPE_UNDEAD` nor `CREATURE_TYPE_DEMON`, suppressing the heal-block aura on everyone else while
  leaving it intact (missCondition untouched, `SPELL_MISS_NONE`) on Undead/Demon targets. This is Templar-only
  (one `AllSpellScript` already scoped to `SpellFamilyName == 25`) and touches no shared engine code.
- A new `heal_block` behaviour kind (`HealBlockSpec`/`heal_block_scenario`/`heal_block_spec` in
  `behaviours.py`): casts the spell under test (`spell`, Interdict) on a creature fixture (`creature_entry`),
  measuring the `aura` metric for the heal-block mechanism's own spell id (`block_spell`, 561309) on that
  creature before and after. This measures the exact mechanism DBC-inspection already confirmed is the
  heal-block (`SPELL_AURA_MOD_HEALING_PCT` -101), the same "measure the mechanism's own aura" idiom
  `dispel_removal`/`aura_presence` already established in this round, applied here to a hostile (enemy-targeted)
  fixture rather than an ally one. A new `BEHAVIOUR_HEAL_BLOCK` check and `behaviour_heal_block_verdict` judge
  (dispatched from `judge_behaviour`) reuse the same exact-match-within-`METRIC_DELTA_FLOAT_TOLERANCE` pattern
  as `behaviour_metric_delta_verdict`: `blocked: true` expects the aura present (1.0) after the cast,
  `blocked: false` expects it to stay absent (0.0); both expect 0.0 before the cast as a baseline sanity check.
- Three class-file entries disambiguated by a `variant` field (the same mechanism `whirling_tempest`'s
  existing multi-entry clauses already use for one spell with several scenarios): creature entry 201
  (Brittlebones Skeleton, `creature_template.type` 6 Undead, `blocked: true`), entry 416 (Imp, type 3 Demon,
  `blocked: true`), and entry 36 (Harvest Golem, type 9 Mechanical, already used elsewhere as `DUMMY_ENTRY`,
  `blocked: false`). The third entry is a positive control: without it, an unconditional-block defect (the
  pre-fix behaviour) would make the Undead/Demon entries pass vacuously, and it is itself the fix's own
  regression check (before the fix, this entry's 561309 would have measured present, i.e. alerted).

## Consequences

- Interdict 560116's creature-type clause closes `ok` for both Undead and Demon, with a passing positive
  control proving the check distinguishes the two cases rather than always reporting "present".
- Any other class's creature-type-conditional heal-block gets the same scenario for free by adding a
  `heal_block` entry naming its own trigger spell, creature entry and block-mechanism spell id; the tool code
  makes no Templar-specific assumption beyond the class file's own ids.
- `KINDS` in `behaviours.py` gains `'heal_block'`; `BEHAVIOUR_CHECKS` gains `BEHAVIOUR_HEAL_BLOCK`;
  `behaviour_scenario`'s dispatch and `judge_behaviour`'s dispatch each gain the matching branch.
- The creature-self-cast-heal limitation found while building this check (a self-cast heal by an owned
  `TempSummon` silently never applies, regardless of clock) is not fixed here: it is shared-engine behaviour,
  out of this capability's scope, and no other class's conformance check currently depends on it.
