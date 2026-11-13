# 0152. Cooldown cost gates may use the accelerated cap

- Status: accepted
- Date: 2026-11-11

## Context

ADR 0139 gave expiry scenarios the one-hour game-time cap of the simulated clock and kept the ten-minute budget for
every other conformance scenario. A cooldown cost gate times three arms from a priming cast, each near the gated
spell's cooldown. Eternally Devoted 573452 ("Damage dealt through Eternal Blessing now reduces the cooldown of
Libram spells by $/1000;806106s1 sec.") gates Libram of Tenacity 801461, whose cooldown is 180000 ms: its scenario
waits 549400 ms, over the 540000 ms the ten-minute cap leaves after the 60000 ms margin, so `generate` refused it.
The arms cannot be split over scenarios without repeating the 180 s priming wait in each.

## Considered options

1. Keep the cap and leave the clause on its cooldown readback. Rejected: the cast-gate arms are the behaviour route.
2. One scenario per arm. Rejected: each arm still needs its own priming cast and wait, and the arms would no longer
   share the learned-talent order the judge relies on.
3. Give cooldown cost gates the accelerated cap, as expiry scenarios have. Chosen: `generate` already validates
   every scenario for the simulated clock (`conformance.py`, `run.validate(scenario, run.SIMULATED_CLOCK)`).

## Decision

`cost_gate_scenario` passes `hits.MAX_ACCELERATED_SCENARIO_MS` to `timed` when `resource` is `cooldown`. Power cost
gates keep `MAX_SCENARIO_MS`. A scenario this produces beyond the real-pace cap runs only on the accelerated clock.

## Consequences

- No existing scenario changes: `timeout_ms` is the summed waits plus the margin whatever the cap.
- A cooldown gate over ten minutes is refused by a `--gameplay-clock real` run, as an hour-long expiry scenario is.
- Test: `test_behaviours.CostGateScenarioTests.test_a_cooldown_gate_beyond_the_real_clock_cap_runs_accelerated_only`.
