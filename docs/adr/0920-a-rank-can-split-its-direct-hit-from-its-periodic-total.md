# 0920. A rank can split its direct hit from its periodic total

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16
- Builds on: ADR 0890, ADR 0686

## Context

Tormentor 501349 (Witch Hunter claim 309.0) states `${$cond($gt($sps, $sph), $m3+0+$sps*.175, $m3+0+$sph*.175)}`
Twilight damage (Effect[2] 2 SCHOOL_DAMAGE) plus `${($d*1000/$T1)*($m1+0+$RAP*.295)}` over `$d` (Effect[0] aura 3
PERIODIC_DAMAGE, EffectAmplitude 2000 ms, 14000 ms). Both effects own tooltip tokens, so `hits.hit_kind` refused its
`hit_mean` and periodic total as several hit models. The harness recorded the direct hit
(`SMSG_SPELLNONMELEEDAMAGELOG`) and the ticks (`SMSG_PERIODICAURALOG`) as one kind of `SpellDamageEvent` under the same
spell id, so a split model would still have judged mixed events. Mentor D-317 approved the split, D-320 the harness flag.

## Options

- Keep the refusal: the claim stays unproven.
- Judge one model over the sum of both effects: the hit_mean label would mix one direct hit and seven ticks per cast.
- An opt-in class-file field naming the effect of each label, with a harness flag that tells direct from periodic
  events.

## Decision

- `rank_hit_effects` {rank id: {`hit_mean`, `periodic_total`, `source`}}: `hits.rank_hit_effect` refuses an entry
  without a non-blank source, with another field, or without two distinct effect indexes 0 to 2.
  `hits.rank_hit(..., check)` keeps only the named effect's tooltip values before `hit_kind`, and `checked_role`
  refuses a named effect whose model is not the label's. `reference_hit_model` and `hit_parts` pass the check;
  `conformance.add_periodic_total` asks for `periodic_total`.
- Harness (read and record only, G-39 note `g39-periodic-flag.md`): `SpellDamageEvent.periodic` is set for
  `SMSG_PERIODICAURALOG`; `spell_damage_total`/`spell_damage_count` take an optional boolean `periodic` filter
  (`run.py` allows it). `hits.hit_measurements` adds `periodic` only for a rank with an entry.
- The spell power and ranged attack power terms are proven by `metric_delta` entries (D-57): `bolt_sp` (one forced
  ranged crit at +20000 spell power, direct events), `bolt_dot_total` and `bolt_dot_rap` (the periodic events at the
  reference and +20000 ranged attack power).

## Consequences

- Ranks without an entry generate byte-identical scenarios: digests 19 and 23 unmoved; Witch Hunter only gains the
  501349 hit parts and the three arms.
- 501349's periodic_total label stays unmodelled for another reason: `$m1` rolls 88..89 once per aura (EffectDieSides[0]
  2), so its ticks are not independent hits (the existing `expected_hit` rule). The metric_delta arms measure the
  periodic part instead.
- Tests: `RankHitEffectsFieldTest`, `RankHitEffectsDataTest` (test_hits.py; mutant with the effects swapped is
  refused), `test_periodic_spell_damage_event_filter` (test_runner.py). Harness mutant: the pair's arms with the flag
  inverted alert.
