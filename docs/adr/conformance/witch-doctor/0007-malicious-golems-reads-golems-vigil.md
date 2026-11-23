# 0007. Malicious Golems reads Golem's Vigil

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Malicious Golems 705912: "... will reduce the cooldown of War Golem by $/1000;707333S1 sec." Golem's Vigil 707333
effect 0 is aura 165 with BasePoints -501 and DieSides 1, so -500 ms, 0.5 sec. The proc called
`Reduce(player, WarGolem, 1000)`: both final05 runs read a War Golem cooldown change of -1000 ms per Hex of Malice
tick (cycle 8 lead R3 (a)).

## Decision

- The event handler reads the cut from 707333 (`Reduce(player, WarGolem, abs(Amount(GolemsVigilCut)))`) instead of the
  literal 1000.

## Consequences

- Regression: catalog `witch-doctor-malicious-golems-half-second`: without the talent a Hex tick sends no War Golem
  change; with it the change is -500 ms. It passed in sweep 20261121-011354. The verdict moved from alert to ok in
  both final06 runs (20261121-021022 and 20261121-023852).
