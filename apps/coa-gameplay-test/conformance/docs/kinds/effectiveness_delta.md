# Effectiveness of an effect (`behaviour_metric_delta`, `kind: "effectiveness_delta"`, ADR 0601)

A `metric_delta` entry (same fields) for a modifier that "increases the effectiveness" of another spell's effect.
`trigger_spell`, the effect, is cast for real in both phases; `gate_spell`, the modifier, is learned between them
(`gate_timing` `between`, `cast_in_before` true), and `expire_ms` lets the first effect end before the second cast.
The read (`metric`: `spell_power`, `stat`, `dodge_chance` or `parry_chance`, ADR 0671, `run_speed_rate`, ADR
1160, `resistance` with its `school` field, ADR 1275, or `attack_power`, ADR 1300) is judged by the `metric_delta`
judge. The verdict
names the state metric `effectiveness_<metric>`, declared in the module with the promise word `effectiveness`,
so a clause that names only the effectiveness counts the learned-contrast read as behaviour.

Necromancer: Improved Mandates 560613 on Grim Mandate 572789 (Shadow spell power 49 -> 58) and Foul Mandate 573298
(Stamina 122 -> 132), claim 117.0.

Witch Hunter: Dark Barrier 705520 on Stoicism 804802 (`dodge` and `parry`: +30% each, 37% with the talent, int32 of
30 x 1.25; judged as `expected_gain` 7 within 0.01, ADR 0671).

Witch Doctor (ADR 1160, provisional): Shadow Enchantments 301361 on Lethargy Jinx 802065 (`jinx_effect`: the slow on
the dummy, `measure_actor` `dummy`, run speed rate 0.57143 -> 0.285715, -50% raised by half to -75%), claim 23.1.

Felsworn (ADR 1275, provisional): Pact Hunter 704612 on Vengeful Pact 803885 (`pact_effectiveness`: the Shadow
resistance of a party ally, `measure_actor` `ally`, `ally_arm`, 65 -> 97, floor(65 x 1.5), the truncation of 97.5 being
the known engine rounding, tolerance 0.5).

Cultist (ADR 1300, provisional): Improved Sermon of Dread 706177 on Sermon of Dread 620614 (`sermon_attack_power`:
the debuffed dummy's `attack_power`, `measure_actor` `dummy`, buffed with Attack Power 980 35785 to avoid zero clamp,
-144 -> -201 = int32(-144 x 1.40), `expected_gain` -57 within 0.5).
