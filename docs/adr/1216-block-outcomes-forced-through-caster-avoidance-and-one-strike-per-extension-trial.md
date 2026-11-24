# 1216. Block outcomes forced through caster_avoidance, and one strike per extension trial

- Status: proposed (provisional number)
- Date: 2026-11-22
- Related: [ADR 0735](0735-a-metric-delta-strike-can-be-avoided-as-set.md) (`caster_avoidance`),
  [ADR 1195](1195-sequenced-casts-earn-a-proc-aura-and-space-hits-around-a-timer.md) (the O-20 block fixture,
  `block_charge_strikes`), [ADR 0581](0581-behaviour-kinds-are-modules-discovered-at-run-time.md) (kind modules).
- Decided by: mentor D-176 (block 0 to 100 in `caster_avoidance`) and D-217 (the `block_extension_trials` kind and
  its conditions), Sun Cleric round B group b3.

## Context

Sunflare Aegis 707629: "Blocking attacks now has a 30% chance to grant you Hammer of Kings for 4 sec. If Hammer of
Kings is already active, you increase the duration by 4 sec." The class script accepts a received block when its own
roll of ProcChance 30 passes, prevents the default trigger and calls `Extend(player, 804751, 4000)`: it casts Hammer
of Kings 804751 with a 4000 ms duration when absent and adds 4000 ms when present. The roll ignores the forced-chance
spell modifier, so a proc cannot be forced. An extension casts nothing, so it is seen only in the aura's expiry.

The `caster_avoidance` option set dodge and parry only, and no kind judged an aura's expiry after a block.

## Options

- One `metric_delta` entry: cast Hammer of Kings, 24 blocked strikes, one presence read. Rejected for the extension:
  the number of extensions m is unknown, the expiry is 12 + 4m s, and no read excludes the upper side of 4 s +-10%.
- Reading `aura_duration_ms` after each strike. Rejected: a readback, not behaviour.
- One blocked strike per fresh application, every trial judged on game-time stamps (chosen, D-217).

## Decision

- `caster_avoidance` takes an optional `block` of 0 or 100 for a strike at the caster. It is copied into every
  `set_combat_avoidance` step, and two guard reads (`spell_damage_count` of the strike, `blocked` true and false)
  follow the before and after readings. At 100 every strike so far must be blocked, at 0 every strike must be an
  unblocked hit, else the run is unmeasured; a match keeps the reading's verdict. Without `block` the steps,
  contract and model are byte-identical.
- `kinds/block_extension_trials.py`: `trials` trials of {remove the aura, cast it, block 100, one strike, blocked and
  unblocked counts, eight stamped presence reads}. A trial whose strike is not one blocked hit is void. Each other
  trial's expiry bracket must lie inside the base band (DurationIndex +-10%) or the extended band (base + extension
  effect, +-10%); outside both alerts, straddling an edge is unmeasured, no extended trial is unmeasured. The extended
  share and its 99% interval are reported, never judged (the 30% rate is a G-20 question).
- Mutants in the seeded tests: a 3 s and a 5 s extension alert, base durations of 10 s and 14.5 s alert, a server
  that never extends is unmeasured.

## Consequences

- The rate claim is not proven by these entries: the 28..32% band needs thousands of blocks per arm (G-20).
- A trial costs about 17 s of game time: 24 trials hold the residual of no extended trial at 0.7^24 = 1.9e-4 per run.
- Finished-class scenarios do not change: both additions are opt-in.

## Addendum (D-228, D-230): `block: 0` and `mode: "grant"`

The `metric_delta` zero arms (a whole-run guard) failed twice: about 4% of strikes are blocked at block 0 with the
shield on, which made every run unmeasured. Both zero arms now judge per trial.

- `block: 0` on the extension trials: a strike blocked anyway voids its trial, every judged trial must keep the base
  duration, at least 24 judged.
- `mode: "grant"`: one strike per trial on a caster whose aura was removed and read absent first; void when the strike
  was not as forced or the aura was on before it. Block 0: no grant on any judged trial. Block 100: the share of
  trials showing the aura is judged against `chance_pct` +- `half_width_points` (30% +- 1.6, the mentor band),
  pooled over `parts` scenarios of at most 10000 steps, with a control arm before the talent is learned.
- Seeded mutants: 25% and 35% rates alert, a grant on an unblocked strike alerts, a grant before the learn alerts,
  too many void trials are unmeasured.
- Both are opt-in: existing entries generate identical scenarios.
