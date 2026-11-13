# 0063. A `group_stack_cap` behaviour kind for "Does not stack with similar effects" clauses

- Status: accepted
- Date: 2026-11-10

## Context

`round10/workstreams/oath-stacks-exclusivity.md` lists five "Does not stack with similar effects." clauses
(Fortified Body 300515, Serendipity 300929, Devotion of Khaz'goroth 560096, Call of the Monastery 560550,
Crusader's Presence 562302). No existing behaviour kind measures cross-spell percentage capping: `exclusivity`
proves a spell's own aura is removed when a sibling is cast (stock `stack_rule` 2), which does not apply here,
since `SpellMgr::LoadSpellGroupStackRules` (`SpellMgr.cpp:2096-2219`) shows Serendipity (300929, `spell_group`
2000184) and Call of the Monastery (560550, `spell_group` 2000180) already carry `stack_rule` 3
(`SPELL_GROUP_STACK_RULE_EXCLUSIVE_SAME_EFFECT`): both auras stay applied, but `Unit::GetTotalAuraModifier`/
`GetTotalAuraMultiplier` (`Unit.cpp:7040-7089`) count only the single highest-magnitude member of the group
once, never their sum. Fortified Body (300515), Devotion of Khaz'goroth (560096) and Crusader's Presence
(562302) carry no `spell_group` row at all in any pending/base/update SQL this session read, so they are left
for a follow-up step that first establishes (or fixes) their own group membership; this step only proves the
two clauses the server already implements.

## Considered options

1. Reuse `metric_delta` (a single before/after pair around one trigger cast). Rejected: the clause needs three
   readings (baseline, own alone, own+partner) to distinguish a correct cap from additive stacking, and
   `metric_delta`'s single trigger-cast shape has no second spell to learn.
2. A new `group_stack_cap` kind: learn the own spell, measure; learn a different spell already confirmed (via
   DBC) to carry the identical aura type in the same `spell_group`, measure again; the combined reading must
   equal `baseline * max(own%, partner%)`, never the summed percentages. Chosen.

## Decision

Added `BEHAVIOUR_GROUP_STACK_CAP` / kind `'group_stack_cap'` to `behaviours.py`, with `GroupStackCapSpec`
(`spell`, `name`, `quote`, `effect`, `partner`, `partner_effect`, `metric`, `fields`, optional `personal_effect`,
`wait_ms`) and `group_stack_cap_scenario`/`group_stack_cap_spec`. The scenario reads the metric with neither
spell known (`baseline`), learns the own spell, waits `wait_ms` (default 300 ms: both Templar entries' capped
effect is a `SPELL_EFFECT_APPLY_AREA_AURA_RAID`, whose self-application runs on `Aura::UpdateOwner`'s own
target-map rescan, not synchronously inside `learnSpell`, confirmed by an exploratory run that measured the
pre-aura baseline unchanged without the wait), reads the metric again (`own`), learns the partner, waits again,
and reads the metric a third time (`combined`). `own_pct`/`partner_pct`/`personal_pct` are read from the DBC at
generation time (`Records.single_value`), never hand-entered. `compare.py` gained
`behaviour_group_stack_cap_verdict`: `own_expected = baseline * (1 + own_pct/100) * (1 + personal_pct/100)` and
`combined_expected = baseline * (1 + max(own_pct, partner_pct)/100) * (1 + personal_pct/100)`, each checked
against the measured reading within `max(ABSOLUTE_TOLERANCE, RELATIVE_TOLERANCE * expected)` (the same
near-deterministic margin `metric_delta`/`amount_delta` use elsewhere in this file: both percentages are fixed
DBC constants with no die roll, so a loose tolerance would hide a stacking bug whose size is comparable to the
percentages themselves, confirmed by a seeded-wrong-value unit test that only failed once the tolerance was
tightened from an initial, too-generous 5% band).

`personal_effect` exists because Call of the Monastery (560550) carries a *second* own-only
`SPELL_AURA_MOD_ATTACK_POWER_PCT` effect (index 2, plain `SPELL_EFFECT_APPLY_AURA`, "in addition, increases your
own attack power by $s2%") that `SpellMgr::IsEffectInSameEffectStackGroup`'s own comment -- "CoA raid groups
must not swallow a talent's separate personal effect" (`SpellMgr.cpp:814-819`) -- deliberately excludes from the
group cap by checking `Effects[effectIndex].IsAreaAuraEffect()`; only the area-aura effect (index 0) is capped,
so the personal effect keeps compounding on top of the capped reading in both the `own` and `combined`
measurements. Serendipity's entry omits `personal_effect` (its only other effect reduces spell costs, a
different stat the `spell_damage_done` metric never reads).

Serendipity's own metric is `spell_damage_done` against a Fire-school spell (133, Fireball), not
`melee_damage_done`: `Unit::MeleeDamageBonusDone` (`Unit.cpp:11470`) explicitly skips
`GetTotalAuraMultiplier(SPELL_AURA_MOD_DAMAGE_PERCENT_DONE)` whenever the queried `damageSchoolMask` includes
`SPELL_SCHOOL_MASK_NORMAL` ("mods for SPELL_SCHOOL_MASK_NORMAL are already factored in base melee damage
calculation", a different code path this harness's fixed-base-1000 query never reaches), confirmed by an
exploratory run where `melee_damage_done` measured baseline==own==combined even after the wait fix.

## Consequences

Any future same-spell-group percentage-cap clause (for any class) can reuse the kind by citing its own
`effect`/`partner`/`partner_effect`/`metric`/`fields` in a class file, with no tool code change. The kind
proves the two-member case (own + one partner); it does not prove a three-or-more-member group picks the
single highest across all members simultaneously (the stock `std::map<SpellGroup, int32>` accumulator in
`Unit::GetTotalAuraModifier`/`GetTotalAuraMultiplier` makes this a direct extension of the two-member case, not
a different code path). It also does not, by itself, establish group membership for a spell with no
`spell_group` row (300515/560096/562302), which the workstream leaves for a follow-up step to investigate
first.
