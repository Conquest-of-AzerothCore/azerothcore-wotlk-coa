# Bounce amounts (`bounce_amounts`, ADR 0587)

A bouncing spell's amount per enemy struck. The entry names `cast_spell` (cast at the primary dummy), `hit_spell` (the
bouncing hit), `distances` (the primary and the further dummies, nearest first, in yd from the caster), `cast_wait_ms`,
an optional `cast_power` and `caster_auras` (precondition fixtures such as the crit and resist removers). One more
dummy stands 16 yd beyond the last.

The scenario casts `cast_spell` before the entry's spell is learned (control), learns it, and casts again (treatment).
After each arm it reads every dummy's `hit_spell` damage total and hit count; the treatment hits are the difference.
The judge needs the control to strike the primary only, every further dummy struck with the talent and the far one
never; the per-hit means, largest first, divided by the primary's, must lie within 5% (G-19) of
`EffectDamageMultiplier[0]` of `hit_spell` raised to the jump number (0.7 and 0.49 for Crypt Swarm 800343).

Necromancer: Crypt Keeper 560596 "at ${-($800343f1-1)*100}% reduced value per enemy struck" (claim 116.0).
