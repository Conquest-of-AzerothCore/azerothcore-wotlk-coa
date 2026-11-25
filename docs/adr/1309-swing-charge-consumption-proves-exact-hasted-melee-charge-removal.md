# 1309. Swing charge consumption proves exact hasted melee charge removal before aura expiry

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39; G-39 harness note

## Context

Cultist Saronite Blessing `301262` (embedded `600327`, `Spell.dbc`) states `"Lasts for $d or $n attacks."` where
`$d` is `DurationIndex 8` (`15000 ms`) and `$n` is `ProcCharges = 10` (`AscensionCultistContracts.cpp:242-243`,
`AscensionCultistEvents.cpp:109-110,290-293`). Row 85 of `cultist_clauses.json` proved `$d` (`15000 ms`) by
behaviour, but left `r85[1]` (`"$n attacks"`) at `data` evidence (`initial_charges` reads `aura_charges`, a
`READBACK` metric) and `r85[2]` (`"or $n attacks"`) as a tool gap for two reasons:

1. Heretic's weapon set uses War Staff `2535` (`3300 ms`; `2640 ms` with `600327`'s `+25%` melee haste), which
   delivers at most `6` swings inside `15000 ms`, so the duration expires before `10` swings can occur without haste
   fixtures.
2. `metric_delta`'s `attack_swings` uses a single nominal `N * swing_interval` wait and one before/after read, so it
   cannot stop after exactly `N - 1` swings to prove `aura == 1` (`charges == 1`) and then stop after exactly `1`
   more swing to prove `aura == 0` (`charges == 0`) strictly before `15000 ms` while guarding against crit refreshes.

## Options

- Reclassify `aura_charges` as `behaviour` in `coverage.py` and widen `behaviours.py`'s `attack_swings`. Rejected:
  `aura_charges` alone is a readback that does not prove attacks consume charges, and altering `behaviours.py` risks
  moving existing `attack_swings` scenarios.
- Add an opt-in harness action `attack_until_swings` and a dedicated opt-in behaviour kind
  `swing_charge_consumption` (`ORDER = 58`) modeled on `block_charge_strikes`. Chosen.

## Decision

1. **Opt-in harness action `attack_until_swings`** (`CoAGameplayTest.cpp`, `run.py`):
   - Takes player `actor`, `target`, `swings` (`1..50`), `timeout_ms`, and optional `hand` (`0` or `1`, default `0`).
   - Records `actor.meleeAttacksByHand[hand]` at step start, calls `SubmitAttackSwing(player, target)`, polls on each
     world update, and immediately sends `CMSG_ATTACKSTOP` on the tick `done >= swings` (or at `timeout_ms`).
   - Inert outside scenarios that explicitly invoke it; leaves `attack`, `stop_attack`, and `wait` untouched.
2. **Opt-in behaviour kind `swing_charge_consumption`** (`kinds/swing_charge_consumption.py`, `ORDER = 58`):
   - Reads `ProcCharges` (`N >= 2`) and `DurationIndex` (`duration_ms > 0`) of `aura` directly from `Spell.dbc`.
   - Runs an unlearned control arm (alerts if `aura != 0` or `aura_charges != 0`), then learns `gate_spell`, applies
     haste fixtures (`62531`, `2116852` -> `660 ms` swings on `2535`), triggers `aura`, applies `no_crit_aura`
     (`64481`, preventing crit refreshes), checks `start` (`1 / N`), delivers `N - 1` swings via
     `attack_until_swings` and checks `penultimate` (`1 / 1`), then delivers `1` swing and checks `final` (`0 / 0`)
     within `int(0.85 * duration_ms) - trigger_wait_ms` in game time (total aura age `< 0.85 * duration_ms`) with `0`
     swings on the inactive hand (`1 - hand`).
   - Any refused cast, crit swing, missed/extra swing, inactive-hand swing, or slow window voids the run as
     `unmeasured`. Pair with a companion no-swing duration check to rule out purely time-driven charge decay.
   - Uses `metric = 'aura'` (`EVENT`), classifying as `behaviour` evidence with zero edits to `coverage.py`.

## Consequences

- Strictly opt-in: finished classes regenerate byte-identical (`coverage.py` and `behaviours.py` untouched).
- Unlocks Cultist `301262` row 85 claims `[1]` (`"$n attacks"`) and `[2]` (`"or $n attacks"`) as behaviour evidence.
