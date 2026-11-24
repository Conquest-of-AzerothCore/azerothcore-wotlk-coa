# 1268. Debuff resist rate judges a resist chance against learned arms

- Status: proposed
- Date: 2026-11-24
- Related: [Felsworn ADR 0026](conformance/felsworn/0026-owner-ruling-o-28-doomstride-doubles-the-resist-chance.md)
- Decided by: Felsworn mentor decision D-93 (2026-11-24).

## Context

Doomstride 804613 doubles the chance to resist a Curse or Magic effect while at full health, at most once every 10
seconds (owner ruling O-28). The `taken_hit` `resist_rate` judge compares a treatment arm that sets its auras by
`set_aura` with a control, by an expected point difference; its trial steps ignore an arm's `learn` and the caster's
health (`behaviours.py`, `taken_rate_arm_steps`). The proof needs a real learn between the arms (D-91), a
below-full-health arm and a rate expectation of 1 - (1 - p)^2, and the lockout needs a resist that the passive
itself produced.

## Options

- Extend `taken_hit` in `behaviours.py`. Rejected: a shared tool core file (guide 14.2).
- A new kind module, additive, judged by the module.

## Decision

`kinds/debuff_resist_rate.py` (doc `docs/kinds/debuff_resist_rate.md`), checks `behaviour_metric_delta` on the
`aura` event metric, two modes:
- `rate`: a striker without a spell hit bonus casts `strike_spell` at the caster; control trials before the real
  learn of the entry's spell, then treatment trials at full health and low-health trials. Each arm's resisted share
  is judged by its Wilson 99% interval inside the G-20 band of its stated chance (control and low health p,
  treatment 1 - (1 - p)^2); trials are sized so a conformant server leaves a band with probability at most
  `residual` (default 1e-3) per arm and run.
- `lockout`: after the real learn, a priming strike; a trial is primed when the lockout aura is on the caster. The
  judged strike's resisted share on primed and unprimed trials must each hold its own chance and exclude the other's
  in a Wilson 99% interval; an expiry arm reads the lockout aura inside and past its duration on primed trials.

## Consequences

- No shared file changes; finished classes do not use the kind, so their generated scenarios are unchanged.
- Unit test `kinds/test_debuff_resist_rate.py`, with the mutants: no second roll, the guaranteed resist, a
  full-strength low-health arm, a lockout that does not block, and a lockout aura that ends early or never.
