# 0940. A hit scenario can start at a stated location

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 116.0 (Repulse 680273, "dealing ${$m1+0} Shadow damage and knocking all affected targets back")
is judged by `680273 hit_mean`, which needs 736 hits. In final17 it was `insufficient_trials` with 25 usable hits:
every part casts at one stationary dummy 3 yd away, and the ability script knocks every target it damages back
5.184 yd (`KnockbackFrom(caster, 10, 5)`, AscensionWitchHunterAbilities.cpp:336-337; MotionMaster.cpp:630-631), so
the dummy leaves the 20 yd cone (SpellRadius 207) after a few casts.

## Options

- A caster relocate of the knockback distance after every cast (`hit_relocate`, built and measured on this branch):
  the caster walks 1.15 km per part; from the default start line of sight was lost from cast 11 on (45 of 736 hits),
  and on the Shimmering Flats a dip stopped the dummy at cast 21 while the caster kept walking (105 hits). Removed.
- An opt-in class-file `hit_location` that sets the scenario's existing `location` field: the part starts where a
  collision stops the knockback, so the dummy stays at the first cast's distance without any movement step.
- Moving the dummy back: it is stationary (UNIT_FLAG_DISABLE_MOVE), and a harness action would be harness C++.

## Decision

`hit_location`. The location is a measured fact, not a computed one: Repulse's start (map 1, -6524.53, -3824.85,
-63.3, near acore_world creature guid 21487) was chosen from a diagnostic run in which the walking dummy stopped
against a collision at x -6521.02, and proved by a second run reading the dummy at 3.51 yd after every cast with line
of sight true for all 221. The spot is under water (drowning from about 180 s), so the class file's existing
`cast_auras` sets Water Breathing 7178 (aura 82 only) before each cast. The judged events, their attribution, the
tolerance and what counts as ok are unchanged.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical; neither class file holds the list.
- Seeded tests: every Repulse part carries the location and its rule names it; a mutant without the entry differs
  only by the missing location; unlisted ranks are untouched; malformed entries are refused.
- Pair 20261116-185528 / -185639: 1104 usable hits of 1104 casts in both runs, `680273 hit_mean` ok.
- A map or collision change at that spot moves the result; the diagnostic reads to repeat are in the class file's
  reason.
