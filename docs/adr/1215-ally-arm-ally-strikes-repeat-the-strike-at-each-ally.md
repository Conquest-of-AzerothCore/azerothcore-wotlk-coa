# 1215. Ally arm ally strikes repeat the strike at each ally

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Scroll of Hope 680646: "If any ally falls below 35% of their maximum health while this is active they are instantly
healed once". The proc needs a damaging hit received while below 35% (AscensionSunClericEvents.cpp:78-79), and the
entry striker struck only the caster (`strike_cast_steps`), so "any ally, once for each ally" stayed open. The harness
creature `cast` resolves any unit id as its target (code reading only). Mentor D-199, D-214.

## Options

- Harness C++ for an ally striker: not needed, the creature cast already takes a unit id.
- An opt-in `ally_strikes` flag on `ally_arm` that reuses the entry's `strike`.

## Decision

`ally_strikes: true` with a `strike` that has `after_trigger_ms`, no `owned_entry` and no `dx`: after the caster's
strikes (at the phase steps in an uncast before phase) each ally is set to the strike health and struck `count` times.
The caster's `spell_go_count` of the striker's spell (`caster: striker`) is read around each ally's strikes; a count
that did not grow by `count` voids the trial (`unmeasured`).

## Consequences

- Opt-in; the finished classes regenerate byte-identical.
- Seeded tests: the strike order and reads, a malformed option refused, landed strikes keep the verdict, and the mutant
  of a strike that did not land voids it.
- Not verified before the pair: that the striker's SPELL_GO reaches the caster's observer for a strike at an ally.

- Amendment (mentor D-224, same provisional number): `ally_strikes` may be `{"health": N}`, which sets the allies'
  health to N (at most the strike's `max_health`) instead of the strike health; the caster keeps the strike health. `true`
  generates as before.
