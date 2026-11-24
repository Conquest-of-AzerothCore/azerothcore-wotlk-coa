# 1268. Debuff resist rate judges a resist chance against learned arms

- Status: proposed
- Date: 2026-11-24
- Related: [Felsworn ADR 0026](conformance/felsworn/0026-owner-ruling-o-28-doomstride-doubles-the-resist-chance.md)
- Decided by: Felsworn mentor decision D-93 (2026-11-24); residuals and the primed share amended after review
  fw-rf1 (I-1 to I-3, 2026-11-24), and the rate sizing after review fw-rf1b (I-2b, 2026-11-24, go from the mentor),
  before merge.

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
  treatment 1 - (1 - p)^2). `residual` (default 1e-3) is the probability that a conformant server fails a claim's
  labels in a counted pair of 2 runs: each of the 3 arms is sized so it leaves its band with probability at most
  `residual` / 6 per run. The size is exact: the smallest trials per part whose binomial false-fail through the
  judge (the sum of the binomial probabilities of every resisted count the judge does not pass) meets
  `residual` / 6; the contract states each arm's figure and the pair total.
- `lockout`: after the real learn, a priming strike; a trial is primed when the lockout aura is on the caster. The
  judged strike's resisted share on primed and unprimed trials must each hold its own chance in a Wilson interval at
  the z of `residual` / 12 (two-sided) and exclude the other's chance in a Wilson 99% interval; the primed share of
  the locked trials must hold (1 - p) p in the same wide interval, so a lockout started by anything but the resist
  of the second roll alerts. Half of `residual` goes to these 3 holds over 2 runs; the generator computes the rest
  (a group count below its exclusion minimum, an interval that keeps the other chance), refuses an entry whose
  total per pair exceeds `residual`, and states the total in the contract. An expiry arm reads the lockout aura
  inside and past its duration on primed trials.

## Consequences

- No shared file changes; finished classes do not use the kind, so their generated scenarios are unchanged.
- Unit test `kinds/test_debuff_resist_rate.py`, with the mutants: no second roll, the guaranteed resist, a
  full-strength low-health arm, a lockout that does not block, a lockout started by any landed effect (primed
  share (1 - p)^2 instead of (1 - p) p), and a lockout aura that ends early or never.
- A single 99% interval per arm or group would give a conformant pair about 1% false alerts per check; the residual
  split keeps a claim at or below `residual` per pair, at the cost of more trials. A normal approximation at the
  expected chance undersizes the arms: the Wilson interval at the band edge is wider than at p and the binomial tail
  is skewed, so the earlier 3860 / 7270 / 3860 trials of a 4% chance failed a conformant claim with probability
  4.5e-3 per pair, not 1e-3 (review fw-rf1b I-2b). Sized exactly, the Doomstride rate arms run 4466 / 7656 / 4466
  trials (11 parts of 406 / 696 / 406; 10 parts would need 10031 steps, above the 10000 step limit) and a conformant
  server fails each claim with probability 9.79e-4 per counted pair.
- The false-fail is not monotonic in the trials (a 4% arm over 10 parts meets `residual` / 6 at 449 trials per part
  and not at 450), so the size is the first count that meets it, and the unit test checks the exact figure of the
  class entries.
