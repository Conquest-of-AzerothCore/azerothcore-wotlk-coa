# 1001. A party pulse can place its members at the radius edges

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-17
- Builds on: ADR 0930

## Context

The `party_pulse` judge of `periodic_dispel` (ADR 0930) places the near party member 3 yd from the caster and the far
one at the radius plus 15 yd, both constants. Witch Hunter part 350.1 (Witching Idol 804051, "within $853203a1 yds.",
20 yd) is therefore data only: a member at 35 yd proves only "not at 35 yd", and a pulse reaching 30 yd would pass.
Mentor D-467 approved design D-nfd-2 (category A: judging unchanged).

## Options

- Optional `party_pulse` fields `near_distance` and `far_margin`, defaulting to the constants.
- `party_stat_ratio`'s `far_margin`: it measures stats, not a dispel.
- A new kind for a radius bracket: duplicates the whole pulse scenario.

## Decision

The first option. `near_distance` must lie inside the radius of `radius_spell` and above 0; `far_margin` must be above
0. The labels, the model and the judge are unchanged; the contract names the two distances.

## Consequences

- Absent by default: the generated scenario is unchanged (a seeded test checks that the defaults written out give the
  same scenario); Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests in `test_periodic_dispel_party.py`: members at 18 and 22 yd, a 20 yd pulse is ok; a 30 yd pulse (the far
  member loses its debuffs) or a 15 yd pulse (the near one keeps them) alerts; a near member at or beyond the radius, at
  0 yd, or a far margin of 0 is refused.
- The distances are from the caster; a pulse centred elsewhere, or a range check that adds the units' sizes, shifts the
  edges, and the entry states where its pulse is centred.
- The periodic_dispel labels carry no suffix, so a spell has one `party_pulse` entry and its labels serve every part of
  the clause.
- Witch Hunter (pair 20261117-150929 / -151118): Witching Idol 804051 with its members at 18 and 22 yd dispelled both;
  the idol's own range check adds both units' sizes (20 + 1.0 + 1.5 = 22.5 yd). The entry stays at the defaults until
  the owner rules whether "within 20 yds" counts those sizes.
