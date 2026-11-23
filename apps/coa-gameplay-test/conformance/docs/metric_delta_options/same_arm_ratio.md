# Same-arm ratio (`metric_delta` `same_arm_ratio`, ADR 1237, provisional)

`same_arm_ratio` is `{"metric": M, "fields": {...}, "ratio": R, "tolerance": T, "least": N, "source": text}` with an
optional `"main_below": B`. Right after the entry's before and after readings the scenario reads `M` with `fields`
on the entry's `measure_actor`, labelled `<reading> same_arm_ratio part`. The judged value is the gain of the entry's
reading between the before and the after reading divided by the gain of `M` over the same window: `ok` within
`R +- T`, else `alert`. A gain of `M` below `N`, an after reading at or above `B`, or a missing read makes the verdict
`unmeasured`. `source` cites the tooltip or data line that states `R`, and the contract quotes it. The verdict
replaces the metric delta's; the evidence metric stays the entry's own.

Refused: `M` with `fields` equal to the entry's own metric and fields, and `expected_ratio` on the same entry. The
window holds only the after arm when the entry stops its events before each reading (an `attack_swings` entry stops
attacking before its readings).

Named points: `fixtures` (the reads and the contract sentence), `model`, `verdict`.

Sun Cleric: Vow of the Valkyr 807749 `per_swing` (Solar Power 500149 stacks per landed auto attack,
`melee_damage_count`, ratio 1 within 0.05, at least 5 attacks, stacks below the cap 20).
