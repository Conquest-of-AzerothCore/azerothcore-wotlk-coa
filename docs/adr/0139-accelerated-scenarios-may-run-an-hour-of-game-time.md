# 0139. Accelerated scenarios may run an hour of game time

- Status: accepted
- Date: 2026-11-11

## Context

A scenario's `timeout_ms` was capped at 10 minutes under schema 1 and 20 minutes under schema 2, on both clocks
(`run.MAX_TIMEOUT_MS`, `MaximumTimeoutMs` in `CoAGameplayTest.cpp`). The cap is game time: on the simulated clock a
`wait` advances game time in steps of up to 25 ms per world update, so a long wait costs little real time. On the
Templar batch 1 runs about 2,180 s of game time took 29 s of real time (owner observation, 2026-11-11). The cap,
not the clock, left Righteous Custodian 572808's "for $d" (30 minutes) without an expiry pair: the pair reads the
blessing 1,755 s and 1,845 s after the cast, so its scenario needs about 1,911 s.

At real pace the cap still matters: a case on the real clock, in single mode or in a `pace: real` diagnostic takes
its game time in real time, and the hang rules (`3 * timeout_ms` of real time on the server, `3 * timeout_ms / 1000 +
60` s in the runner) scale with `timeout_ms`.

## Considered options

1. Raise the cap on both clocks. Rejected: a real-clock reference run of such a case would take its full game time
   in real time.
2. Split a long duration over several scenarios. Rejected: an aura does not survive the end of a case, so an expiry
   pair cannot span two scenarios.
3. A second cap for accelerated cases only, enforced where the clock is known, with the existing validation and
   hang rules unchanged. Chosen.

## Decision

- `run.validate(scenario, clock)` takes the clock, default real. `MAX_TIMEOUT_MS` stays the real-pace cap;
  `MAX_SIMULATED_TIMEOUT_MS` is one hour under either schema (`run.timeout_cap`).
- `batch.select_cases` validates an exploratory `--scenario` file for the batch's clock and catalog definitions
  for the real clock, so every catalog case still runs on both clocks and no real-pace diagnostic meets a longer
  case. `verify_all.py` validates exploratory files for `--gameplay-clock` before any stage.
- The worldserver loads a queued case with the one-hour cap only when it runs on the simulated clock and not at
  real pace (`GameplayCase::Load(file, accelerated)`); single mode keeps the real cap.
- The conformance tool keeps its 10-minute budget for splitting casts over parts. An expiry scenario may use the
  accelerated cap (`hits.MAX_ACCELERATED_SCENARIO_MS`), and `generate` validates its scenarios for the simulated
  clock, the default of the gameplay stage.

## Consequences

- Righteous Custodian's expiry pair runs in one accelerated scenario: 1,850 s of game time in 8.5 s of real time
  (runs `20261111-103309` and `20261111-103533`).
- A long exploratory file is refused by `--gameplay-clock real` with "timeout_ms: value is too large".
- A case that hangs waits up to three times its own `timeout_ms` before the runner gives up, so only a case that
  asks for an hour can hold a lane that long.
- Tests: `test_runner.RunnerTests.test_simulated_clock_allows_an_hour_of_game_time_and_the_real_clock_keeps_its_cap`,
  `test_batch.BatchTests.test_only_a_simulated_batch_admits_an_exploratory_case_beyond_the_real_clock_cap`,
  `test_verify_all.GameplayTests.test_exploratory_files_beyond_the_real_clock_cap_need_the_simulated_clock`,
  `test_expiry.TemplarExpiryScenarioTest.test_a_half_hour_end_fits_only_an_accelerated_scenario`.
- The same route agent added two class-agnostic options used by chunk 2 clauses: `attack_swings` and `force_crit`
  on `metric_delta` (Parry Dance's stack cap) and `dual_wield` on attack trigger entries (Zealotry's off-hand
  trigger), documented in the conformance behaviour and trigger pages.
