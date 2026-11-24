# Taken total ratio (`behaviour_hit_ratio`, `kind: "taken_total_ratio"`, ADR 1266, provisional)

A damage-taken reduction that lives on an absorb aura ("While the barrier holds, you take $s2% reduced Physical
Damage"). The damage logs record a strike after the absorb, so `taken_hit` `damage_ratio` cannot separate the
reduction from the absorbed amount. This kind reads each strike from the spell logs the caster receives as its damage
plus resisted (`spell_damage_with_resist_total`) plus absorbed (`spell_absorb_total`) amount, non-critical logs only
(a trial with a critical log or without exactly one log is left out; each arm needs half its trials).

A passive stationary striker (creature 36) casts one strike per trial at the caster, held at `caster_max_health`,
`trials` per arm, in five arms: `control` (`strike_spell`, no aura), `treatment` (`spell` cast before the strike,
cancelled after), `magic_control` and `magic` (the same with `magic_spell`), and `broken` (`spell` cast, broken by
`magic_spell`, then `strike_spell`). Three expectations, labels `<spell> behaviour_hit_ratio <label_suffix>`,
`magic_taken` and `physical_after_break`:

- the control total must be a single value `C`, with nothing absorbed, or the label is unmeasured;
- `treatment`: each total lies in floor(f x C) .. ceil(f x (C + 1)) - 1 with f = (100 + Effect[`reduction_effect`])
  / 100 from the DBC, the aura read present before the strike and part of the strike absorbed;
- `magic`: each total equals the magic control, and the absorbed amount lies within the tooltip formula of
  Effect[`absorb_effect`] (base + 1 .. base + DieSides) plus `stamina_coefficient` x Stamina read at the arm start;
- `broken`: the aura is present before the breaker and absent after it, nothing is absorbed and each total equals
  the physical control.

Felsworn: Hateforged Barrier 707527 (Void Zone 92559 Physical, Light of the Naaru 41394 Holy).
