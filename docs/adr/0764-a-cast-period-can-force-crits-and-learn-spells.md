# 0764. A cast period can force crits and learn spells

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

A later Witch Hunter `cast_period` entry (706260 / 282.0) needs the caster's crits forced and extra spells known at
the start. Mentor D-245 (O-12).

## Options

- Two optional fields of the `cast_period` kind.
- A new kind: duplicates the whole cast period judge.

## Decision

`force_crit` (`melee`, `spell` or `ranged`) sets that school's forced crit rating (`FORCE_CRIT_RATINGS`) on the
caster as `metric_delta` does; `learn` lists spells learned at the scenario's start, after the setup and trigger
spells. Both change only the scenario and its contract.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical.
- Seeded tests: the rating and the learn step are present with the options and absent without them. The options add
  no check; the mutant that must alert is a malformed value (an unknown school, a non-integer spell), refused.
- No class-file entry changes here (D-245): the 706260 entry is a later author's.
