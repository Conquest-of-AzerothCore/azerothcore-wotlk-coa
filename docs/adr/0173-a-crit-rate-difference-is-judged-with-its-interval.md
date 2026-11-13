# 0173. A crit-rate difference is judged with its interval

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0125 (hit ratios), the chance-claim ruling of 2026-11-12 (method-study/owner-rulings-2026-11-10.md)

## Context

Scourge-Defense Training 520608, "and critical strike chance of your next Argent Blade by $s1%" (50): the existing
entries read the crit modifier back (spell_done_crit_chance) or forced every crit. A behaviour read counts critical
hits over trials. With the ruled band of 5% of 50 (2.5 points), a 99% interval inside it needs thousands of casts
per arm, beyond one accelerated scenario. The mentor's ruling: about 300 casts per arm first, recorded as "effect
present, interval stated", not final; the pooled proof to the band follows with the ext2 pooling extension.

## Options

1. A hit ratio on critical hits only. It measures damage, not the share of hits that crit.
2. A kind that counts landed and critical hits per arm and judges the difference of the critical shares with an
   interval.

## Decision

Option 2. Kind `crit_rate` (check `behaviour_crit_rate`), built on the hit_ratio fields (observe_spell, arms with
auras or casts, learn, trials, default 300), with no forced crit and no crit filter. Each arm counts
`spell_damage_count` and its `critical: true` share between a start and an end read; the scenario uses the
accelerated cap. The judge takes the 99% Newcombe interval of the difference (a Wilson interval per arm): ok when it
lies inside the band, alert when it misses the band, `measured` otherwise, with the interval, what it excludes and
the hits per arm an interval inside the band would need at the measured shares. `measured` is not conformant, so
the claim is not proven by it.

## Consequences

- Without a `crit_rate` entry every scenario regenerates byte-identical.
- Seeded tests: 1500 of 3000 against 0 of 3000 is ok; 150 of 300 is measured; no change and the older +20 alert;
  fewer landed hits than half the trials are not judged; a forced crit is refused.
