# 0234. A cost gate for a raised cost and a removed cooldown

- Status: accepted
- Date: 2026-11-12

## Context

Justicar of the Light 707663: "Removes the cooldown from Benediction, but increases its Energy cost by $s2." Claims 261
and 262. A cost gate modelled a lower cost and a shorter or longer cooldown; a higher cost and a cooldown cut to zero
were `NotModelled` (no `beyond` level below zero, a wait under the global cooldown).

## Decision

- A negative `reduction` on a power gate is a raised cost. Arms: `without` at the base cost (through), `base` with the
  talent at the base cost (refused, 85), `with` at the raised cost (through) and `beyond` one point below it (refused).
  A raised cost that is not a whole number, or not above the base by more than one point, is `NotModelled`.
- A cooldown gate whose `reduction` equals the gated spell's cooldown is a removal. Both arms attempt the spell
  `margin_ms` after the global-cooldown wait (1600 ms) from the priming cast: refused without the talent (67), through
  with it. No later wait is refused, so there is no `beyond` arm. A cooldown not above that wait is `NotModelled`.

The existing cooldown-lengthening entry (Patience 712678) and every other entry regenerate byte-identical.

## Consequences

- On build 2a99d5b855eb, both runs (20261112-031521 / -031601): Benediction at 20 Energy goes through without the
  talent and is refused with it, goes through at 30 and is refused at 29; Benediction 2100 ms after a priming cast is
  refused without the talent and goes through with it.
- The removal arm shows a cooldown below 2100 ms, the finest wait the global cooldown leaves.
- Seeded tests: the arms and levels of both shapes, a `with` refusal alerts, an increase with no whole level between is
  `NotModelled`.
