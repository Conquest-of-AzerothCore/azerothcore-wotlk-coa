# 0029. The `spell_power_cost` consumer skips a target with no plain cost

- Status: accepted
- Date: 2026-11-08

## Context

Round 3's modifier-target-unresolved item added `passive_targets` overrides for Blessed Strikes 704180 (effect 0,
`SpellModOp` 14, `spell_power_cost` consumer, relation `add`) so its 10 mask-matched "Oath Breaker" finishers
became its targets instead of `unmodelled`. Measuring the generated scenario alerted on 3 of the 10: Divine Fury
501567, Reckoning 572741 and Chakram 704573 each read `spell_power_cost` 0 before and 0 after learning Blessed
Strikes, against an expected delta of −10.

`Spell.dbc` confirms why: all three have `ManaCost = 0`, `ManaCostPerlevel = 0` and `ManaCostPercentage = 0` (no
plain cost field is set at all). `SpellInfo::CalcPowerCost` (`src/server/game/Spells/SpellInfo.cpp:3166` on,
clamp at `:3268`) starts `powerCost` from `ManaCost`, applies the `SPELLMOD_COST` modifier, then clamps a negative
result to 0 before returning. A flat −10 modifier on a 0 base therefore always measures 0 → 0: not because the
modifier fails to apply, but because there is nothing to subtract from and the result cannot go negative. The
three targets are real, confirmed mask members of this effect (their own `SpellFamilyFlags` do carry the bit, and
their own tooltips do use "Oath Breaker"/"Oaths" per the same override); the mismatch is in the metric, not in
the target list.

## Considered options

1. Drop the three zero-cost spells from Blessed Strikes' `passive_targets` override. Rejected: `plan_probes`
   measures every target of a `P1` effect, named or mask-only (`modifier_targets`'s `mask_only` list is built
   independently of the override), so the same three ids would still be probed as mask-only entries and still
   alert; removing them from the override's `targets` list does not stop the probe.
2. Leave the alert and record it as a known false positive in the report. Rejected: a passing conformance run
   should not carry a known-wrong alert, and "an honest `unmodelled` beats a check that could give a false ok/
   alert" is the project's own rule for exactly this shape of gap.
3. `plan_probes` skips the `spell_power_cost` consumer for a target with no plain cost (`facts_of(...).mana_cost`,
   `.mana_cost_per_level` and `.mana_cost_percentage` all falsy), the same `RankFacts` facts `PLAIN_COST` already
   reads for `reference_spell`, with reason `unmodelled: target <id> has no power cost to modify`. Chosen: it is
   the same shape as the existing `spell_effect_value` skip (`unmodelled: target <id> has no effect <n>`) one
   line above it, generic (no class or spell id in `passives.py`), and the facts it reads are already read
   elsewhere in the same file for the same reason.

## Decision

- `passives.py`'s `plan_probes` adds, beside the existing `spell_effect_value` "has no effect" skip: when
  `plan.metric == 'spell_power_cost'` and the target's `RankFacts` show no `mana_cost`, no `mana_cost_per_level`
  and no `mana_cost_percentage`, the probe's reason becomes `unmodelled: target <id> has no power cost to modify`
  instead of a `passive_delta` probe.
- Scoped to `spell_power_cost` only: the other `SPELL_MODIFIER_CONSUMERS` metrics (`spell_cast_time_ms`,
  `spell_max_range`, `spell_max_stacks`, `spell_effect_value`, `spell_done_crit_chance`) are not known to clamp a
  meaningful base to a value indistinguishable from "no base", so widening the pattern to them is a follow-up,
  not implied by this change.
- `classes/templar.json` keeps Blessed Strikes' override at the full 10-spell mask-derived list (no spell added
  or removed relative to what `in_mask` computes); the skip, not a shorter target list, is what keeps the three
  zero-cost finishers honest.

## Consequences

- Blessed Strikes 704180's scenario alerts drop from 3 to 0; the three zero-cost targets report
  `unmodelled: target <id> has no power cost to modify` instead of a false `passive_delta` alert.
  `test_spell_power_cost_skips_targets_with_no_plain_cost` (Templar, real DBC) pins it; the existing
  `test_effect_value_consumer_skips_targets_without_the_effect` (Martial Training) stays the regression for the
  sibling `spell_effect_value` skip.
- Mark of Aggramar 804928's own mask-only, out-of-class targets (Ascetic/Mortal Abdication, relation `scale`)
  move from `compare.py`'s own pre-existing `unmeasured` ("relation scale multiplies the before value 0") to this
  `unmodelled` reason instead, since several of them also have no plain cost; both are non-alert statuses, so no
  existing assertion changes meaning, only the stated reason gets more specific where it applies.
- A future class whose own finisher-style ability is named by a cost-reduction tooltip but genuinely has no base
  cost in `Spell.dbc` gets the same honest `unmodelled` without any class-specific code.
