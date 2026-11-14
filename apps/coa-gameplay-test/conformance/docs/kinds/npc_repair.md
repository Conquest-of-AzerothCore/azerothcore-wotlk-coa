# Repair at an owned creature (`behaviour_cast_condition`, `kind: "npc_repair"`, ADR 0384)

The caster, a grouped ally and an enemy-faction player each wear `item` (`full` durability), worn by `loss_percent`
before each request (harness `durability_loss`, a precondition fixture), and send a repair-all request to the caster's
creature `entry` (harness `repair_at`, the real `CMSG_REPAIR_ITEM` handler): before `spell` is cast (no creature), then
after it for the caster, the ally and the enemy. Each worn and repaired reading of `equipped_durability` (the item's
entry) is judged exactly: refused requests keep the worn value, granted ones restore `full`. Animate: Skeletal Smith
804681 repairs the caster and the ally, not the enemy.
