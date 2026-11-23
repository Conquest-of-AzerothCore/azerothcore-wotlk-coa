# Effectiveness of an effect (`behaviour_metric_delta`, `kind: "effectiveness_delta"`, ADR 0601)

A `metric_delta` entry (same fields) for a modifier that "increases the effectiveness" of another spell's effect.
`trigger_spell`, the effect, is cast for real in both phases; `gate_spell`, the modifier, is learned between them
(`gate_timing` `between`, `cast_in_before` true), and `expire_ms` lets the first effect end before the second cast.
The read (`metric`: `spell_power`, `stat`, `dodge_chance` or `parry_chance`, ADR 0671) is judged by the
`metric_delta` judge. The verdict names the state metric
`effectiveness_<metric>`, declared in the module with the promise word `effectiveness`, so a clause that names only
the effectiveness counts the learned-contrast read as behaviour.

Necromancer: Improved Mandates 560613 on Grim Mandate 572789 (Shadow spell power 49 -> 58) and Foul Mandate 573298
(Stamina 122 -> 132), claim 117.0.

Witch Hunter: Dark Barrier 705520 on Stoicism 804802 (`dodge` and `parry`: +30% each, 37% with the talent, int32 of
30 x 1.25; judged as `expected_gain` 7 within 0.01, ADR 0671).
