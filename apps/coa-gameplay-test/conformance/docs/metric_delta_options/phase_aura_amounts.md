# Phase aura amounts (`metric_delta` `phase_aura_amounts`, ADR 0585)

`phase_aura_amounts` lists `[spell, effect, amount]` triples. Each names an aura of the entry's `phase_auras` or
`after_auras`; right after that aura's `set_aura` step, in every phase where the aura is set, the option adds a second
`set_aura` step on the same unit and caster with `effect` (0-2) and `amount`, which the harness applies through
`AuraEffect::ChangeAmount`. An amount for a spell that is neither a phase nor an after aura, or an effect outside 0-2,
is refused.

The module adds its steps at the named point `phase_steps(spec, value, after)`, called by `cast_steps` after the
phase and after aura steps (`metric_delta_options.option_phase_steps`).

Use: a capacity fixture for the Necromancer Life Force rig. Summoning Adept 92123 Effect[2] is a
SPELLMOD_MAX_AURA_STACKS modifier on Life Force 805011 (+1); with amount 4 the capacity is 2 + 4 = 6, read by the
301207 `capacity_fixture` entry, so two Abominations (3 each) stay at once (claims 26.1 and 94.1).
