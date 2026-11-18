# 1010. Blade of Faith's ticks gain the Oath's own 30% for each Lunge or Retribution stack

- Status: accepted
- Date: 2026-11-18
- Supersedes: [0289](0289-blade-of-faith-ticks-gain-ten-percent-per-unreached-oath.md) (its value only)

## Context

Blade of Faith 803872-803880 reads "Consumes your Oaths, dealing additional damage for each consumed." and gives no
per-Oath number. ADR 0289 made Oath: Righteous Lunge 804904 and Oath: Retribution 804924 raise the ticks by a
provisional +10% per stack, because their only damage mods (SPELLMOD_DAMAGE) are not read on the periodic path.

Issues #12358 and #12519 report that stacking Oaths barely changes Blade's damage. The investigation
(`.agents/plans/templar-followup/blade-of-faith.md`) found:
- the +10% is applied as ADR 0289 states;
- both Oaths carry Effect[2] aura 108 SPELLMOD_DAMAGE +30% (BasePoints 29, DieSides 1), the same +30% per stack that
  the direct Oath Breakers read;
- uncontrolled live combat logs (`~/Projects/coa-log-history`) suggest about +22% to +27% per Lunge or Retribution
  stack on live Blade ticks. This is a hypothesis from the logs, not a measured value.

The owner ruled on 2026-11-18: each consumed Lunge or Retribution stack adds +30% to Blade's ticks, additive per
stack as before. Condemn, Vindication and Holy Cleave keep their own paths.

## Options

- Raise the constant from 10 to 30. It works, but the number would be copied from the data.
- Read each held Oath's Effect[2] amount, as Righteous Tempest 805409 sums its Oaths
  (`AscensionTemplarAuras.cpp`). Chosen. `AuraEffect::CalculateAmount` already multiplies the amount by the stack
  count, so the sum is 30 per stack.

## Decision

`AddBladeOfFaithUnreachedOathBonus` (`AscensionTemplarContracts.cpp`) sums `GetAuraEffect(oath, EFFECT_2)->GetAmount()`
over `BLADE_OF_FAITH_UNREACHED_OATHS` {804904, 804924}. Negative amounts count as zero. The amount becomes
`amount x (100 + sum) / 100`. The constant `BLADE_OF_FAITH_UNREACHED_OATH_BONUS_PCT` is removed. The hook point is
unchanged, and so is ADR 0289's rule for Keeping the Oath: a held Oath counts the same as a consumed one.

## Consequences

One tick of 803880 (rank 9, level 60, crit forced to 0), against the 191 no-Oath tick measured under ADR 0289. All
values are computed (c). None was measured on this change before it was written.

| Oath(s) at cast | ADR 0289 | ADR 1010 |
|---|---:|---:|
| 1 Righteous Lunge or Retribution | x1.0995 (m) | x1.30 (c) |
| 2 Righteous Lunge | x1.20 (m) | x1.60 (c) |
| 10 Righteous Lunge (the chain maximum) | x2.00 (c) | x4.00 (c) |
| Lunge under Keeping the Oath | x1.0995 (m) | x1.30 (c) |
| Lunge + Condemn (`oaths`, AP/SP 20000) | x1.375 | x1.625 (c: 1.30 x 1.25) |
| all five | 388 (m) | about 517 (c: 216 x 1.60 = 345, then x 1.50) |
| 10 Condemn | x3.50 (c) | x3.50 (c, unchanged) |

- Regressions: `templar-blade-of-faith-consumed-oaths` (bounds moved to the new values) and the new
  `templar-blade-of-faith-ten-oaths` (10 Lunge stacks x4.00; a control arm with 10 Condemn stacks at x3.50).
- Conformance (`classes/templar.json`): `oath_lunge`, `oath_retribution` and `oath_lunge_keeping_the_oath` go from
  1.10 to 1.30, `oaths` from 1.375 to 1.625, and `oath_all` from 2.0356 to 2.7141. `oath_condemn`, `oath_vindication`
  and `oath_cleave` are unchanged controls. The Templar snapshot digests are rewritten.
- A spell modifier that raises an Oath's Effect[2] amount now raises Blade's bonus too, as it already does for
  Righteous Tempest. No such modifier is held in the regressions.
- Not changed, recorded as observations: Holy Cleave's +25 flat per tick against little effect in the live logs,
  and our ten-grant cap on the whole chain while live Oath kinds kept stacking past it.
