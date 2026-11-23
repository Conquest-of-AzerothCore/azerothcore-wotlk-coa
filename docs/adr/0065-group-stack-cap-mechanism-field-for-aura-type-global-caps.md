# 0065. A `mechanism` field on `group_stack_cap` for non-stacking caps that are not a `spell_group`

- Status: accepted
- Date: 2026-11-10

## Context

ADR 0056 built the `group_stack_cap` behaviour kind for the two "Does not stack with similar effects." clauses
whose non-stacking is implemented via `spell_group`/`spell_group_stack_rules` (`stack_rule` 3,
`SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT`). It left Fortified Body (300515), Devotion of Khaz'goroth
(560096) and Crusader's Presence (562302) for a follow-up, since none of them carry a `spell_group` row
anywhere in `data/sql` this session grepped.

Tracing Fortified Body (300515) found a different, genuine stock mechanism: its healing-taken bonus is
`SPELL_AURA_MOD_HEALING_PCT` (118), implemented not through `SpellMgr`'s group system at all but directly in
`Unit::SpellHealingBonusTaken` (`Unit.cpp:10880-10895`), which calls `GetMaxPositiveAuraModifier(SPELL_AURA_MOD_
HEALING_PCT)` (`Unit.cpp:7091-7135`) unconditionally: that function takes the single highest-magnitude aura of
the given type across *every* aura the unit holds, with no `spell_group` predicate and no per-class
restriction. Any two sources of this aura type anywhere already cap rather than sum, by construction of the
aura type's own handler (`SpellAuraEffects.cpp:188`, `HandleNoImmediateEffect`, "implemented in
Unit::SpellHealingBonus"). The existing `group_stack_cap` scenario/judge math (`own_expected`/`combined_expected`
= `baseline * (1 + pct/100) * (1 + personal_pct/100)`, capped at `max(own_pct, partner_pct)`) is identical either
way — only the generated `contract` text and the judge's `explanation` string named the mechanism, and both
hard-coded the `spell_group`/`SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT` wording, which would be a false claim
for 300515 if reused unmodified (CLAUDE.md: never invent, never state something not read from code/DBC/output).

Devotion of Khaz'goroth (560096) and Crusader's Presence (562302) remain open: 560096's own effect is a plain
`SPELL_AURA_PROC_TRIGGER_SPELL`, with the actual haste buff granted onto a *different* spell (567572, via
`AscensionTemplar.cpp:294-297`'s `OnPlayerUpdate` check) that genuinely is a `spell_group` 2000182 member — but
its aura type (`SPELL_AURA_MOD_MELEE_RANGED_HASTE`, 192) is observable only through `attack_time_ms`, which the
*stock* `AuraEffect::HandleModMeleeRangedSpeedPct` (`SpellAuraEffects.cpp:5056-5072`) applies as a *decrease* to
the metric for a *positive* buff percentage, the opposite sign convention from every existing `group_stack_cap`
metric (`spell_damage_done`, `attack_power`, `spell_healing_taken`), which the judge's `own_expected`/
`combined_expected` formulas assume increase with a positive percentage. Reusing the kind unmodified for 560096
would need a `direction` field and a second, decrease-shaped judge formula verified against a scenario-level
`learn` of 560096 (not 567572 directly) plus the `OnPlayerUpdate` latency, which this step did not have budget
to design and verify safely. Crusader's Presence (562302) needs the caster to actually be mounted
(`Unit::UpdateSpeed`'s `MOVE_RUN`/`MOVE_FLIGHT` cases only read the `_NOT_STACK`/`_NOT_STACKING` aura types when
`IsMounted()`), and no `learn`/`cast`/fixture step in `CoAGameplayTest.cpp` grants a mount; both are left for a
further follow-up.

## Considered options

1. Leave 300515 unclosed, since its mechanism text does not match the existing hard-coded wording. Rejected:
   the clause is fully provable today with the existing scenario/judge math; only the generated prose needs to
   name the real mechanism, which is a one-field generalisation, not a new behaviour kind.
2. Duplicate `group_stack_cap_scenario`/`behaviour_group_stack_cap_verdict` into a second, near-identical
   `aura_cap` kind just to change two strings. Rejected: needless duplication of tested, working judge math for
   a difference that is purely descriptive.
3. Add a `mechanism: str = 'spell_group'` field to `GroupStackCapSpec`, carried into the model dict and read by
   `behaviour_group_stack_cap_verdict`'s explanation text; a lookup table (`GROUP_STACK_CAP_MECHANISM_PHRASES`)
   maps `'spell_group'` (unchanged wording, the default, so the two already-committed entries are untouched)
   and a new `'aura_cap'` to the accurate phrase ("a different spell whose own aura is capped by the same aura
   type's global cap ... with no spell_group row needed at all"). An unrecognised `mechanism` value raises
   `KeyError` from the dict lookup rather than silently falling back to the wrong phrase. Chosen.

## Decision

Added `mechanism` to `GroupStackCapSpec` (default `'spell_group'`) and `GROUP_STACK_CAP_MECHANISM_PHRASES` to
`behaviours.py`; `group_stack_cap_scenario`'s `contract` string and the model dict's `mechanism` key use it, and
`behaviour_group_stack_cap_verdict` in `compare.py` reads `model.get('mechanism', 'spell_group')` to pick the
matching explanation phrase. The judge's numeric comparison is unchanged in every case.

Closed Fortified Body (300515) with `mechanism: "aura_cap"`, `partner: 34123` (Tree of Life, a Druid talent,
learned purely as harness setup, matching ADR 0056's precedent), both at an equal 6% (so an additive-stacking
bug cannot hide behind "still capped by the larger one"), metric `spell_healing_taken` (`CoAGameplayTest.cpp:
3519-3524`, `Unit::SpellHealingBonusTaken(caster, info, 1000, HEAL)`, a synthetic base-1000 query, the `Taken`-
side counterpart of the already-used `spell_damage_done`/`spell_healing_done` idiom) read on the caster itself
against spell 578276 (Benediction, chosen only so `SpellInfo` resolves; no cast happens). No mount or "haste
decreases a time metric" generalisation was added, since no clause closed this step needed either.

Left Devotion of Khaz'goroth (560096, needs a `direction`-aware judge formula and a `learn`-the-trigger-spell/
measure-the-granted-spell split, mirroring `oath_consumption`'s `measured_spell` precedent) and Crusader's
Presence (562302, needs a mount fixture/action that does not exist anywhere in the harness) for a follow-up
step, with both investigations and the concrete blocker recorded in the workstream report rather than guessed
at.

## Consequences

- `group_stack_cap` now proves "Does not stack with similar effects." regardless of whether the stock
  non-stacking mechanism is `SpellMgr`'s group system or an aura type's own unconditional
  `GetMaxPositiveAuraModifier` cap, without inventing a mechanism the judge text does not actually check.
- The two pre-existing entries (300929, 560550) keep their original `spell_group` wording unchanged (default
  value), with no behavioural or textual change, confirmed by their unit tests still passing unmodified.
- Devotion of Khaz'goroth and Crusader's Presence remain genuinely open clauses, each needing a distinct further
  capability (a decrease-direction judge variant; a new mount setup action), not swept into this one by a
  mismatched reuse.
