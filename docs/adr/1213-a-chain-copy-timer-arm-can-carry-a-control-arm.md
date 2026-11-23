# 1213. A chain-copy timer arm can carry a control arm

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Censure 300371 "Dealing direct damage to an enemy affected by Chains of Light will now cause it to chain to
a nearby enemy.": the `timer_spacing_arms` `chain_copy` entry shows copies spreading with 300371 learned, but has no
arm without it, so the chain itself is not contrasted.

## Decision

A variant `chain_control` of `timer_spacing_arms` (ADR 1195): `chain_copy` plus a control arm before `spell` is learned,
the same seed and two hits `gaps[1]` ms apart, expected 0 new copies. A variant rather than a key because the
scenario key is built from the entry's variant, so a second `chain_copy` entry of one spell would collide.

## Consequences

- Opt-in; `chain_copy` and `cooldown_cut` are unchanged and the finished classes regenerate byte-identical.
- Seeded tests: no copy before the learn with 1/2 after is ok; a copy before the learn, or no copy after, alerts; a
  control arm out of band or not opened is unmeasured.
