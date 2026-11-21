# 0012. Smite Evil casts its Wickedness strike only with Wickedness

- Status: accepted
- Date: 2026-11-16

## Context

Smite Evil ranks 2-7 (803359-803364) carry Effect[1] 142 TRIGGER_SPELL_WITH_VALUE to 802844 "Smite Evil
(Wickedness)". 802844 has CasterAuraSpell 802015 (Wickedness) and a 100 ms periodic aura on the caster whose ticks
cast 803710, which grants or extends Flames of Sin 803422 by 3000 ms. EffectTriggerSpell casts 802844 with
TRIGGERED_FULL_MASK, which includes TRIGGERED_IGNORE_CASTER_AURASTATE, and `Spell::CheckCast` skips CasterAuraSpell
under that flag. So every landed Smite Evil granted Flames of Sin to every Witch Hunter, with or without Wickedness.

Flames of the Sinned 560207 reads: "Your Smite Evil now has a $h% chance to strike again. While you have Flames of
Sin active, the chance to trigger this effect is increased by $803422s3%." ($h 25, $803422s3 10). Its plain arm
(claim 96.0, no Flames of Sin fixture) measured 35.4% (93 recasts in 263 casts), the same as the Flames of Sin arm.
The live logs show 23.1% without Flames of Sin, 33.5% with it, and no 802844 event in 186 logs. No Smite Evil text
mentions Flames of Sin; the Wickedness 802015 text does. 802844 deals no damage (Effect[0] is a dummy effect with no
handler), and 802015 has no acquisition route (deprecated talent 500058).

Mentor ruling D-191: fix option (B), Witch Hunter code only, no SQL.

## Options

- (B) In `spell_ascension_witch_hunter_ability`, already bound to every Smite Evil rank, prevent the 142 effect that
  triggers 802844 when the caster lacks 802844's CasterAuraSpell.
- (A) A SpellScript on 802844 with an OnCheckCast on 802015: needs a spell_script_names row, SQL not authorized.
- Honour CasterAuraSpell for triggered casts in `Spell::CheckCast` or EffectTriggerSpell: an engine change for every
  class, against the stock "not for triggered spells (needed by execute)" rule.

## Decision

Option (B): `Launch` in `AscensionWitchHunterAbilities.cpp`, hooked on OnEffectLaunch and OnEffectLaunchTarget for
every effect, prevents an effect whose type is TRIGGER_SPELL_WITH_VALUE and whose TriggerSpell is 802844 unless the
caster has 802844's CasterAuraSpell. The 560207 recasts go through the same script.

## Consequences

- Without the 802015 aura, Smite Evil no longer casts 802844, so it no longer grants or extends Flames of Sin; the
  Smite Evil hit, rank 1 and every other Flames of Sin source are unchanged.
- With the 802015 aura, Smite Evil casts 802844 and grants Flames of Sin as before.
- 560207 reads 25% without Flames of Sin and 35% with it. Regressions: `560207 proc_rate` and `560207 proc_rate
  803364 with 803422` on one pair, `560207 behaviour_metric_delta smite_evil_no_flames` (no 803422 after a plain
  cast), `560207 behaviour_metric_delta wickedness_flames_grant` (803422 granted with the 802015 aura) and
  `803364 hit_mean`.
- If 802844 ever loses its CasterAuraSpell, the guard lets the trigger through.
