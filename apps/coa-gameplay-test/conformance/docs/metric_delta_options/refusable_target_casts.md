# Refusable target casts (`metric_delta` `refusable_target_casts`, ADR 1027)

`refusable_target_casts` is `{"spells": [ids], "refusal": SpellCastResult, "delay_ms": n}`, for an entry whose trigger
is cast at the dummy in both phases (`cast_in_before`, `gate_timing` `between`) and that sets no `target_casts`.
`delay_ms` after each trigger cast the dummy casts each spell at itself, triggered, with `allowed_refusal`: a refusal
with exactly that code passes the step, any other refusal still fails the scenario (the plain creature cast refuses
every refusal). The entry's `wait_ms` follows the casts. Right after each judged reading the scenario reads
`creature_cast_result` of each spell (SPELL_CAST_OK 255 when it started, the refusal code otherwise). A missing result, or a refused control cast,
makes the verdict `unmeasured`; the treatment results are stated in the explanation. Absent, the scenario is unchanged.

Named points: `after_trigger_steps` (the casts), `fixtures` (the result reads), `model` and `verdict`.

Witch Doctor: Eye of Kimbul 503714 `no_stealth` and `no_invisibility` (a marked dummy's Stealth Dummy 2144558 and
Super Invis 8149 refused with SPELL_FAILED_CASTER_AURASTATE 22; the control phase takes the aura), held in cycle 8 for
want of a refusable creature cast (tool note T2).
