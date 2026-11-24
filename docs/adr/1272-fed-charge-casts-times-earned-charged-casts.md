# 1272. Fed charge casts times the charged casts of an earned aura

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

Felsworn Felforged 300490 grants Felforged 806104 on a periodic damage tick at its raw ProcChance 15 ("Your next 3 Fel
Fireballs have a $s1% reduced cast time for $d."). The charge and cut entries set 806104 with `set_aura`, which
mentor D-67 does not accept for a passive's claim. A real feed with a fixed read after it misses the aura (fw-fa4:
806104 lasts 8000 ms, so it is gone at the read in most trials), and a single early and late cast count read cannot
resolve a 30% cut at the accelerated clock: wait steps are up to 25 ms against a 45 ms margin on each side of the
1050 ms cut cast.

## Options

- Extend `aura_fed_effect`: edits a kind module a finished class (Sun Cleric) uses.
- A metric_delta option with set_aura and an equivalence arm: still a harness-set aura on the judged casts.
- A new additive kind that feeds for real, stops at the grant, unlearns the talent, and times each charged cast by
  polls bracketed with game-time stamps.

## Decision

The third option, `fed_charge_casts` (CONF/docs/kinds/fed_charge_casts.md). The cut and the cast time come from the
DBC (aura Effect `ADD_PCT_MODIFIER` on `SPELLMOD_CASTING_TIME`, `EffectBasePoints` + 1; the effect spell's
`CastingTimeIndex`), the charge count from the tooltip. Bands are 10% of the figure for the cut casts and 10% of the
cast time for the next one. A bracket wholly outside its band in any judged trial alerts; straddling or fewer than
`min_judged` judged trials is unmeasured (mentor D-97, conditions 1 and 2). The verdict is stamped with
`spell_cast_count`, an existing event row: no evidence table changes.

## Consequences

- Additive: no shared file changes; the finished classes regenerate byte-identical.
- The talent is unlearned at the stop so that no later roll refreshes the aura or resets its charges; the aura must
  read present after the unlearn. An alert is diagnosed with the unlearn as a candidate cause before any server fix.
- Each trial waits for a real grant: up to `max_casts` feed casts (54 at 15% and 0.001 for three trials a pair).
