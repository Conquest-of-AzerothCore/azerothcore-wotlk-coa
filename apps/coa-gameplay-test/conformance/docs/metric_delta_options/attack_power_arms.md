# Attack power arms (`metric_delta` `attack_power_arms`, ADR 1284, provisional)

`attack_power_arms` is `{"aura": A, "wait_ms": W, "source": text}` on a plain learned-contrast entry (gate learned
between the phases, no `setup_only_after`, swings, expiry read, phase power, gain, ratio or after bounds). It judges
"grows with attack power" without asserting a coefficient or the before value.

Right after the before reading (spell not learned) the caster reads its attack power (`control low`), takes the
fixture aura `A` (harness `set_aura`), waits `W` ms, reads its attack power (`control high`) and the entry's metric
(`<spell> <metric> control high`), then loses `A` (`set_aura` stacks 0). Right after the after reading (spell learned)
it repeats the step (`learned low`, `A`, `W`, `learned high`, `<spell> <metric> learned high`). Attack power labels are
`<spell> attack_power_arms attack_power <arm>`.

The fixture's attack power gain is read, not assumed. The trial is void (`unmeasured`) when the control gain is not
above 0.5, or when either learned attack power differs from its control by more than 0.5 (the two arms would not
compare the same two attack powers), or when a reading is missing.

Judged on the direction only; the plain before/after bands are not applied:

- low gain = after - before, above the entry's `tolerance`;
- high gain = learned high - control high, above the low gain plus `tolerance`.

`ok` when both hold, else `alert` (a flat bonus, no bonus or a falling bonus). The verdict detail carries
`arm_gains` and the four attack powers. One entry judges one metric: Armor and each resistance school are separate
entries.

Named points: `check`, `fixtures` (the arms and the contract), `model`, `verdict` (ORDER 43, after
`void_on_cast_failure`; an `unmeasured` verdict is kept).

Felsworn: Burning Commander 92089 `armor_ap_arms` and `resist_<school>_ap_arms` (schools 1 to 6), Attack Power 980
35785, `W` = 3600 ms (one 3000 ms tick of the passive).
