# 0710. A proc rate can count hits taken from a striker

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Vengeful Intent 705534 (Witch Hunter): "Whenever you take direct damage or avoid an attack you now have a $h%
chance to strike back" (key 278.0); Dawn Knight 680497 names avoiding damage too (140.0). The proc entries had cast,
attack and minion triggers only. Mentor decision D-158 (design D-12, the chance version of D-5).

## Options

- Proc triggers `taken_hit` (a striker's spell hit as the trial) and `avoided` (D-5's avoided swings).
- `taken_hit` only this cycle.

## Decision

`taken_hit`: a stationary striker casts the trigger spell at the caster, the caster's health set to full before
each strike, each damage event of the spell on the caster a trial; an optional baseline runs the same strikes before
the learn. `avoided` for proc rates is not built: the proc judge reads one trial label, and the parry sum of D-5
would have to reach its baseline and between-part reads, and 680497 also rolls on the caster's own auto attacks
(the engage swings of the avoided setup); larger than its effort (cycle 11 tool report).

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical.
- Witch Hunter: `705534 proc_rate` (Light of the Naaru 41394 from creature 36), pair 20261115-210153 / -210225 ok,
  129 / 1382 and 115 / 1371, none in the baseline. The ledger splits the clause; "or avoid an attack" stays unproven.
