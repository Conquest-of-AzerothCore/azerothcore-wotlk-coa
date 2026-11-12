# 0204. Immunity read on a grouped ally

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0134 (immunity checks carry their control arms), ADR 0212 (an ally cast target)

## Context

Testament of Will 801455, claim 312: "Break an ally free of worldly constraints, making them immune to all movement
impairing effects for $d." It targets an ally only (TARGET_UNIT_TARGET_ALLY), so the `immunity` kind, which casts the
spell on the caster and lands its fixtures there, could not run it. The 10 s window alone was proven by an expiry pair.

## Considered options

1. Read the server's immunity predicate on the ally. It is a readback, not an applied effect.
2. Let the `immunity` kind take the grouped ally as its subject. Chosen: the same arms, on another unit.

## Decision

`immunity` takes `target` (`caster`, the default, or `ally`). With `ally`, the ally player is added and grouped after
the base steps; the dummy sets and casts each fixture at the ally, the spell is cast at the ally, and every aura reading
is the ally's. Fixtures for 801455 (aura 147 mask 65: slows and roots, SpellInfo.cpp:2723-2734): Chilled Blood 35317
(aura 33) and Net 47021 (aura 26), each a single aura effect.

## Consequences

- Claim 312: both fixtures land before the cast, neither lands inside the window (three casts each), both land after it.
- Caster entries regenerate byte-identical (1693 of 1693 for ADRs 0204-0208 together, 11 new scenarios).
- Tests: `test_behaviours.AllyImmunityTests`; a fixture landing inside the window alerts.
