# Flat chance rate (`behaviour_metric_delta`, `kind: "flat_chance_rate"`, ADR 1012, provisional)

ADR 1012 has a provisional number and is renumbered at merge (guide 14.4).

A flat chance per trial ("Periodic damage dealt by Hex of Malice now has a 20% chance to collect a Spirit") whose
trial is not a landed hit of a cast trigger, so a `procs` entry cannot count it: a periodic tick only, an effective
self heal, or an owned creature's own attack. The scenario repeats a cycle around a real `trigger_spell` cast and
counts `trial` and `event` reads, before `talents` (default `spell`) are learned and after:

- `unlearned`: `unlearned_cycles` cycles, the control: any event alerts, and fewer than 50 pooled trials is
  `insufficient_trials`;
- `treatment`: `cycles` cycles, judged on the events over the trials (`events_per_proc` events per proc).

A cycle follows `layout`, a list of `{"do": ...}` steps: `trigger` (the `caster_health_pct` and `attempt_auras`
fixtures, the power and cooldown fixtures, the cast at `trigger_target`, a wait of `wait_ms`, then with
`stop_trigger_aura` the trigger aura removed from the dummy), `setup` (a real `setup` cast every `setup.every`
cycles, then `wait_ms`), `start` and `end` (the reads of one cycle, for a counter that belongs to one creature), and
`wait`. Without `layout` a cycle is `setup` (with `setup_wait_ms`, when there is a setup) then `trigger` (with
`cast_wait_ms`). Without `start`/`end` the reads bracket each arm. `unlearned` may name another `setup` and creature
`entry` for the control, when the treatment's creature exists only with the talent (Viper Ward 707329).

Reads: `trial` is `spell_damage_count` (with `periodic` and `target`), `spell_heal_count` (with `target`),
`spell_cast_count` or `owned_creature_spell_cast_count` (with `entry`); `event` is `spell_cast_count`,
`owned_creature_summon_count` (with `entry`) or `owned_creature_spell_cast_count` (with `entry`). Every cast must be
spaced by its cast time and global cooldown (`stack_chance_rate.minimum_wait_ms`), a costed cast names its power,
and the talents are never learned up front.

The judge pools the parts: a Wilson interval below 10 parts, the between-part t interval from 10 parts, inside the
G-19 band of the chance (`compare.banded_rate`). Sizing is the flip-proof rule of `stack_chance_rate` (mentor M-14):
`cycles x trials_per_cycle x parts` must reach `arm_trials_needed(chance, 1, parts)`, unless `pilot`; the judge
refuses fewer measured trials. The verdict states the fixtures. Its evidence metric is `flat_chance_rate`, an event
count.

Witch Doctor: Darkspear Traditionalist 503707, Hexfire Mass 807450 and Berserking 705925 (one Hex of Malice tick per
cycle, the Hex removed after 3500 ms), Mojo Madness 705871 and Loa Spirits 804620 and 807904 (a Loa's Brew self heal
at 30% health), Voodoo Fire 802262 and 803846 and Spirit Striker 806286 (one Serpent Ward per cycle, its attacks the
trials), Viper Ward 707329 (one Viper Ward per cycle, a plain Serpent Ward in the control), Overflowing
Juju 705844 (the five Shadow Puppet 802745 hits of one Shadow Puppets cast per cycle).
