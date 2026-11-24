# 1284. Metric delta: full evidence table for the contrast, an apply stamp after the trigger, attack power arms

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24
- Rulings: mentor D-90, D-111

## Context

Three Felsworn claims stayed open on tool gaps (fw-fa3, fw-rfa3, fw-rfa4):

- 305.1 Fel Rush 806109 "now dashes an additional 20 yds.": the entries read ok in both runs, but
  `behaviours.metric_delta_contrast` looked the metric up in the static `coverage.METRIC_EVIDENCE`. `position_x` is
  a state metric only through the `displacement` option row (`coverage.metric_evidence()`), so the own-cast contrast
  fell back to a condition contrast and the audit classed the claim as data.
- 231.1 Ruin 805748 "over $805748d": `apply_stamp` brackets an aura applied before the trigger cast. The Inner Demon
  DoT is applied by the Ruin hit after a 2500 ms cast and a missile, so every trial read "1 apply after the trigger
  cast" and was unmeasured. The timeline stamps a cast when it goes off (`ALLSPELLHOOK_ON_CAST`), so the game-time
  reads around the cast command do not bound a cast-time trigger.
- 4.1 Burning Commander 92089 "grants you additional Armor and magic resistance based on your attack power": D-90
  asks for a positive off/on delta and a strictly larger delta at a higher attack power, coefficient unasserted.
  `metric_delta` asserts the before reading (Armor reads a stat-derived 270) and has no second attack power level in
  one scenario.

## Options

- 305.1: an opt-in field naming the evidence class per entry; read `coverage.metric_evidence()` in the contrast.
- 231.1: plain game-time reads (cannot exclude 10% with 84 ms of margin); a harness clock read in the timeline base
  (harness C++); read the game time around `encounter_start` and take the apply stamp as an offset from the opening
  (built first: both pair runs alerted with a bracket of about 5500 ms, because `timeline_first_ms` subtracts the boss
  engage time, `CoAGameplayTimeline.cpp:104`); an anchor apply stamped between two game-time reads, compared with
  the apply stamp so that the engage offset cancels.
- 4.1: `monotone` (phase power only); an `after_at_least` from the read baseline (a bound taken from a reading);
  two arms read again at a higher attack power in one scenario, judged on the direction only.

## Decision

- `metric_delta_contrast` reads `coverage.metric_evidence()`. At 21ce665ad0 only Felsworn 806109 `dash_range` and
  `dash_range_torpedo` change contrast (condition to own_cast); a test keeps the two lookups from diverging and no
  module outside `coverage.py` imports the static table.
- `apply_stamp` takes an optional `"applied": "after_trigger"` with an `"anchor"`, a phase aura of the entry. Right
  after `encounter_start` the anchor is removed and set again between two game-time reads; with `d = first - anchor`
  the after reading's age is bracketed as `[game_time after - open_upper - d, read_upper - open_lower - d]` and judged
  against the same window. The trial is void when an apply precedes the trigger cast, when the apply count is not
  exactly one, when the apply precedes the completed cast, when the anchor apply count is not one, or when the apply
  precedes the anchor. No `strike` is needed in this mode. The anchor must be a fixture unrelated to the claim
  (Felsworn: Blessed Resilience 33143 on the dummy).
- `attack_power_arms` `{aura, wait_ms, source}` adds a control arm (before learning) and a learned arm (after), each
  reading attack power, taking the fixture aura, waiting, reading attack power and the metric again. The attack power
  gain is read: not positive, or different between the arms by more than 0.5, voids the trial. `ok` when the low
  gain (after - before) exceeds the tolerance and the high gain (learned high - control high) exceeds the low gain
  plus the tolerance. One entry per metric (Armor and each resistance school).

## Consequences

- All three are opt-in or reach no finished-class entry: classes 15, 19, 19 `--stack`, 23 and 27 regenerate
  byte-identical (checked against the class head).
- Felsworn gains `inner_dot_held` / `inner_dot_gone` (501298) and `armor_ap_arms`, `resist_<school>_ap_arms` (92089).
- The attack power arms do not assert any amount: a coefficient defect that keeps the direction passes; that is the
  D-90 scope.
- Docs: `docs/metric_delta_options/apply_stamp.md`, `docs/metric_delta_options/attack_power_arms.md`,
  `docs/behaviour-scenarios.md`.
