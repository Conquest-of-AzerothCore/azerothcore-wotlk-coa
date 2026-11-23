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

`player_ratings` (a map of the player fixture's rating fields, such as `ranged_crit_rating`, to non-negative integers)
sets those ratings on the caster for both arms of every part, for a chance that a rating raises. With it,
`rating_bonus` (`{"rating": CombatRating, "expected_pct": n, "tolerance": n}`) reads `combat_rating_bonus` of that
rating once per part, after the learns; a part whose bonus is missing or off the stated percentage points by more
than the tolerance makes the verdict `unmeasured` (the fixture is not the stated arm). The entry's `chance_pct` is
then the stated base chance plus that bonus (ADR 1048, provisional).

The judge pools the parts: a Wilson interval below 10 parts, the between-part t interval from 10 parts, inside the
G-19 band of the chance (`compare.banded_rate`). Sizing is the flip-proof rule of `stack_chance_rate` (mentor M-14):
`cycles x trials_per_cycle x parts` must reach `arm_trials_needed(chance, 1, parts)`, unless `pilot`; the judge
refuses fewer measured trials. The verdict states the fixtures. Its evidence metric is `flat_chance_rate`, an event
count.

## Streams

`streams` (default 1) runs that many independent copies of the design in one scenario, so a part gathers that many
times the trials in the same game time. Stream 0 is `caster` and `dummy`, stream k is `casterk` and `dummyk`. Every
cast, fixture and read of a stream names its own caster and dummy by id; waits are shared, so every stream keeps the
single-stream timing. Each stream has its own unlearned control arm and learns the talents between the arms. The
reads are per stream and summed per part; the sizing rule, the band and the judge are unchanged, only the trials
per part are multiplied by `streams`, so `cycles` (or the arm `trials`) shrink by that factor for the same totals.

The scenario stands at the flat, open, dry ground of `STREAM_LOCATION` (map 1, the Shimmering Flats, z -58.75
over the whole 116 x 43 yd box, no model or liquid; checked with the server map and vmap data), facing +y.
The dummies are 100 / (`streams` - 1) yd apart along x (the creature `distance` limit is 100 yd); each caster is
moved by `relocate` steps to `dummy_distance` yd (default 3) in front of its own dummy. Nobody is grouped.

A multi-stream entry must declare `isolation`: `reach_yd` (the largest radius, chain or splash reach of any spell
involved, from a stream's caster or dummy), `source` (why, from the DBC and the code) and `wards`, one item per
owned creature that attacks on its own: `entries`, `within_yd` (its largest distance from its owner), `reach_yd`
(its attack reach), `combat_reach_yd` (a bound on its own combat reach) and `spells` (its damage spells, read per
ward guid). Generation refuses an entry whose spacing is not beyond `reach_yd` plus two 2 yd combat reaches, or
whose ward, at `within_yd` from its owner, could come within its reach plus both combat reaches of another dummy.

Asserted in the scenario (harness assertions, min and max, so a breach fails the run), and judged again by the
verdict (`isolation` in the model: a damage or heal read across streams outside its bounds alerts, a placement
read outside its bounds or any missing read is `unmeasured`):
- the ground height and z of every caster and dummy (z -58.75 plus or minus 0.5), their combat reaches (at most
  2 yd) and the distance from every caster to every dummy (plus or minus 0.5 yd);
- every ward entry: no owned ward farther than `within_yd` from its owner, at every cycle end read while the ward
  lives (or after every cycle for a layout without per-cycle reads);
- ward `spells`: the current ward's damage on every other dummy is 0, read at every cycle end read, or before
  every setup recast and at the end when the layout has no per-cycle reads;
- at the end, per dummy, no damage from any other stream's caster with the trigger, the spells it triggers in the
  DBC and the trial spell, read by the dummy's owner with `caster`; for a heal trial, no heal on any other stream's
  caster.

The harness has no read of every ward guid of an entry across its lifetimes: a ward's hits are read while it lives
(the last seconds of a Serpent Ward's life after the end read, and Mass Serpent Wards, of which several can live at
once, rest on the asserted placement).

Witch Doctor: Darkspear Traditionalist 503707, Hexfire Mass 807450 and Berserking 705925 (one Hex of Malice tick per
cycle, the Hex removed after 3500 ms), Mojo Madness 705871 and Loa Spirits 804620 and 807904 (a Loa's Brew self heal
at 30% health), Voodoo Fire 802262 and 803846 and Spirit Striker 806286 (one Serpent Ward per cycle, its attacks the
trials), Viper Ward 707329 (one Viper Ward per cycle, a plain Serpent Ward in the control; `viper_rating_rate` at 280
ranged critical strike rating, one stream), Overflowing Juju 705844 (the five Shadow Puppet 802745 hits of one Shadow
Puppets cast per cycle). Streams: 8 for 503707, 705844 and the three heal entries; 4 for 705925 and the three Voodoo
Fire entries (a Serpent Ward 3 yd in front of a caster 25 yd from its dummy); 3 for 807450 and 707329 (a ward at the
dummy itself).
