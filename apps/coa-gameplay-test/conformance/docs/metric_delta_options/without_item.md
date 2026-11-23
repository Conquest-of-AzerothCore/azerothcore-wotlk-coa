# Without item (`metric_delta` `without_item`, ADR 1225)

`without_item` is `{"item": item id, "source": text}` for an entry whose metric is `cast_failure` of its own
`trigger_spell`, with `cast_in_before` true and the spell learned in both phases. The scenario must equip the item
before the first cast and cast the trigger twice. Right before the second cast the option adds the harness steps
`reset_cooldown` (of the trigger spell) and `destroy_item` (of the equipped item). The first cast is the control; the
entry states the expected failure code and `source` cites the DBC equipment requirement and the code line that returns
that code. Absent, the scenario is unchanged.

Sun Cleric: Shield Radiance 504580 `no_shield` (shield 2129; EquippedItemClass 4, SubClassMask 64;
SPELL_FAILED_EQUIPPED_ITEM_CLASS 29, Spell.cpp:7539-7541).
