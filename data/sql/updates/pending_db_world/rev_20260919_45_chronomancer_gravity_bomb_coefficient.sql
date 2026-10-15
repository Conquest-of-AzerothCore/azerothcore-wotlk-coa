-- Gravity Bomb (801281) states its explosion as
-- "${($801282m1+$801282ppl1+$SP*1.2+$RAP*0.3)} Chromatic Damage in a $801254a1 yds radius".
-- The explosion itself is the child 801282, a single SPELL_EFFECT_SCHOOL_DAMAGE with
-- EffectBasePoints 966 and EffectRealPointsPerLevel 6.0 (the $801282m1 + $801282ppl1 terms).
-- Its EffectBonusMultiplier is 0.0 in the shipped Spell.dbc - it is not one of the records
-- AscensionStockCoefficients.cpp clears, it simply carries no value - and it had no `spell_bonus_data`
-- row anywhere in data/sql/, no rank chain to fall back to and no script. Unit::SpellDamageBonusDone
-- therefore starts from `coeff = Effects[effIndex].BonusMultiplier` (0.0), finds no SpellBonusEntry and
-- adds nothing, so the explosion landed for its flat base only: none of the tooltip's scaling existed.
-- This row supplies the spell-power half, which the formula settles unambiguously: direct_bonus 1.2.
-- The $RAP*0.3 term is deliberately NOT added here. Per .agents/docs/systems/ascension-spell-parity.md
-- the damage path selects ranged attack power only when `UseRangedAttackPowerForDamage` is set or
-- `IsRangedWeaponSpell() && DmgClass != SPELL_DAMAGE_CLASS_MELEE`; 801282 is DmgClass 1 (MAGIC) with
-- EquippedItemClass -1 and no SPELL_ATTR0_USES_RANGED_SLOT, so a plain `ap_bonus = 0.3` would read melee
-- attack power instead. Choosing between that and the `UseRangedAttackPowerForDamage` opt-in is a design
-- decision the parity contract forbids guessing, so the 0.3 term stays unimplemented and #3202 stays open.
DELETE FROM `spell_bonus_data` WHERE `entry` = 801282;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(801282, 1.2, 0, 0, 0, 'Local Chronomancer: Gravity Bomb - explosion spell power coefficient');
