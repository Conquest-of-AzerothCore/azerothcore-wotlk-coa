# 0151. Set a proc aura that a cast grants

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0130 (procs per trigger)

## Context

Vindication 573324 grants Oath: Vindication 805332, "Oath: Your damaging abilities have a $805332s1% chance to
trigger Zealotry." The roll is the Oath's effect 0 amount (`AscensionTemplarAbilities.cpp:326-329`). A `procs`
entry learns its aura and reads a `chance_pct` token of the aura's own tooltip. Learning 805332 applies nothing, and
805332 has no Description: its chance is a percent token of Vindication's tooltip.

## Decision

A `procs` entry may carry `applied_by: {"spell", "source"}`. The scenario then sets the aura (`set_aura`, 1 stack)
where it would learn it, and the chance is the aura's own `$<aura>s1` percent token in the tooltip of `spell`, both
when the scenario is generated and when it is judged (model `chance_spell`, `chance_kind`). Any other token is
refused. The entry's `tooltip` copies the tooltip of `spell`.

## Consequences

- Oath: Vindication's chance is measured on Argent Blade 807268 hits: 503 Zealotry casts in 2552 hits, Wilson 99%
  [0.178, 0.218] against 20% (diagnostic 20261111-172610).
- Entries without `applied_by` generate the same scenarios and models as before.
