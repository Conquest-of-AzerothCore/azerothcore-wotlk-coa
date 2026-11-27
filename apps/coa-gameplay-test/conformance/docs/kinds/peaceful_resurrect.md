# Peaceful resurrect (`behaviour_cast_combat`, `kind: "peaceful_resurrect"`, ADR 1022, provisional)

A resurrection that carries `SPELL_ATTR0_NOT_IN_COMBAT_ONLY_PEACEFUL`, read out of combat and in combat in one
scenario. `cast_combat` (ADR 0537) attacks the dummy before its cast and expects the cast to go through, so it cannot
read such a spell. The dead ally first answers with no offer (`CMSG_RESURRECT_RESPONSE` 348) and stays dead. Out of
combat (`combat` 0) the spell is cast at the dead ally and waits its cast time plus 500 ms (`cast_failure` 0); the ally
accepts and is read alive, with the effect's BasePoints + DieSides as health and MiscValue as mana (regeneration
off). The ally dies again, the caster attacks the dummy (`combat` 1), and the same cast is refused with
`SPELL_FAILED_AFFECTING_COMBAT` (1); the ally's answer finds no offer (alive 0). The out-of-combat arm runs first,
because the harness keeps a spell's last refusal reason.

`claims` lists `{claim, quote}` with `claim` one of `health`, `mana` and `refusal`; each is one label
`<spell> behaviour_cast_combat <label_suffix> <claim>` judged exactly on its readings: `health` and `mana` on the
control, the accepted cast and the amount; `refusal` on both arms (combat 0 and 1, cast 0 and 1, alive 1 and 0). A
spell without the attribute or without a resurrect effect is refused at generation.

Witch Doctor: Reclaim Soul 803624 (clauses 459, 460, 461).

`SPELL_EFFECT_RESURRECT` (effect 18, ADR 1323): alongside `SPELL_EFFECT_RESURRECT_NEW` (113, flat amounts), `peaceful_resurrect`
accepts effect 18 (`RESURRECT_EFFECTS = frozenset({18, 113})` in `behaviours.py`). For effect 18 the scenario also reads
`max_health` and `max_power` (power 0, mana) on `ALLY` after resurrection and compares `health_peaceful` /
`mana_peaceful` against `CalculatePct(max, BasePoints + DieSides)` without silently clamping percentages above 100%, so
oversized DBC percentage values (such as Vampyr Bite 803585's 820%) alert honestly instead of false-passing at full
health/mana. A zero maximum pool (for example mana on a non-mana ally) returns `unmeasured`; optional `ally_class`
(12..32) selects a CoA class for `ALLY`. Effect 113 scenarios remain byte-identical.
