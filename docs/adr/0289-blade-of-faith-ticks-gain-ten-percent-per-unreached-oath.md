# 0289. Blade of Faith's ticks gain 10% for each consumed Oath that missed them

- Status: accepted
- Date: 2026-11-12

## Context

Blade of Faith 803872-803880 reads "Unleash a devastating Oath Breaker on an enemy dealing ... Holy damage over $d.
... Consumes your Oaths, dealing additional damage for each consumed." Its damage is periodic (effect 0, aura 3,
every 3000 ms). The Oaths strengthen the direct Oath Breakers through SPELLMOD_DAMAGE mods, which the periodic path
(`Unit::SpellDamageBonusDone` with DOT, which applies SPELLMOD_DOT) never reads. So Oath: Righteous Lunge 804904 and
Oath: Retribution 804924 added nothing to Blade's ticks. Oath: Condemn 804922 and Oath: Vindication 805332 reach
them by data (+25 on effect 1, aura 271), and Oath: Holy Cleave 804903 adds +25 per tick (SPELLMOD_DOT).

The owner ruled on 2026-11-12 (Q-r2b-1, claim 364, option b): every consumed Oath must strengthen the ticks, at +10%
per Oath. This is a provisional tuning value, not a derived one ("disons +10% pour le moment et voir ce que ça donne
comparé aux autres"). FableMentor stated the scope:
- the +10% applies only to the Oaths whose data add nothing to the ticks;
- the other Oaths keep their own effects;
- the bonuses are additive, as Righteous Tempest sums its Oaths (`AscensionTemplarAuras.cpp`, 805409);
- under Keeping the Oath (92109 / 803149), Blade mirrors the direct Oath Breakers.

Reference search: the coabuildhub and sidekick snapshots carry the same text; nothing found on Blade's per-Oath
values.

## Measured before the change (run 20261112-081220, level 60, crit forced to 0)

- One tick of 803880 with no Oath: 191.
- Righteous Lunge: x1.000. Retribution: x1.000, so it stays in the set.
- Vindication: x1.246, the same as Condemn, so it stays out of the set.
- Holy Cleave: x1.131. All five Oaths: x1.696 (324).
- A direct Breaker, Righteous Upheaval 572027 with the Lunge Oath, read +36.5% with Keeping the Oath 92109 held, the
  same as without it. Keeping the Oath stops the Oaths from being consumed
  (`templar_casts::OnSpellCast`, the `ClearOaths` gate), but a held Oath still raises a direct Breaker's hit.
  Blade therefore gets its +10% for a held Lunge or Retribution Oath under Keeping the Oath too.

## Options

- A `UnitScript` hook on `OnAfterAuraEffectCalculateAmount` for Blade's effect 0, multiplying the done amount by
  1 + 0.10 x n. Here n is the number of Lunge and Retribution Oath stacks the caster holds.
  - Blade has no travel time, so the amount is computed in `Spell::handle_immediate`, before `OnSpellCast` clears
    the Oaths.
  - A recast or refresh recomputes the amount from the Oaths held at that cast.
- Raise the spell modifiers of the two Oaths onto SPELLMOD_DOT. Rejected: the same mods also apply to the direct
  Breakers, which would gain twice.

## Decision

`templar_scaling` (`AscensionTemplarContracts.cpp`) registers `UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT`.
For a Blade rank's effect 0 on a unit, the amount becomes
`amount x (100 + BLADE_OF_FAITH_UNREACHED_OATH_BONUS_PCT x n) / 100`, with:
- the constant at 10;
- `BLADE_OF_FAITH_UNREACHED_OATHS` = {804904, 804924};
- n counted per stack, as Righteous Tempest sums its Oaths' stacked amounts.

The count is read at each calculation and is not cached. A recalculation after the Oaths are gone, with no new cast,
would drop the bonus. No engine path that does so for Blade was found. The engine is unchanged.

## Consequences

One tick of Blade of Faith 803880 (rank 9, level 60, crit forced to 0). The Lunge + Condemn row comes from the
`oaths` entry, run at attack and spell power 20000, so its ticks are 191 times the measured ratio. m = measured on
the counted pair 20261112-081901 / 20261112-081939 (worldserver ead9e58d…), identical in both runs; c = computed.

| Oath(s) consumed | Before | After |
|---|---:|---:|
| none | 191 (m) | 191 (m) |
| Righteous Lunge 804904 | 191 (m) | 210 (m, x1.0995) |
| Retribution 804924 | 191 (m) | 210 (m, x1.0995) |
| Condemn 804922 | 238 (m) | 238 (m) |
| Vindication 805332 | 238 (m) | 238 (m) |
| Holy Cleave 804903 | 216 (m) | 216 (m) |
| Lunge + Condemn | 238.7 (c: 191 x the measured x1.2499) | 262.6 (c: 191 x the measured x1.3749) |
| all five | 324 (m, x1.6963) | 388 (m, x2.0314) |
| Lunge under Keeping the Oath | 191 (m) | 210 (m) |

- The all-five order is: +25 flat inside the done amount, then the hook's x1.20, then aura 271's x1.50 at the tick.
  (191 + 25) x 1.20 = 259, and 259 x 1.50 = 388.
- Multiplicative alternative, not chosen: 216 x 1.10 x 1.10 x 1.50 = 392.04 (c).

One direct Oath Breaker, for comparison, unchanged by this decision. Each figure is the factor on a non-critical hit
against no Oath. d = by data.

| Oath(s) consumed | Factor |
|---|---:|
| Righteous Lunge | 1.365 (d); Righteous Upheaval 572027 measured +36.1% / +36.8% |
| Lunge under Keeping the Oath | Righteous Upheaval measured +36.4% / +36.7% |
| Condemn, Retribution or Vindication | 1.30 (d) |
| Lunge + Condemn | 1.7745 (d) |
| all five | 2.999 (c: 1.05 x 1.30^4) |

- Regression: catalog scenario `templar-blade-of-faith-consumed-oaths`, one arm per row of the first table, each on
  its own dummy, 13 yd apart.
- Conformance changes:
  - `oath_lunge` 1.0 -> 1.10;
  - `oaths` 1.7745 -> 1.375;
  - new entries `oath_retribution` 1.10, `oath_vindication` 1.25, `oath_all` 2.0356 and
    `oath_lunge_keeping_the_oath` 1.10;
  - new direct Breaker control `572027 oath_keeping_the_oath` 1.365;
  - `oath_condemn` and `oath_cleave` are unchanged controls.
- All 23 labels are ok on both runs of the pair.
- The 10% is provisional. Changing it means changing the constant, the catalog bounds and the expected values of
  the conformance entries.
