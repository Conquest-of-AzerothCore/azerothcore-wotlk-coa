# 0141. Percent-path stats are judged to the engine's truncation, with a known engine rounding

- Status: accepted
- Date: 2026-11-11
- Amends: ADR 0135 (deterministic stat readings) for `stat`, `armor`, `max_health`, `max_power` and `resistance`

## Context

Sturdy 681009, "Increases your maximum health and Energy by 5%", reads maximum Energy 100 before the learn and 104
after it. The tooltip states 105. The cause was found by code reading (`lean/sturdy-fix-reading.md`):
`AuraEffect::HandleAuraModIncreaseEnergyPercent` passes 5.0f to `Unit::ApplyStatPctModifier`, `AddPct`
(`Util.h:52-60`) builds the factor 1.0499999523162842 in float, `Player::UpdateMaxPower` multiplies 100 by it in
float (104.99999237060547) and `SetMaxPower(power, uint32(value))` truncates to 104. The stock engine has about twenty
casts of this shape in `StatSystem.cpp`, for every class.

The owner ruled ("Sturdy, no server change", `owner-rulings-2026-11-10.md`, 2026-11-11): no server change; a
percent-derived stat that reads exactly 1 below the tooltip value is "conformant, known engine rounding" when
emulating the engine's float computation reproduces the reading, and the verdict carries the computed float value.
One above, two or more away, or a one below the emulation does not reproduce stays a deviation. The rule covers max
health, max power, the five stats, armor and resistances only, never damage, healing or durations. It amends "stat
passives judged exactly to the rounding".

ADR 0135 judged these stats within a symmetric 1-point floor. That accepted one above (Blessed Padding +803 for
+802, `test_compare.py`) and gave the Sturdy reading `ok` with no emulation (review `lean/batch1-c2-review.md`, I6).

## Considered options

1. Keep the symmetric floor and add the emulated value as a note. Rejected: one above stays `ok`, against the ruling.
2. Accept any one below on these stats. Rejected: a 4% server on a 5% tooltip at 80 Energy reads 83, one below the
   84 the float gives, and would pass.
3. Judge these stats to the engine's truncation of the expected value, and accept one below only where the float
   emulation reproduces it. Chosen.

## Decision

- `compare.PERCENT_PATH_METRICS` = `stat`, `armor`, `max_health`, `max_power`, `resistance`.
- For them `delta_status` is `ok` only when the delta equals the expected delta truncated (`compare.truncated`); the
  interval is that integer (`interval_verdict`). A fractional expected delta keeps its truncation (+108 for +108.65).
- `compare.engine_rounding_verdict`, on a single `scale` reading of such a metric, a nonzero delta exactly one below
  the truncated expected delta: it emulates the engine in float32 (factor `1 + 1 x p / 100` with each operation
  rounded to float, the float product with the before value, the truncation). If the emulation gives the reading,
  the verdict is `ok`, its explanation says "known engine rounding" and `detail['engine_rounding']` holds the
  computed float value; otherwise the ordinary judge gives the alert.
- `data_only` for such a verdict comes from the emulation, not from `floor_only_reason`: it is set when a percent one
  point away emulates to the same reading, because the reading then cannot tell the stated percent.
- Not covered: combined effects of one passive (`judge_combined`), `share` and `add` relations (judged to the
  truncation, with no one-below acceptance), `behaviour_group_stack_cap`, `stat_exact`, and every other metric,
  which keeps ADR 0135.

## Consequences

- Sturdy's Energy verdict is `ok` with evidence 104.99999237060547 and stays data conformant: +4% also reads 104
  from 100 (`100 x 1.04f` is 104.0 in float).
- One above is an alert on these stats; the Blessed Padding test now asserts it.
- Seeded tests in `test_compare.PassiveDeltaTest`: the true positive (100 to 104 for +5%), the 4% mutant at 80, one
  above and two below, and a damage and an attack power reading that never take the rule.
- The emulation assumes a factor of 1 before the learn. On a character with another percent aura on the same
  quantity it does not follow the engine, and a one-below reading there is judged against the wrong float value.
- The emulation multiplies the whole before reading. Where the engine adds flat terms after the percent factor
  (BASE_PCT stat and armor slots, `Player::UpdateArmor`; `lean/sturdy-fix-reading.md` §5) it is not the engine's
  computation either, so a one-below reading there may be judged against the wrong value.
- The verdicts re-judged on the stored batch 1 and round 10 results are listed in `lean/rounding-tool.md`.
