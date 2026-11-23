# 0171. School lockouts and positioned taken hits

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0126 (expiry pairs), ADR 0143 (act-anchored arms), ADR 0153 (taken_hit), ADR 0170

## Context

Two Templar claims had no behaviour route after the first attempt of R1:

- Divine Force 806153, "and interrupting non-player spellcasting for $32747d": 807805 casts
  SPELL_INTERRUPT_NONPLAYER 32747 at a creature target. The 3 s school lockout acts only on a creature that is
  casting, and the 6 s stun of the same cast keeps that creature from casting anyway, so no cast attempt can show
  the lockout. The harness had no read of a creature's school lockout.
- Testament of Hope 1397742, "While within $704409a1 yds of you": the copies stand 2.5-3.5 yd from the owner, so no
  arm put a copy outside the 15 yd radius.

## Options

1. A stun-immune casting creature and timed cast attempts. The harness casts creature spells as triggered spells,
   which skip the lockout check (Spell.cpp:5835), so the attempts would prove nothing.
2. A read-only harness metric of the lockout itself, and an expiry pair on it.
3. For the radius: relocate the owner away from the copies. The copies walk back every 500 ms, so the arm races
   their movement.
4. For the radius: select a dummy at a stated distance. The copies attack the owner's selected enemy
   (AscensionTemplarSummons.cpp UpdateAI) and stay there.

## Decision

Options 2 and 4.

- Harness metric `school_prohibited` (`Creature::IsSpellProhibited` for `school_mask`), a read with no action.
- Behaviour kind `school_lockout`: the dummy channels an interruptible spell on itself, the caster casts an instant
  spell at it, and the lockout of the channel's school is read as an act-anchored expiry pair at the DBC duration
  of the interrupt spell. The pair needs the channel running and the school free before the cast.
- `taken_hit` `targets` (extra dummies at stated distances) and arm fields `select`, `select_settle_ms` and
  `checks` (harness asserts on where the copies stand).

## Consequences

- Without the new fields every scenario regenerates byte-identical.
- Seeded tests: a lockout held 6 s, a shortened one and a missing one alert; a dummy that was not channelling is
  unmeasured; a spell an interrupt cannot stop is refused.
- The radius bracket is a measurement of where the copies stood (2D centre distance), not of the radius itself:
  reduced within 16.5 yd, not reduced beyond 20 yd. With the combat reaches the engine adds (owner 1.5, copy 2.25),
  that is an edge distance of at most 12.75 yd and at least 16.25 yd, around the stated 15.
