# 0677. A cost gate can grant its talent aura by a real cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0137

## Context

A cost gate with `talent_aura` sets that aura with `set_aura` and reads it present before every talent arm. Dawn
Knight 680497 "Your next Dawn Blade within $d is free of cost": the aura 681390 is consumed by the `with` Dawn Blade
cast (`AscensionWitchHunterAbilities.cpp:415-416`), so `dawn_free next aura` read 0 against 1 (final04). The mentor
asked for the aura to come from a real cast of 681390 (D-26), as the Templar's Tithe 500694 entry does with
`set_aura`.

## Options

- Change `talent_aura` to a cast for every entry: changes the Templar 500694 scenarios.
- An opt-in `talent_cast` and a next-arm aura expected absent.

## Decision

`talent_cast: true` (with a `talent_aura`, without `talent_aura_each_arm`) learns the aura spell and casts it at the
caster once, before the first talent arm, instead of `set_aura`. In a `next` arm the talent aura is expected absent
(0): the `with` cast consumed it.

## Consequences

- Tests: the real cast replaces `set_aura`; without the field `set_aura` stays; the next-arm aura reads 0 `ok` and a
  seeded 1 `alert` (a consumption that does not happen alerts); talent_cast without a once-set aura is refused.
- Templar and Necromancer generations stay byte-identical: no finished-class entry has a talent aura with a next
  arm, and none sets `talent_cast`.
