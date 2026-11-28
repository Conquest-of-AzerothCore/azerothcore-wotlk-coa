-- Cloak of Flames (3475): equip damage shield 909276 "Immolation" had no spell power or attack power coefficient
-- (no spell_bonus_data row, EffectBonusMultiplier 0). Tooltip: ${$m1+0.035*$SP+0.023*$AP} Fire damage.
DELETE FROM `spell_bonus_data` WHERE `entry` = 909276;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(909276, 0.035, 0, 0.023, 0, 'Cloak of Flames - Immolation');

-- AuraEffect::CalculateAmount and Unit::DealDamageShieldDamage both add the caster bonus to a damage shield; the
-- script keeps the stored amount at its base so the bonus is added once, per hit.
DELETE FROM `spell_script_names`
  WHERE `spell_id` = 909276 AND `ScriptName` = 'aura_ascension_damage_shield_single_bonus';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(909276, 'aura_ascension_damage_shield_single_bonus');
