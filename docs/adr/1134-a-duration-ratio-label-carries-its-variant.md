# 1134. A duration-ratio label carries its variant

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0126

## Context

Spice: Peacebloom 803700 reduces roots, stuns and snares. A duration_ratio entry's labels (`<spell>
behaviour_duration_ratio`, `<spell> behaviour_expiry`) had no variant, so a second and third entry of the spell
collided (cycle 10 proposal item 1033).

## Decision

A duration_ratio entry may name a `variant`; its readback and expiry labels then end in it. An entry without a variant
keeps its labels.

## Consequences

No existing duration_ratio entry of any class names a variant, so every existing label and scenario is unchanged.
Class 13 gains 803700 `root` (Chains of Ice 29991, SPELL_ATTR3_ALWAYS_HIT, 10000 ms) and `stun` (Stun 2880, magic,
10000 ms), each a readback and an expiry pair.
