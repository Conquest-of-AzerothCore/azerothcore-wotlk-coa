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
