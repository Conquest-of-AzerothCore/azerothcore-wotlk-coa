# Script count (`metric_delta` `script_count`, ADR 1258, provisional)

`script_count: {"noun": "attack" | "charge" | "stack"}` is for an `aura_script_value` entry whose script value is the
count the tooltip sentence states (an aura that keeps its remaining attacks in a script value while `Aura::GetCharges`
stays 0). The read stays `aura_script_value`; the verdict stamps `aura_script_count`, a STATE metric of the option
module with the promise words `attacks?|charges?|stacks?`. The module also classes `aura_script_value` itself as
READBACK with no `CONTRAST_PROOF` row, so a read without the option is data, never behaviour (mentor D-70), and an entry
that names `evidence_metric: "aura_script_count"` without the option is refused.

The generator refuses the opted entry unless:

- the quote (a tooltip substring, as for every behaviour entry) holds a `$` token followed by the noun, with at most
  one word between (`$n attacks`, `$s1 additional attack`), and the read aura is the entry spell or its DBC name is in
  the quote;
- the entry reads `aura_script_value` of a named aura, judged exactly (no `evidence_metric`, ratio, floor or ceiling);
- the layout is the plain with/without one (no `setup_only_after`, start gate, swings, gate cast, forced chance or
  trigger item), with a real `cast` of `trigger_spell` between the two readings and no `set_aura` step nor any step
  other than `cast`, `learn`, `assert` or `reset_cooldown` on the read aura;
- the before arm differs by its driving event: absent (`cast_in_before: false`, and no cast of the trigger before the
  before reading) or different (the trigger cast in both phases, the gate spell learned between differs from it);
- `before_expected` differs from `expected` by more than twice the tolerance.

Felsworn: Annihilation 803904 (0 without the cast, 5 after it, "Lasts for $n attacks"), Pit Lord's Strength 802076 and
802110 (5 without the talent, 6 and 7 with it, "affects $s1 additional attack").

`swings` (ADR 1270, optional, noun `attack` only) is a positive count of reference swing intervals. After each real
cast of `trigger_spell` the scenario reads the count (`<reading> cast count`) and the caster's `melee_damage_count`
(`<reading> cast landed`), auto-attacks the dummy for `swings` intervals, stops, and after the reading reads
`melee_damage_count` again (`<reading> landed`). Each reading of a cast arm becomes the count plus the attacks landed
since the cast, and is missing (the plain judge alerts) unless at least one attack landed, the count is strictly
below the cast count, and the count plus the landed attacks equals the cast count (one count per landed attack,
mentor D-95). An uncast before arm (driver `absent`) keeps its plain count and has no swings. Refused: a window whose
landed-attack bound is not below the least expected count of a cast arm (the aura could end inside the window); the
bound sums `window // speed + 1` over every melee hand the scenario equips, since `melee_damage_count` counts both
hands. Untested by the rule: missed or avoided swings (only landed attacks count) and the aura's end at the last
count.

`main_hand` (ADR 1277, optional, with `swings` only) is `{"item", "speed_ms", "skill_line", "proficiency"}`, all
positive integers read from `item_template` (`delay`, the subclass's skill line) and Spell.dbc. It replaces the
scenario's melee equip steps (slots 15 and 16 with their `add_item`) by one main-hand weapon: the caster learns
`proficiency` (refused unless Spell.dbc gives it Effect[0] 25 on item class 2), equips `item` in slot 15 and sets
`skill_line` to the class's skill target. The bound then uses `speed_ms`; the judge is unchanged. Use it when the
window must land more attacks than one interval of the class weapons allows below the count (with a fast weapon,
`swings` intervals of the class's reference weapon hold several landed attacks). Felsworn: Annihilation 803904,
Pit Lord's Strength 802076 and 802110 (`consumed`, 2 swings = 4600 ms, Poniard 2208 at 1300 ms, Daggers 1180: bound
4, below the least count 5; the class file's hit and expertise ratings remove misses, dodges and parries).
