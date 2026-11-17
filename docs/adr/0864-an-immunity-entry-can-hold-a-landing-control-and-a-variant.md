# 0864. An immunity entry can hold a landing control and a variant

- Status: accepted
- Date: 2026-11-16

## Context

Witching Shroud 805770 states "granting immunity to all harmful magic effects." (claim 389.1). The first entry measures
one fixture, Chilled Blood 35317 (Frost, one aura effect). Review 2 (I-2) and the mentor (D-316) ask for a second
fixture of another school and another shape, and for a Physical control that still lands, because the immunity mask is
126 (every school but Physical). The `immunity` kind expects every effect absent under the immunity, and its labels
carry only the spell id, so a second entry of 805770 would repeat the `cast`, `applied` and `expired` labels. The
3000 ms window holds three casts of one effect (1500 ms), so a second blocked effect does not fit the same scenario.

## Options

- A new kind for a mixed block and landing set: a larger change for one more read on an existing shape.
- Change the default expectations of the kind: moves every existing immunity entry.
- Opt-in fields on the existing kind (D-293 category A).

## Decision

- `variant` (string): inserted after `immunity` in every label of the entry.
- `lands` on an effect: the effect is expected present after the casts under the immunity, is removed with `set_aura`
  afterwards, has no post-expiry control arm and needs no `words` match with the quote.

## Consequences

- Tests: `ImmunityScenarioTests` (landing effect expectations and cast count, a missing landing effect is an alert,
  variant labels, a non-landing word still refused). Entries without the fields keep their scenario and labels.
