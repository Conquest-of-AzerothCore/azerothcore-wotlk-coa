# Caster avoidance (`metric_delta` `caster_avoidance`, ADR 0735)

`caster_avoidance` is `{"dodge": percent, "parry": percent}` (at least one, each 0 to 100, the other 0), for an entry
with a `strike`. Right before every striker cast the scenario sets the caster's dodge and parry chances (the harness
`set_combat_avoidance` step, `Player::m_realDodge` and `m_realParry`, the fields `Unit::MeleeSpellHitResult` reads),
so a melee-class strike is dodged or parried as set. It adds no check. Absent, the scenario is unchanged.

Witch Hunter: none yet. Dark Riposte 503659 does not proc on a parried spell (its `spell_proc` row asks a damage
spell type, and a parried spell deals none), so its claim needs a parried auto-attack, not a strike (ADR 0735).
