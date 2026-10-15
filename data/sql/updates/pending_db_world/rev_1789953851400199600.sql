--
-- Dreamslip (#3583): native pacify/silence with the existing half-second recovery.
SET @ScriptName = 'aura_ascension_dreamslip';
DELETE FROM `spell_script_names` WHERE `spell_id` = 805867 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (805867, @ScriptName);
