--
-- SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN names one spell id in EffectMiscValue and
-- Player::ModifySpellCooldown keys the cooldown map by that exact id, while
-- Player::AddSpellAndCategoryCooldowns stores the cast rank's cooldown under its own id.
-- The named rank-1 ids below therefore leave the rank a level-80 player casts untouched:
-- 801854 Titanstorm -> 801847 Arm of Thorim (9 ranks), 560030 Lightning Cage (single);
-- 300828 Cyclone's Recharge -> 500039 Kiss of the Clouds (9 ranks);
-- 680878 Master Airbender -> 806124 Aerodynamics, 500039 Kiss of the Clouds, 804035 Tailwind.
-- The script walks the caster's cooldown map by rank chain instead.
SET @ScriptName = 'spell_ascension_stormbringer_cooldown_reduction';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (300828, 680878, 801854) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(300828, @ScriptName),
(680878, @ScriptName),
(801854, @ScriptName);
