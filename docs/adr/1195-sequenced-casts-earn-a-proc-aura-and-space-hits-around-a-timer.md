# 1195. Sequenced casts earn a proc aura and space hits around a timer

- Status: proposed (provisional number)
- Date: 2026-11-22
- Related: [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md) (kind modules),
  [ADR 0120](0120-two-proof-statuses-computed-by-clause-coverage.md) (evidence tables).
- Decided by: owner ruling O-17 (Sun Cleric Q-sc-7, both harness actions approved) and owner ruling O-20 (the block
  fixture). These rulings are the G-39 approval of the harness actions; design notes went to the controller before
  the harness C++ was edited.

## Context

Five Sun Cleric claims could not be expressed. Spears of Glory 804629 "Your next Dawnsear is instant cast and deals
25% increased damage" was measured with `set_aura` of 807299, the claim's own aura, which guide 3.4 forbids (review b7c
C1): the aura comes from a 15% roll per Radiant Flame tick, and a fixed sequence of casts leaves too many runs without
it. Hope 300349 and Censure 300371 "Can occur only once per sec." need two real hits about 1 s apart, but the global
cooldown (1500 ms) forbids a second real cast that close. Paying The Tithe 680647 / 681468 "your Seraphic Bulwark now
lasts for N additional blocks" was a readback of the aura's charges: no fixture could force real blocks. The harness steps are a linear list: no repeat, no condition,
and `reset_cooldown` clears only the spell's own cooldown.

## Options

- `set_aura` of the proc aura, or `.cast ... triggered` for the second hit. Rejected: the first is the review finding;
  the second sets the disallow-proc flag and skips cost and cooldown, so it is not the real cast.
- An unrolled run of N feed casts and one read. Rejected: the aura lasts 10 s, about two feed casts, so the read misses
  it far above 0.1% per pair.
- Two harness actions and two new kind modules (chosen).

## Decision

- Harness: `cast` takes an optional `ignore_gcd` that calls `GetGlobalCooldownMgr().CancelGlobalCooldown(info)` right
  before `HandleCastSpellOpcode`; nothing else changes. The new step `cast_until_aura` re-submits the same `cast` path
  (with its `set_power` and `reset_cooldown` fixtures) every `every_ms` of game time while the actor lacks `aura`, stops
  at the first poll that reads it or after `max_casts`, records `attempts` and `stopped`, and never sets the aura.
- `kinds/aura_fed_effect.py`: control trials cancel the aura, treatment trials earn it through `cast_until_aura`; every
  trial reads the aura right before the judged cast, and a disagreeing read makes the run unmeasured, never ok.
  The instant variant reads `casting` 300 ms into the judged cast and its `spell_go_count` after the cast ends: a fed
  cast that did not go off alerts, a control one makes the run unmeasured (review t8 I1). The damage variant compares
  the mean non-critical hit of the two arms against `expected x (1 +- EffectDieSides / control mean)`: the band is the
  dice envelope of the hit itself, narrower than the G-19 band, so it risks only false alerts (review t8 M2). It
  accepts one usable hit per arm and states the counts it judged.
  `max_casts` comes from the DBC ProcChance and tick count of the feed for a residual of at most `residual_target` per
  pair.
- `kinds/timer_spacing_arms.py`: two arms of two real hits, the second cast `ignore_gcd` inside `[timer - 10%, timer)`
  and `(timer, timer + 10%]`; an arm counts only when its measured event spacing lies in its band (10% band of review
  b7a I3). Expected 1 effect blocked, 2 allowed. A cooldown cut is counted as a whole number of cuts in a window bounded
  by the summed step `elapsed_ms` (a `snapshot` carries no game-time stamp).
- Harness, O-20: `set_combat_avoidance` takes an optional `block` percent, applied as a `CR_BLOCK` rating through
  `Player::ApplyRatingMod` so `UpdateBlockPercentage` keeps it (no engine edit); a repeat replaces the previous
  fixture, `Dismiss` removes it, and a chance below the key fails the step unless `rejected: true`.
  `kinds/block_charge_strikes.py` counts the real blocks Seraphic Bulwark lasts without and with Paying The Tithe,
  one strike past the expected count, every strike required to be a blocked hit.
- The kinds use the existing check `behaviour_metric_delta` and existing metrics, so no evidence row is added.

## Consequences

- Every new key is optional and both kinds are new names: no existing scenario changes, and the finished classes
  regenerate byte-identical.
- The cooldown window widens with `max_step_ms`; a run with long world steps can be unmeasured, not wrong.
- The fed trials cost game time (about 1.8 feed casts per trial expected); the cap only bounds the worst case.
