# Caster avoidance (`metric_delta` `caster_avoidance`, ADR 0735)

`caster_avoidance` is `{"dodge": percent, "parry": percent}` (at least one, each 0 to 100, the other 0, and an
optional `block`), for an entry with a `strike`. Right before every striker cast the scenario sets the caster's dodge and parry chances (the harness
`set_combat_avoidance` step, `Player::m_realDodge` and `m_realParry`, the fields `Unit::MeleeSpellHitResult` reads),
so a melee-class strike is dodged or parried as set. Without `block` it adds no check. Absent, the scenario is
unchanged.

`block` (0 or 100, ADR 1216, provisional, mentor D-176) adds the block chance to each `set_combat_avoidance` step
(owner ruling O-20) for a strike at the caster. Right after the before and after readings the striker's
`spell_damage_count` of the strike on the caster is read with `blocked: true` and `blocked: false`: at block 100
every strike so far must be a blocked hit, at block 0 an unblocked hit, else the run is `unmeasured`. A match keeps
the reading's verdict. Without `block` the steps, contract and model are unchanged.

Sun Cleric: Sunflare Aegis 707629 `block_grant` (block 100) and its zero arms (block 0).

Witch Hunter: none yet. Dark Riposte 503659 does not proc on a parried spell (its `spell_proc` row asks a damage
spell type, and a parried spell deals none), so its claim needs a parried auto-attack, not a strike (ADR 0735).
