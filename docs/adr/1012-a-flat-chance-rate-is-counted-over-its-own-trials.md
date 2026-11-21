# 1012. A flat chance rate is counted over its own trials

- Status: proposed (draft, Witch Doctor cycle 10 task P; provisional number, renumbered at merge, guide 14.4)
- Date: 2026-11-21
- Builds on: ADR 0581 (kind modules), ADR 0582 (metric_delta options)

## Context

A `procs` entry with a `cast` trigger counts a trial as a landed hit of the trigger rank (`procs.trials_step`).
Four Witch Doctor shapes do not fit and were tool gaps:

- a roll on periodic ticks only, where the trigger rank also has a direct hit that never rolls (Hex of Malice 801693:
  Darkspear Traditionalist 503707, Hexfire Mass 807450 with a 3000 ms internal cooldown, Berserking 705925 with a
  ward that must be alive);
- a roll on an effective heal, which needs a hurt caster or ally (the healing halves of Mojo Madness 705871 and Loa
  Spirits 804620 and 807904);
- a roll on the hits a trigger's aura script casts, where the trigger itself deals no damage (Shadow Puppets 500015
  and its Shadow Puppet 802745 hits: Overflowing Juju 705844);
- a roll by an owned creature on each of its own attacks (Voodoo Fire 802262 and 803846, Spirit Striker 806286, Viper
  Ward 707329; tool note T-c9-B16-4).

## Decision

`kinds/flat_chance_rate.py` (`behaviour_metric_delta`, `kind: "flat_chance_rate"`): a real trigger cast in repeated
cycles (`layout` of trigger, setup, start, end and wait steps), an unlearned control arm and a treatment arm after a
real learn, a configurable trial read (periodic `spell_damage_count`, `spell_heal_count`, `spell_cast_count`,
`owned_creature_spell_cast_count`) and event read (`spell_cast_count`, `owned_creature_summon_count`,
`owned_creature_spell_cast_count`), per-cycle reads for counters that belong to one creature, the flip-proof sizing and
the between-part judge of `stack_chance_rate`, and the G-19 band. Fixtures (`attempt_auras`, `caster_health_pct`, the
trigger aura removed from the dummy) are precondition fixtures named in the verdict. Evidence metric
`flat_chance_rate`, an event count.

## Consequences

Fourteen claim parts of the Witch Doctor get a rate proof without an owner change (the fix round added Overflowing
Juju 705844, whose `procs` judge counted the damage of the non-damaging trigger 500015). The scenarios are long:
about 144 h of game time per run over 173 parts (about 3 h of wall time at the median 48x of final07, spread over
the lanes); each entry stays inside the 90 minutes per counted pair of G-20 step 3. No owner file changes;
the `docs/behaviour-scenarios.md` list of kind modules gains one line at merge:
"[`flat_chance_rate`](kinds/flat_chance_rate.md): a flat chance per periodic tick, effective heal or owned creature
attack, pooled over parts (ADR 1012, provisional)".
