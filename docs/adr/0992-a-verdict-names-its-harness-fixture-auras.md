# 0992. A verdict names its harness fixture auras

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Guide section 3.4 accepts a harness `set_aura` only as a precondition fixture, and requires that the verdict names
the fixture. The verdicts of `570726 behaviour_fixed_count rampaging_cleave` (fixtures 984584 and 530014 on the extra
dummies, ADR 0991) and `802139 behaviour_expiry lockout` (Shattered Eyes 57290 on the dummy, Witch Hunter ADR 0019)
named them only in the scenario contract and the class file text (review13 I2).

## Options

- Carry the fixtures in the model and append them to the verdict explanation.
- Record them in the ledger only: the verdict files would still not show them.

## Decision

The first option, as text only. `expiry.school_lockout_scenario` adds `fixtures` (`unit`, `auras`) to the expiry
model when `target_auras` is set, and `fixed_count` adds it when `swing_cleave` `dummy_auras` is set.
`compare.behaviour_expiry_verdict` and `compare.swing_cleave_count_verdict` append `expiry.fixture_note`: "; fixture:
aura <auras> set by harness set_aura on the <unit> (a precondition, not the claim's subject)". Status, measured value,
bounds and the judged reads do not change.

## Consequences

- Absent by default: no finished-class entry sets either field (Templar 806153's lockout has no `target_auras`), so
  Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: `test_expiry.py` and `test_behaviours.py` read the named fixture at the end of the explanation; mutant:
  a model without `fixtures` does not name it, with the same status and bounds; an entry without fixtures has no
  `fixtures` key and no note.
- Other kinds that take fixture auras (`hit_ratio` and `absorb_pierce_ratio` `target_auras`, `fixed_count`
  `post_cast_auras`) are not covered by this change.
