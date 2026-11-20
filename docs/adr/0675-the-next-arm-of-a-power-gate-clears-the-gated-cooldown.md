# 0675. The next arm of a power gate clears the gated spell's cooldown

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0137, ADR 0185

## Context

A cost gate's `next` arm runs without setup (`setup=False`), so it never clears the gated spell's cooldown. For a
power gate of a spell with a cooldown, the `with` cast starts that cooldown and the next attempt is refused by it:
Bringer of Darkness 500101 `vault_free next` read 67 (`SPELL_FAILED_NOT_READY`) against 85, Vault 500085 having a
12000 ms RecoveryTime. The arm then measures the cooldown, not the once-only cost.

## Options

- Drop `next_arm` from the entry: loses the "next Vault" (once-only) value, refused by the label-drop ruling.
- An opt-in entry field.
- Clear the cooldown in the next arm of a power gate whose gated spell has a cooldown.

## Decision

The `next` arm of a `resource: "power"` gate clears the gated spell's cooldown when its RecoveryTime or
CategoryRecoveryTime is positive, without the setup casts; the contract says so. A gated spell without a cooldown
keeps its steps.

## Consequences

- Tests: the Vault next arm clears 500085's cooldown between the with and next attempts without a Repulse; Temple
  Guardian 803792 (no cooldown) keeps its steps; a seeded 67 on the next arm is `alert`, 85 `ok`.
- Templar and Necromancer generations stay byte-identical: their next arms gate Temple Guardian 803792 and Holy
  Cleave 573049, both without a cooldown.
