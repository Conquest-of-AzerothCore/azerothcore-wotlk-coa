# Action buttons (`metric_delta` `action_buttons`, ADR 1113, provisional)

`action_buttons` is a non-empty list of `[button, spell]` (button 0 to 143, distinct), each spell also in the entry's
`learn`. In the treatment phase only, before the trigger cast (named point `phase_steps`), each spell's cooldown is
reset and the harness `set_action_button` step puts it on its button (`Player::addActionButton`); the control phase
leaves the buttons empty. Absent, the scenario is unchanged.

Use it for a spell that acts on the caster's action bar, such as `SPELL_EFFECT_CAST_BUTTON`.

Witch Doctor: Rite of the Loa 575025 `rite_ward`, `rite_effigy`, `rite_idol` (buttons 132 to 134 hold Serpent Ward
500960, Shadow Effigy 505339 and Spirit Idol 500961; one Rite places one of each, none with the buttons empty).
