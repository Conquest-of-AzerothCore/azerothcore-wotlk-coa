# Item cooldown gate (`behaviour_cast_condition`, `kind: "item_cooldown_gate"`, ADR 0492)

A grouped ally holds `item` (a named precondition fixture: the caster creates it and hands it out) and uses it through
the real item-use handler (harness `use_item`): first with no earlier use (accepted, the control), then
`cooldown_ms - margin_ms` after the first use (refused, 67 SPELL_FAILED_NOT_READY) and `cooldown_ms + margin_ms`
after it (accepted). Each attempt reads the ally's `cast_failure` of `item_spell` and its completed `spell_go_count`
(1, 1, 2), judged exactly. With `shared_item`/`shared_spell`, the ally uses that item right after the second accepted
use: refused for a shared cooldown. Create Bone Reliquary 803771 and Create Frozen Reliquary 803777: "Allies may only
use a ... once per minute."

An `item_cooldown_gate` entry's `label_suffix` (ADR 0534) keeps several entries of one item apart, and
`combat_kill_spell` reads the shared potion rule in combat: the ally attacks the dummy, uses `item`, is refused
`shared_item` past the cooldown while still in combat, the caster kills the dummy (set to 1 health) with that spell,
and `shared_item` is refused right after the combat end, still refused just before the cooldown from the combat end
and accepted just after it.
