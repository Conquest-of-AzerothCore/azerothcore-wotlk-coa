# 1235. `aura_fed_effect` reads a proc rate per feed heal on a chosen feed target

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-23
- Builds on: [ADR 1195](1195-sequenced-casts-earn-a-proc-aura-and-space-hits-around-a-timer.md),
  [ADR 1202](1202-heal-variant-of-aura-fed-effect-and-pre-cast-of-attacker-miss-share.md),
  [ADR 0195](0195-pool-hit-ratio-parts-and-judge-rates-in-points.md)

## Context

Sun Cleric rc4, mentor rulings D-262, D-263, D-264, D-267 and D-275. Cultivate Divinity 704920: "Effectively
healing with Radiant Cascade has a $h% chance to increase the healing of your next Illumination by $301293s1%.
Effectively healing with Illumination has a $707520h% chance to increase the healing of your next Radiant Cascade by
$300354s1%." The two
tiers come from the server DBC set: ProcChance 20 on 704920 and 40 on 707520, chosen by
`AscensionSunClericEvents.cpp:345` by the healing spell. The question is whether a self heal (actor == target) rolls
the same chance as an ally heal, or rolls twice through the shared actor/target proc check (D-245, D-255).

The existing routes do not read it. `proc_rate` trial `effective_heal` (ADR 1192) heals the ally only. The
`aura_fed_effect` heal variant judges the +20% figure, not the chance, and feeds the ally only. `spell_proc_count`
of 704920 reads 0, and `aura_apply_count` of the granted aura saturates at 0 to 1 because the aura persists until
the next consuming heal.

## Decision

Python only, opt-in. No harness, coverage or evidence table change.

1. `aura_fed_effect` variant `heal_rate` (or `heal_rate_<suffix>`) with `feed_target` `ally` or `self`. The feed
   target is set once to 1 health of a 2000000000 maximum. Each of `rolls` rolls cancels the granted `aura` on the
   caster and casts `feed_spell` once at the feed target. After the cast time plus 500 ms, the roll reads `aura` on
   the caster (1 = the roll succeeded). The harness never sets the aura. A roll is 5 steps, so about 1900 rolls fit
   the harness limit of 10000 steps per scenario.
2. The run is void (unmeasured) if the feed's heal count on the target at the end is not the roll count (a refused
   or extra heal), if its effective healing is not its healing (an overheal), if the last cast failure of the feed
   is not 0, or, in the ally arm, if the feed heals the full-health caster effectively.
3. Judge: the G-20 band of `procs.rate_band`, max(5% relative, 2 points) around ProcChance of `chance_spell`. The
   Wilson interval at `procs.residual_z(residual_target)` must lie inside the band. An interval wholly outside alerts.
   One that straddles an edge is unmeasured, with the interval and the roll count the band needs stated
   (`procs.residual_sizing` with `min_detectable`). A doubled roll, 1 - (1 - p)^2, lies outside the band.
4. `haste_aura` (D-267, opt-in): a caster aura whose only effects are `SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK` below
   1000, with no proc flags, no spell family and no class mask. The generator refuses any other aura. The aura is
   set once before the rolls and read at the start and the end of the part (1, else void). The feed's cast time is
   read once after it, and every feed is cast with `ignore_gcd`.
   The roll step is the cast time divided by 1 + amount / 100, plus 500 ms. The end heal count check stays the
   guard that each cast landed.
5. The verdict stamps the metric `aura`, already EVENT in `METRIC_EVIDENCE`.
6. Pooled parts (D-275, opt-in by `parts` > 1, the kind's `POOLED_JUDGE`, the pooled-parts model of the other rate
   kinds): `parts` identical scenarios with `spare_parts` (at least 1) fixed in the entry before the run. The
   generator refuses an entry whose `(parts - spare_parts) * rolls` falls short of the band's roll count. A part with
   any void or missing read is excluded whole. The kept parts' rolls pool into one Wilson interval, judged as in 3,
   and fewer pooled rolls than the band needs is unmeasured. A pooled hasted entry names `haste_agreement` (the step 1
   agreement of hasted and unhasted rates) in its contract. The aura_fed_effect `POOLED_JUDGE` pools only
   `heal_rate`. Entries without `parts` never reach it, so the other variants and kinds are unchanged.

## Consequences

- At 300 rolls (G-20 step 1) the interval is stated, not final. The band at residual 0.001 per pair needs 29078
  rolls at 40% and 19386 at 20%. The sized Sun Cleric entries pool 17 parts of 1900 hasted rolls at 40% (30400 if
  one part drops out) and 12 at 20% (20900).
- Finished classes are untouched: the branch is taken only for the new variant, so their generated files and audits
  stay byte-identical.
