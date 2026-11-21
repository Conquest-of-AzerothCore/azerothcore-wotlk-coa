# 0010. Soul Marionette: an enemy already stunned takes the other explosions' damage only

- Status: accepted
- Date: 2026-11-20

## Context

Written 2026-11-21, after the fix, as a catch-up for guide section 7.

Soul Marionette 704497: the five clones explode at the 20th stack, "stunning enemies within $706553a1 yds". All five
explosions 706553 (effect 1 MOD_STUN, 4000 ms, 5 yd) hit the same enemy in the same instant; each later stun climbed
the stun diminishing returns (DRTYPE_ALL) and the zero-duration result removed the aura, so in both final05 runs the
dummy was not stunned (cycle 8 lead R5, M-51).

## Decision

- `OnSpellCalculatedTarget` clears the stun effect (`EFFECT_1`) of an explosion on a target that already holds 706553:
  one explosion stuns, the others deal damage only. This follows the Necromancer's single-stun precedent
  ([Necromancer ADR 0050](../necromancer/0050-command-bonefreeze-casts-once-at-its-target.md)).

## Consequences

- Regression: catalog `witch-doctor-marionette-stun`: a dummy 3 yd away holds 706553 and is stunned 1.5 s later; a
  dummy 12 yd away is not. It passed in sweep 20261121-011354. The stun verdict moved from alert to ok in both final06
  runs (20261121-021022 and 20261121-023852).
