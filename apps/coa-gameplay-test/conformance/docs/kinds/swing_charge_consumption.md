# Swing charge consumption (`kind: "swing_charge_consumption"`, ADR 1309)

ADR 1309 has a provisional number and is renumbered at merge (guide 14.4).

Proves that a timed buff with `ProcCharges = N` (`>= 2`) starts with `N` charges, stays active with `1` charge left
after `N - 1` non-critical melee auto-attacks, and is removed on the `N`th melee auto-attack strictly before its
`DurationIndex` expiry.

## Harness primitive

- Action `attack_until_swings` (`actor`, `target`, `swings`, `timeout_ms`; optional `hand` `0` or `1`, default `0`):
  starts auto-attack (`SubmitAttackSwing`), polls `meleeAttacksByHand[hand]` on every world update, and immediately
  sends `CMSG_ATTACKSTOP` on the tick `done >= swings` (or at `timeout_ms`), recording `swings` and `stopped`
  (`swings` or `timeout`).

## Scenario and arms

- Reads `ProcCharges` (`N`) and `DurationIndex` (`duration_ms`) of `aura` directly from `Spell.dbc`.
- `control`: applies `haste_auras`, triggers `trigger_spell` before `gate_spell` is learned, and requires
  `aura == 0` and `aura_charges == 0`.
- `treatment`: learns `gate_spell`, applies `haste_auras` (for example `62531` and `2116852` so `N` swings finish
  well before `duration_ms`), triggers `aura` with `trigger_spell` (optional `force_crit`), applies `no_crit_aura`
  (for example `64481`, with optional negative `no_crit_amount` such as `-10000` when overriding `FORCED_CRIT_RATING`)
  so auto-attacks cannot crit and refresh `aura`, reads `start` (`aura == 1`,
  `aura_charges == N`), executes `attack_until_swings(swings = N - 1)` and reads `penultimate` (`aura == 1`,
  `aura_charges == 1`), then executes `attack_until_swings(swings = 1)` and reads `final` (`aura == 0`,
  `aura_charges == 0`) with elapsed swing time `< int(0.85 * duration_ms) - trigger_wait_ms` (so total aura age from
  trigger cast stays strictly `< 0.85 * duration_ms`) and `0` swings on the inactive hand (`1 - hand`).
- Any refused cast, crit swing, missed/extra swing, inactive-hand swing, or elapsed time
  `>= int(0.85 * duration_ms) - trigger_wait_ms` voids the run as `unmeasured`.
- `swing_charge_consumption` proves exact swing-count removal before duration expiry; pair it with a companion
  no-swing duration check (such as `duration` or `duration_contrast`) to rule out purely time-driven charge decay.
- Uses `metric = 'aura'` (`EVENT`), so `BEHAVIOUR_METRIC_DELTA` classifies as `behaviour` evidence without changing
  `coverage.py`.

## Refusals

Refuses unknown fields, `ProcCharges < 2`, non-finite aura duration, `gate_spell` in `learn`, invalid `force_crit`
or `hand`, out-of-range waits/timeouts, and a `quote_spell` not embedded in `spell`'s tooltip.
