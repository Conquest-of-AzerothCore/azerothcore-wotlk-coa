# 0730. A death-saving claim pairs a control case with a treatment case

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 133.0 (Clinch Fighting 680492: "Attacks which would otherwise kill you now heal you for
$680493s1% maximum health") lost its heal label in the cycle 6 review (I-3): both phases held the talent, so there
was no control arm. A control in the same scenario is impossible: the lethal strike without the talent kills the
caster, and no step resurrects a player for the next phase (a talent learned after it failed with "Creature cast
failed: 109"). The c13 tool batch wrote a G-39 note for a `revive` harness action; mentor decision D-192 asked first
for a second design without harness C++.

## Options

- Separate `metric_delta` cases, each one scenario, judged together because a ledger part needs every one of its
  labels conformant in both runs of the pair (`labels_pass`, `clause_proven`).
- A judge option that pairs two cases into one verdict, as `pool_cases` pools identical cases: a new tool option for
  what the ledger already requires.
- The `revive` harness action (G-39 note): a harness change, a rebuild and a harness image refresh.

## Decision

The first option, with existing kinds only. `clinch_control` never learns 680492 (its gate is the already known
neutral self cast Pyro Tonic 802277) and reads `alive` 1 before and 0 after the lethal strike 32247 at 100 of 10000
health; `clinch_survives` learns 680492 between the phases and reads `alive` 1 after the same strike;
`clinch_heal` reads `spell_heal_total` of 680493 0 before and 5000 (50% of the 10000 maximum health) after it. The
ledger part lists the three labels with the DBC readback, so it holds only when the control dies and the treatment
survives and heals by the stated share.

## Consequences

- No tool or harness change; Templar 19 and Necromancer 23 are untouched.
- The `revive` G-39 note is not needed for 133.0.
- Counted pair 20261116-000320 / -000522: all three labels ok in both runs.
