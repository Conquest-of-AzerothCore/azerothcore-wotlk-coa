# 0031. `$pplN` tokens scale by the caster's actual level, not the skill rank

- Status: accepted
- Date: 2026-11-08
- Related: does not reopen [ADR 0014](0014-level-scaled-tooltip-values-use-the-skill-rank.md) ("level-scaled
  tooltip values use the skill rank"), which keeps governing `$mN`/`$sN`.

## Context

ADR 0014 left `$<id>pplN` unreadable ("no client handler" found in the decompiled client) and sent it to the
player question list. Round 3's `player-numbers-spec.md` investigated the 2026-11-07 player report against the
7 Templar tooltips that carry it (Force of Golganneth, Norgannon's Wrath, Divine Charge, Eternal Blessing,
Libram of Consecration, Silverhand Incantation, Armor of Faith): all 7 formula spells (803153, 524740, 527270,
707111, 804148, 801465, 801546) have no `SkillLineAbility` row, so `client_spell_level` (ADR 0014's skill-rank
reading, reused by `$mN`/`$sN`) resolves to 0 for every one of them regardless of the character's real level.
Reusing that same skill-rank reading for `$pplN` would therefore make the per-level term 0 on every rank, which
cannot be tested against the player's numbers (a term that is always 0 explains nothing).

Two of the 7 readings carry no `$AP`/`$sph` term at all (Libram of Consecration, Eternal Blessing), so they check
`$pplN` alone, independent of the player's unstated attack power, spell power and spec. Eternal Blessing's own
`EffectRealPointsPerLevel` is 0 (so it gives no information either way), but Libram's is not: its reported 188
matches `EffectBasePoints + 1 + EffectRealPointsPerLevel × max(0, 60 − BaseLevel)` exactly (`20 + 4.0 × (60 − 18)
= 188`), using the character's actual level 60. The skill-rank reading would give `20 + 4.0 × 0 = 20`, which does
not match. No other hypothesis was tested against evidence; this is the only one the player's own tooltip number
confirms.

## Considered options

1. Reuse `client_spell_level`/`points_level`, exactly like `$mN`/`$sN` (ADR 0014). Rejected: contradicted by
   Libram of Consecration's exact, SP-independent match above; every one of the 7 formula spells would read a
   flat 0 per-level term, which the evidence does not support.
2. Read `$pplN` by the caster's actual level (`CasterStats.level`), reusing the existing `levels_above_base`
   helper (the same `max(0, level − BaseLevel)` clamp `$mN`/`$sN` already apply, just fed a different level).
   Chosen: it is the only hypothesis Libram of Consecration's player-reported number confirms exactly, and it
   needs no new per-level arithmetic (`Records.levels_above_base` already existed for the skill-rank path).
   Caveat: the harness's own reference caster is always level 60, the same level the 2026-11-07 report was
   read at, so this single confirming data point cannot by itself distinguish "scales by `caster.level`" from
   "always evaluates the per-level term at a hardcoded level 60" — both predict the identical 188 here. The
   actual-level reading is still chosen on design grounds (it is the general rule; a hardcoded 60 is not a
   rule at all, only this round's accidental test condition), not because the evidence rules out the
   hardcoded-60 alternative; it does not.

## Decision

`Tooltip.per_level_points(spell_id, effect)` returns `EffectRealPointsPerLevel[effect] × max(0, caster.level −
BaseLevel)`, or `0` when `EffectRealPointsPerLevel` is `0`; `0` short-circuits without touching `BaseLevel` or
raising, so a `$pplN` token never joins the three `client_spell_level` failure cases ADR 0014 documented for
`$mN`/`$sN` (skill not measured, race/class unknown, several ability lines). `math_variable` resolves
`$pplN`/`$<id>pplN` (`ExpressionParser` only; the token never appears as a standalone text macro) to this value,
with `own_effect`/`spell_reference` exactly as `$mN` already uses them. `$mN`/`$sN` keep reading
`client_spell_level` unchanged: ADR 0014 is not reopened.

## Consequences

- The 7 Templar `$pplN` tokens stop being unreadable and join the reference-caster `effect_value`/`hit_mean`
  checks ADR 0014 already runs for `$mN`/`$sN`-only entries, via the existing foreign-effect routing in
  `values.py` (no metric or scenario change needed).
- `classes/templar.json`'s new `player_tooltip_readings` (README, "Player tooltip readings") cites the
  2026-11-07 report for all 7 as corroboration, never as the expected value; Libram of Consecration and Eternal
  Blessing's entries carry the exact, SP-independent confirmation above.
- Three of the 7 now-judged checks alert at the harness's reference caster (Divine Charge, Silverhand
  Incantation, Armor of Faith): each measured value is short of the expected one by almost exactly the AP (or
  AP/SP) term the formula adds. This matches the `effect_value` scope ADR 0014 already documents ("`CalcValue`
  before aura scripts (`CalcAmount` hooks not covered)"; its own Staffguard alert was such an artifact, not a
  server defect) rather than a new defect this ADR introduces; it is reported as a round-3 follow-up (an
  `aura_amount` check on the live aura, if one applies, is ADR 0014's own remedy), not fixed here.
- Argent Blade/Scourgebane's `scalingbp` reading is unaffected by this ADR (a different gap, cross-spell `$<name>`
  resolution) and stays a player question: evaluated at the player's stated attack power it is 260-330 points
  above the reported number under either candidate spell power.
