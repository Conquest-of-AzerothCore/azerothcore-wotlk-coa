# 0006. Malignant Jinx: the jinxed enemy casts the silence on itself

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Malignant Jinx 803678: "causing their next spell cast to silence them for 5 sec." The silence 803732 names
TARGET_UNIT_CASTER, and the class hook cast it as `doctor->CastSpell(jinxed, 803732)`, so the target resolved to the
Witch Doctor: in both final05 runs the doctor carried 803732 and the Jinxed enemy did not (cycle 8 lead R2 F1).

## Decision

- The hook has the Jinxed unit cast 803732 on itself, triggered, with the Witch Doctor as original caster.

## Consequences

- Regression: catalog `witch-doctor-malignant-jinx-silences-target`: after a real Renew by the Jinxed enemy it
  carries 803732 and its next Renew is refused, and the Witch Doctor carries no 803732 and still casts. It passed in
  sweep 20261121-011354. The silence verdict moved from alert to ok in both final06 runs (20261121-021022 and
  20261121-023852).
