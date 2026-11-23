# 0008. The Eye of Kimbul mark removes and refuses stealth and invisibility

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Eye of Kimbul 503714 marks a critically struck enemy with 802707: "While affected, enemies cannot stealth or turn
invisible." 802707 has only auras 271 and 308 and no code stopped a marked unit from stealthing: both final05 runs
kept the stealth and invisibility auras on the marked dummy (cycle 8 lead R3 (b)).

## Decision

- When the mark lands, the event handler removes the target's stealth and invisibility auras
  (`SPELL_AURA_MOD_STEALTH`, `SPELL_AURA_MOD_INVISIBILITY`).
- `OnSpellCheckCast` refuses a spell with either aura while the caster carries 802707, with
  SPELL_FAILED_CASTER_AURASTATE.

## Consequences

- Regression: catalog `witch-doctor-eye-of-kimbul-blocks-stealth`. Unmarked, the enemy enters Stealth Dummy 2144558
  and Head of the Horseman Invisible 44312; marked, both casts fail with reason 22 and no aura lands. It passed in
  sweep 20261121-011354.
