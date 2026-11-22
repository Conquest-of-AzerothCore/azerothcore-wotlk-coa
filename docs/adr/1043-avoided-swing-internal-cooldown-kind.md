# 1043. Avoided-swing internal cooldown kind

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
