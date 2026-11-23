# 1140. A removed own effect is not read for its radius or its aura

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 0364 (removed_own_effects)

## Context

A class file's `removed_own_effects` keeps an effect that a class contract zeroes from being the rank's first effect
for its unreadable tokens (ADR 0364). The value scenario still reads the same effect for an own `$aN` radius
(`spell_effect_radius`) and takes it as the aura of an own `$d` (`aura_duration_ms` of the first aura effect). The
harness refuses both reads of a zeroed effect ("Spell effect does not exist"), which stops the whole value scenario.
Voodoo Cauldron 804684: the load contract zeroes Effect[2], the persistent area aura
(`AscensionWitchDoctorCompletion.cpp:507-508`), and the cauldron creature pulses the heal from that effect's radius and
points itself (`AscensionWitchDoctorSummons.cpp:555-562`). Its value scenario fails at `$a3`, so its power cost and
cooldown are never measured, and both `$d` tokens alert.

## Decision

In `values.value_scenario`, an own radius token of a removed effect is `unmeasurable: radius of an effect a class
contract removes (removed_own_effects)`, and the aura an own `$d` reads skips removed effects; with no other aura
effect the token is the existing `unmeasurable: the spell is passive or applies no aura`. The labels keep their names.

## Consequences

- The behaviour entries that read the zeroed effect's radius, amount and lifetime through the creature stay the
  measure of those tokens; the unmeasurable labels leave the claims that those entries prove.
- Opt-in through the class file list: classes 19 (also with `--stack`) and 23 generate byte-identical scenarios (the
  Necromancer Runic Harvest entries name an effect that is neither a radius nor an aura of a `$d`).
