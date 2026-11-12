# 0201. A hit-ratio expectation from the hit model

- Status: accepted
- Date: 2026-11-12
- Supersedes: the last consequence of ADR 0183 (the 570205 spell power claim left to the route agent)

## Context

Righteous Tempest 805409, "scaling with spell power". Its hit 570205 is 100% normalized weapon damage plus 154 plus
0.3 x spell power, then the class aura and the dummy's armor. A first estimate of the expected ratio for +220 spell
power (1.279) read 1.254, and ADR 0183 left the claim to the route agent. The review (M11) found that no ADR recorded
how the claim was later closed and that no test tied the expected value to its source.

## Decision

The expected ratio is the hit model's: `hits.rank_hit` for 807274 at the reference stats (172.40) and at spell power
+220 (220.20), 1.2773. The earlier reading was the test's design: the spell power aura (Power of the Ashtongue 1140480,
5000 ms) lapsed inside the read and a set on a present aura did not restart it. Each trial now removes the Tempest,
restarts the aura and reads the hits at 0 to 3000 ms. A seeded test recomputes the ratio from the model and compares
it with the class-file value, so a change to the model cannot leave the constant stale.

## Consequences

- Righteous Tempest reads +27.75% and +27.68% against +27.73%.
