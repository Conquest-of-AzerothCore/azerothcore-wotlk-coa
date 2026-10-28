-- Issue #7190: Nerve Venom coating 808065 promises "$AP*0.05" Nature damage on its
-- weapon proc 570244, but nothing supplied the melee attack-power term server-side,
-- so procs dealt only the DBC base plus level scaling (24 instead of 63 on dummies).
-- $AP is melee attack power (Skullpiercer writes $RAP*0.25+$AP*.1 for ranged/melee).
-- The proc is DmgClass RANGED with a ranged weapon mask, so native ap_bonus would
-- select ranged attack power; spell_ascension_ranger_nerve_venom adds 0.05 * melee
-- attack power on effect 0 instead (AscensionRangerScaling.cpp).
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 570244 AND `ScriptName` = 'spell_ascension_ranger_nerve_venom';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(570244, 'spell_ascension_ranger_nerve_venom');
COMMIT;
