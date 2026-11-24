# After gate cast (`metric_delta` `after_gate_cast`, ADR 1251, provisional)

`after_gate_cast: true` casts the gate spell (`gate_spell`, else `spell`) at the caster at the start of the after
phase, after the gate learn and the `after_auras` and `phase_auras` steps and before the feed and trigger casts
(`reset_cooldown`, then `cast` with the caster as target). It replaces an `after_auras` fixture of the gate's own
aura when a real cast is available (guide 3.4): the learn of an active spell applies nothing by itself, so the
contract names the cast as the cause.

The entry must also carry `after_start_reads` with `{"spell": <gate>, "expected": 1}`, read right after the cast,
and `void_on_cast_failure: true`: a cast that did not land (the aura absent or unread) or a refused cast makes the
verdict `unmeasured`, never `ok` or `alert`. It needs the default `between` gate timing and no `attack_swings`
(`gate_cast` casts a gate between two attack phases), and the gate may not also be an after or phase aura. The cast
adds no reading and no counted label. Absent, the scenario is unchanged.

Named points: `check`, `phase_steps` (after phase only), `fixtures` (the contract).

Felsworn: Reckoning 802058 `stack_cap` (instant, StartRecoveryTime 0, so the Fel Fireball feed casts that follow meet
no global cooldown).
