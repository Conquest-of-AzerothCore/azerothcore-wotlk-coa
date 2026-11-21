# After-trigger casts (`metric_delta` `after_trigger_casts`, ADR 1028)

`after_trigger_casts` is a non-empty list of `{"spell": id, "delay_ms": n}`, each with an optional `target` and an
optional `destination_unit` (`caster` or `dummy`; `target` defaults to the caster). In the treatment phase only, right
after the trigger cast, the caster waits `delay_ms`, its cooldown of `spell` is reset, the spell's `CasterAuraSpell` is
set (a precondition fixture, as for setup casts) and it casts `spell` for real at `target`; with `destination_unit`
the cast sends that unit's current position as its ground target (the harness `destination_unit` of ADR 1028), for a
spell with a destination target. The entry's `wait_ms` follows the last cast. The control phase makes no such cast.
Absent, the scenario is unchanged.

Use it for a claim about a cast made while the trigger's effect runs (a channel, a window), read after the cast.

Named points: `after_trigger_steps` (the casts) and `fixtures` (the caster aura fixtures).

Witch Doctor: Mojo Beam 501117 `potion_in_channel`, `potion_keeps_beam`, `splash_in_channel` and `splash_keeps_beam`
(Potion Toss and Splash Potion cast 1700 ms into the channel: each completes and the Beam still channels).
