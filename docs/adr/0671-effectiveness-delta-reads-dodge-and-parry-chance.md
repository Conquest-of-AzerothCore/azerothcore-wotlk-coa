# 0671. Effectiveness delta reads dodge and parry chance

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-14
- Builds on: ADR 0601, ADR 0581

## Context

`effectiveness_delta` (ADR 0601) reads `spell_power` or `stat` around a real cast of the modified effect, without and
with the learned modifier. Witch Hunter Dark Barrier 705520, "and increases its effectiveness by 25%", modifies
Stoicism 804802, whose effects raise the dodge chance (aura 49) and the parry chance (aura 47) by 30%. The harness
already reads `dodge_chance` and `parry_chance` (`run.py`), and coverage classes them as state reads, but the kind
refuses them, so the clause stayed data.

## Options

- A new kind module for avoidance effectiveness: duplicates `effectiveness_delta` for two metric names.
- Extend the kind module's `READ_METRICS` with `dodge_chance` and `parry_chance`. Its `METRIC_EVIDENCE` and
  `STATE_PROMISES` rows are built from that tuple, so `effectiveness_dodge_chance` and `effectiveness_parry_chance`
  get their own rows (state, promise word `effectiveness`) without a change to the owner's base tables.

## Decision

The second option. Since the reads include the character's own avoidance (base, agility, a negative sum clamped at
0), an entry judges the gain (`expected_gain`, after less before) and a least before reading that proves the effect
landed, rather than absolute values.

## Consequences

- Test: `EffectivenessDeltaTests.test_a_dodge_or_parry_read_is_judged_as_its_effectiveness_state`
  (kinds/test_effectiveness_delta.py); the cross-class evidence guard covers the new rows through `metric_evidence()`.
- The new rows are new keys, not overrides of base rows (`KindRowOverrideGuardTest`).
- No existing entry reads these metrics: the Templar and Necromancer scenarios are unchanged.
- Mutant: `804802 all_effects x0` (Stoicism's amounts zeroed) must alert the Witch Hunter `dodge` and `parry` entries.
