# 0031. Blightbreaker gives Mercy a 2 sec period

- Status: accepted (owner ruling O-24, 2026-11-22)
- Date: 2026-11-22

## Context

Blightbreaker 707433: "Increases the tick rate of Mercy by $s1%, but increases its mana cost by $s2%."

Effect 0 is aura 108 `SPELLMOD_ACTIVATION_TIME` at -50 and effect 1 aura 108 `SPELLMOD_COST` at +100, both on
class mask word 0 = 32 of family 33. Mercy 504848 has a 12000 ms duration (DurationIndex 29), effect 0 aura 23 with
a 3000 ms amplitude, and `SPELL_ATTR5_EXTRA_INITIAL_PERIOD`. The stock engine applies the -50% to the amplitude
(`SpellAuraEffects.cpp:725`): a 1500 ms period, twice the ticks.

Owner ruling O-24 (2026-11-22, confirmed "option 2"): the duration stays and the tick rate rises by 50%, so the period
is 3000 x 100 / 150 = 2000 ms. Mentor note D-74, which kept the 1500 ms period, is withdrawn.

The mask also matches Champion of the Sun 800612, a Sun Cleric spell with no periodic effect. Only the periodic
amplitude reads `SPELLMOD_ACTIVATION_TIME` in the engine.

## Options

1. Keep the percent modifier and set it to -33: 3000 x 0.67 = 2010 ms, not 2000. `SpellModifier::value` is an
   integer.
2. Rewrite Blightbreaker's effect 0 modifier in a `DoEffectCalcSpellMod` hook as a flat change limited to Mercy
   (-1000 ms). The passive's `spell_modifier` data check, generated from the DBC percent (-500 on base 1000), would
   then read -1000, and the class file cannot express a percent modifier turned flat without a tool change.
3. Set Mercy's amplitude in a `DoEffectCalcPeriodic` hook, which runs before the engine applies the modifier
   (`SpellAuraEffects.cpp:709`, then `:725`): the target period `P x 100 / (100 + 50)`, divided in advance by the
   modifier's factor, `x 100 / (100 - 50)`. 3000 gives 4000 in the hook and 4000 x 0.5 = 2000 after the modifier.

## Decision

Option 3. `aura_ascension_sun_cleric_mercy` (`AscensionSunClericAuras.cpp`), bound to Mercy 504848 by
`rev_20261122_31_sun_cleric_blightbreaker_mercy_period.sql`, reads the amount of the caster's Blightbreaker effect 0
(-50) and sets effect 0's amplitude as above. Without Blightbreaker the hook changes nothing. Blightbreaker's two
modifiers stay as the DBC gives them.

## Consequences

- Mercy cast with Blightbreaker has a 2000 ms period over its unchanged 12000 ms duration, chained copies included
  (the hook reads the caster, as the engine's modifier does).
- Measured tick counts over the whole aura, the tick on apply and the tick at 12000 ms included: 5 without the talent,
  7 with it (9 with the stock 1500 ms period, by the same count).
- The modifier query still reads the DBC -50% (1500 on base 3000): the period is set on the aura, not on the
  modifier. The mana cost stays doubled.
- The client is unchanged: it reads the same DBC modifier, so a client display derived from the -50% period
  modifier may show 1.5 sec instead of 2 sec. Whether the 3.3.5 client applies that spellmod to Mercy's
  `$t1` was not checked.
- No engine file changes. Only 707433 carries a `SPELLMOD_ACTIVATION_TIME` modifier on Mercy's class mask; the hook
  reads its amount, so a change of that value in the data moves the result with it.
- Regression: `sun-cleric-blightbreaker-mercy` reads the period and counts the Mercy Proc 503650 ticks over the whole
  aura without the talent (3000 ms, the control) and with it (2000 ms), and keeps the cost ratio. The class file entry
  `707433 mercy_period` expects 2000.
