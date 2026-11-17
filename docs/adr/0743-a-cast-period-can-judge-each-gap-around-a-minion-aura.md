# 0743. A cast period can judge each gap around a minion aura

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 282.0 (Scent of Magic 706260, "causing your Shadow Hound's next Shadow Leap to incur a
$/1000;800528s1 sec reduced cooldown") needs the gap after one leap: the hound's auto leap fires 20 s after the last
one, 10 s when it holds 800528, which the leap removes (`AscensionWitchHunterSummons.cpp:115-136`); each landing casts
Shadowhound Strike 706332 twice (:213-229). `cast_period` judges a mean period of single casts after a cast trigger.
Gap design O1 (c13 gap designs), mentor ruling D-201.

## Options

- `cast_period` options: an aura on the owned creature at a point of the window (`minion_auras`), events of several
  casts (`casts_per_event`), a judge of each gap (`gaps_ms`), and a pet attack command after the trigger
  (`pet_attack`): the diagnostic runs showed that a hostile cast at the dummy does not engage the summoned hound.
- A new kind: it would repeat the summon, the control and the polls.

## Decision

The options, absent by default. Each gap is bracketed between the polls around its two events and judged in its own
G-19 band; the gaps before and after the aura are the control gaps of the same window.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); the two
  Necromancer cast_period entries keep their model.
- Seeded tests: the aura step sits before its poll and the plain entry has no gaps; events at 4000, 2000, 4000 ms
  pass, an unshortened or a shortened control gap alerts; the mutant that counts single casts as events alerts, two
  events are unmeasured; the pet command follows the trigger only when asked; malformed options are refused.
- Witch Hunter: `706260 behaviour_metric_delta leap_gaps`. Pilot 20261116-070532: gaps 19950-20168, 9810-10028 and
  19947-20165 ms, ok. Without the pet command the hound never engaged (diagnostic 20261116-070338).
- The aura is set by the harness on the hound: the entry measures the reduction 800528 makes, not the critical strike
  of 706260 that applies it.
