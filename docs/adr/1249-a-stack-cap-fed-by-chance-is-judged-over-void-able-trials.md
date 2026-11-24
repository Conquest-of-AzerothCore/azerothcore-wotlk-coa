# 1249. A stack cap fed by chance is judged over trials that can be void

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: mentor D-18 (Felsworn 14, Malice of Gul'dan 800214 "stacking $u times", tool group fw-tg-stack),
  controller go 2026-11-23 (residual from the measured void rate)

## Context

The finished classes prove a stack cap with a `metric_delta` that reads `aura_stacks` after cap + 1 feed casts, each
of which applies the aura. Malice of Gul'dan applies Felstrike 802678 (cap 3, 6000 ms) only on a direct critical
strike that also passes `Chance()` on the raw ProcChance 60 (AscensionFelswornEvents.cpp:97-98, :227-229;
AscensionFelsworn.cpp:231-239), which no spell modifier forces. One reading then fails a correct cap whenever fewer
than cap + 1 rolls succeed or two applications are more than the duration apart (34% of runs in fw-b1b's simulation).
`cast_until_aura` cannot feed stacks: its counter restarts per step but it stops on the first `HasAura`.

## Options

- A plain `metric_delta` with more feed casts: the failure share falls but stays a false alert, never a void.
- The encounter timeline (`timeline_count`, `timeline_interval_max_ms`): one timeline per scenario, so its counts and
  intervals mix every trial of a run.
- Polls of the existing `aura_apply_count`, `aura_stacks` and `game_time_ms` after every feed cast, per trial.

## Decision

The `metric_delta` option `stack_feed` (`{aura, cap, window_ms, trials, source}`, optional `refeed_auras`) repeats the
treatment phase as N trials and polls the apply count, the stacks and the game time at the start, after every feed cast
and at the end of each. Any stacks read above the cap alerts its trial before the void checks, so a cap that breaks only
in an otherwise void trial still fails (controller go after review I4). Otherwise a trial is void without cap + 1
applications, with a span between application brackets or to the end read of `window_ms` or more, with stacks at its
start or with the aura gone at its end; a valid trial passes when the most stacks read equal the cap and alerts above or
below it. The control phase must read 0. The verdict reports v = voided / N and the residual v^N, which an entry sizes
to at most 0.05% from the larger v of its counted pair. Python only, opt-in, default off; the evidence metric stays
`aura_stacks`.

## Consequences

- Test: `StackFeedTests` (metric_delta_options/test_stack_feed.py), with the seeded mutants: a read above the cap
  (also inside a trial that is otherwise void) and a cap one below the tooltip alert; too few applications and a gap
  past the window are void, not failures.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- An expiry and a re-application inside one poll interval can only be excluded through the poll spans, so the polls
  must be well inside the window (`setup_wait_ms`, `wait_ms` below `window_ms`).
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/stack_feed.md`.
