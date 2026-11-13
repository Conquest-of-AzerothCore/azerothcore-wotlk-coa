# Cooldown pick share (`behaviour_metric_delta`, `kind: "cooldown_pick_share"`, Necromancer ADR 0052)

A cooldown cut applied to one spell of a pool at random ("reduced by 15 sec at random"). Each cycle resets and casts
every spell of `pool` (mana set to `mana`, at most the fixture maximum), gives `commands` casts of `command_spell` at
the dummy `command_gap_ms` apart, and reads `cooldown_ms` of the pool before and `settle_ms` after the last;
`owned_creature_count` of `zombie_entry` is read too, and the cycle waits `expire_ms`. The median drop is the elapsed
time; a drop of `cut_ms` +- `tolerance_ms` more is the pick. `control_cycles` run before `spell` is learned and must
pick nothing (and summon nothing); each of the `cycles` after must pick exactly one. With `parts`, the cycles are
pooled: every spell must be picked and each count must lie in the two-sided 99.9% binomial band of a uniform pick. A
refused priming cast or a cooldown below the cut is unmeasured.

Necromancer: Underking 704701, pool 805032 / 805044 / 805048, 3 parts of 10 cycles (claim 172.1).
