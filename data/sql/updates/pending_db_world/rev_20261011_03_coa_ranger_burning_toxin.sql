-- Issue #7189: Burning Toxin coating 808029 promises "$AP*0.1" Fire damage on its
-- weapon proc 570245, but nothing supplied the melee attack-power term server-side,
-- so procs dealt only the DBC base plus level scaling (about 31 instead of 129 on
-- dummies at the reporter's attack power). $AP is melee attack power (Skullpiercer
-- writes $RAP*0.25+$AP*.1 for ranged/melee, and #7190 established the same reading
-- for the sibling Nerve Venom $AP term). The proc carries the ranged weapon mask,
-- so native ap_bonus would select ranged attack power; spell_ascension_ranger_burning_toxin
-- adds 0.10 * melee attack power on effect 0 instead (AscensionRangerScaling.cpp).
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 570245 AND `ScriptName` = 'spell_ascension_ranger_burning_toxin';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(570245, 'spell_ascension_ranger_burning_toxin');
COMMIT;
