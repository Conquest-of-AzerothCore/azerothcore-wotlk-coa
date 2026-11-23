# 1245. `aura_fed_effect` reads a proc rate per reset damage feed cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Builds on: [ADR 1235](1235-aura-fed-effect-reads-a-proc-rate-per-feed-heal-on-a-chosen-feed-target.md),
  [ADR 0195](0195-pool-hit-ratio-parts-and-judge-rates-in-points.md)

## Context

Sun Cleric, mentor ruling D-302. Dawn's Arrival 503690: "Casting Dawnbreak now has a $h% chance to reset the cooldown
of Gavels and causes the next one to not incur a cooldown." ProcChance 40 (server Spell.dbc). The roll is made on the
Dawnbreak 800654 cast (`AscensionSunClericAbilities.cpp:278-287`, `Chance(player, 503690)`), and a success casts the
marker 503691 on the caster, so the per-roll outcome is that aura, as in the `heal_rate` variant.

`heal_rate` cannot feed Dawnbreak: its roll refuses a feed with a cooldown and ignores the global cooldown only with a
haste aura, its part guards read heals, and its scenario has no creature. Dawnbreak is an instant SCHOOL_DAMAGE cone
with Category 111 / CategoryRecoveryTime 6000 and StartRecoveryTime 1500.

## Decision

Python only, opt-in. No harness, coverage or evidence table change.

1. `aura_fed_effect` variant `damage_rate` (or `damage_rate_<suffix>`) with `feed_target` `dummy`, sharing the
   `heal_rate` spec fields except `haste_aura` and `haste_agreement`, which it refuses. The feed must have a
   SCHOOL_DAMAGE effect and no travel speed. One stationary dummy stands at the feed's cast distance.
2. Each of `rolls` rolls cancels the granted `aura` on the caster, sets the feed power, resets the feed's cooldown
   (`reset_cooldown`) and casts it at the dummy with `ignore_gcd`; after the cast time plus 500 ms it reads `aura` on
   the caster (1 = the roll succeeded). A roll is 6 steps, about 1600 rolls per part under the 10000-step limit. The
   harness never sets the aura.
3. The part is void (unmeasured, excluded whole when pooled) if, at its end, `spell_go_count` of the feed is not the
   roll count (a refused or extra cast), `spell_damage_count` of the feed on the dummy is not the roll count (a cast
   that landed nothing), the last cast failure of the feed is not 0, or the dummy does not read alive with health
   above 0.
4. Judge, sizing and pooling are those of ADR 1235 (G-20 band of `procs.rate_band`, Wilson interval at
   `procs.residual_z`, `procs.residual_sizing`, the kind's `POOLED_JUDGE`). The model's `variant` is `damage_rate`;
   the kind routes both rate variants to the same judges.

## Consequences

- The `heal_rate` code paths, models and generated scenarios are unchanged; finished classes have no `damage_rate`
  entry, so their generated files and audits stay byte-identical.
- The Sun Cleric entry pools 20 parts of 1600 rolls with one spare (30400 rolls if one part drops, 29078 needed).
- No control arm: a server that never rolls reads 0% and alerts against the 38% to 42% band.

## Addendum: control arm with the talent unlearned (mentor D-309)

- Entry field `learn_talent` (boolean, default true; `false` takes a single part, damage variant only). With `false`
  the scenario emits an `unlearn` of the talent and learns only the feed, so the same roll runs without the talent.
- The model gets `control: true`, expected 0, `needed` = the rolls. The judge is `ok` only with 0 grants of the aura
  over every roll and the same void guards; any grant alerts, fewer rolls than needed is unmeasured. A 40% rate would
  leave 0 grants in 300 rolls with probability 0.6^300.
- Entries without the field generate byte-identical scenarios; the heal variant refuses the field. The control adds
  evidence and closes no claim.
