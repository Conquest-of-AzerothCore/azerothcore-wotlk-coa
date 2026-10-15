--
-- Power Hammer (#1835): keep the additional Rage bonus conditional on a two-handed weapon.
SET @ScriptName = 'aura_ascension_power_hammer';
DELETE FROM `spell_script_names` WHERE `spell_id` = 303014 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (303014, @ScriptName);
