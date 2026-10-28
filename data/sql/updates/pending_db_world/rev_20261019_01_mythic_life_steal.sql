-- Mythic+ Life Stealing (80026) procs Life Steal 80027, which drains 2% of the target's maximum health. Its effect 1
-- healed the caster for 5% of its own maximum health, so key-scaled creatures healed far more than they drained.
DELETE FROM `spell_script_names` WHERE `spell_id` = 80027 AND `ScriptName` = 'spell_coa_mythic_life_steal';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(80027, 'spell_coa_mythic_life_steal');
