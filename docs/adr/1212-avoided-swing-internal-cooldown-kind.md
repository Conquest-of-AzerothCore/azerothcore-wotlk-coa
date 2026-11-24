# 1212. Avoided-swing internal cooldown kind

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Protector of the Flame 560492 "Can only occur once per sec.": `Chance(player, 560492, 1000)` gates a proc of
avoided swings. The avoided proc trigger refuses an internal cooldown and `internal_cooldown_gate` casts its own
trigger, which an avoided swing is not; swings cannot be placed at chosen gaps as `timer_spacing_arms` places casts.

## Decision

A kind `avoided_icd` (docs `CONF/docs/kinds/avoided_icd.md`): dense avoided swings from ten strikers (the
`proc_avoided` fixtures, misses counted), a control window before the learn, then the shortest interval between the
proc's hits judged in `[timer - 5%, timer + 5%]`, which excludes a timer 10% off on either side. Void (`unmeasured`)
on a refused cast, an attack-balance miss, fewer than 20 intervals or fewer than 10 avoided swings per hit; the
contract states the residual (at most 2^-20 per run under independent uniform swing phases, an assumption).

## Consequences

- A new kind module, used by no finished class.
- Seeded tests: a simulated 1000 ms timer is ok, 900 ms and 1100 ms timers and no timer alert (mentor D-213), the
  window conditions void.

## Addendum (2026-11-23, mentor D-299): atomic identity reads

Base pair 14 flipped `560492 behaviour_metric_delta icd` (ok in run 1, unmeasured in run 2: 1047 attacks against
1046 dodged, parried and missed). The four identity reads are four assert steps, and the harness runs one step per
world tick (`CoAGameplayTest.cpp` `Progress()`), while the strikers keep swinging: a swing landing between the first
state read and the total read adds to the total only. Before each read group (start and end) the kind now relocates
the caster out of the strikers' reach and waits, reads the distance to each striker (void when it is under the
reach bound), and reads the total before and after the state reads (void when they differ), so a residual race voids
instead of misjudging. Seeded tests and a mutant cover each void; finished classes 15/19/19 --stack/23 generate and
audit unchanged (no finished class uses the kind). `proc_avoided` reads its counts the same way and is not changed
here (owner G-39 list).
