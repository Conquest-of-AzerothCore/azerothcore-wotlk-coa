--
-- Earthmother's Roar (#1815): heal the raid for 20% missing health after Protective Roar.
SET @ScriptName = 'spell_ascension_earthmother_roar';
DELETE FROM `spell_script_names` WHERE `spell_id` = 802782 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802782, @ScriptName);
SET @ScriptName = 'spell_ascension_earthmother_missing_health';
DELETE FROM `spell_script_names` WHERE `spell_id` = 301307 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (301307, @ScriptName);

DELETE FROM `spell_bonus_data` WHERE `entry` = 301307;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (301307, 0, 0, 0, 0, 'Earthmother Roar: missing-health base, without an additional SP or AP coefficient');
