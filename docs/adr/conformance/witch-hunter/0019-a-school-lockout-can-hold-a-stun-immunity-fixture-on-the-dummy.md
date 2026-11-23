# 0019. A school lockout can hold a stun immunity fixture on the dummy

- Status: accepted
- Date: 2026-11-16

## Context

Darkslayer's Lantern 802139 reads: "... and interrupting non-player spellcasting for $32747d." (Spell.dbc server
set). `spell_ascension_witch_hunter_ability::Hit`, registered `AfterHit`, casts Interrupt 32747 (Effect[0] 68
SPELL_EFFECT_INTERRUPT_CAST, DurationIndex 27, 3000 ms) at each non-player target the Lantern hits
(`src/server/coa/AscensionWitchHunterAbilities.cpp`). The Lantern's own Effect[1] stun (aura 12, EffectMechanic 12,
5000 ms) is applied before `AfterHit` and stops a stunnable dummy's channel first, so `Spell::EffectInterruptCast`
finds nothing to interrupt and no school is locked. Earlier attempts (a stun-immune SmartAI caster, Flamewaker
Acolyte 11663) did not cast under the harness; a non-triggered creature cast step would need harness C++ (G-39).

## Options

- A non-triggered creature `cast` step in the harness (G-39 note g39-o5): harness C++, rebuild, image refresh.
- A stun-immune world creature as the fixture: unproven, its SmartAI casts were not seen.
- An opt-in `target_auras` field on the existing `school_lockout` kind: a stun immunity aura set on the dummy before
  its channel, with existing reads only.

## Decision

`target_auras` (`expiry.py`, `school_lockout`): each `[spell, stacks]` is set on the dummy by `set_aura` before its
channel. With the field, the arm also requires the dummy to read `stunned` 0 and `casting` 0 after the pair, so a
landed stun or a channel that was not stopped leaves the pair unmeasured. Entries without the field generate
unchanged (Templar and Necromancer digests match).

## Consequences

- 802139 `lockout` entry: Shattered Eyes 57290 (sole effect Effect[0] 6 APPLY_AURA, aura 77
  SPELL_AURA_MECHANIC_IMMUNITY, EffectMiscValue[0] 12 MECHANIC_STUN, DurationIndex 21 = -1) makes the Lantern's stun
  effect immune while its damage hit and `AfterHit` stay. Counted pair 20261116-200311 / -200622: Evocation 12051's
  Arcane school locked 2876 ms and free 3026 ms after the cast; the end lies in (2876, 3126] ms against 3000 ms, so
  values 10% off (2700, 3300) are excluded.
- Seeded tests in test_expiry.py: the fixture is set before the channel and the reads follow the pair; an empty
  field changes nothing; a landed stun, an unstopped channel, a shortened or lengthened lockout do not pass.
