-- Remove 4979 "Quick Flame Ward" from 1096 "Venture Co. Geologist" and 4723 "Foreman Cozzle" (STV)
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (1096, 4723) AND `Spell` = 4979;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (1096, 4723) AND `source_type` = 0 AND `action_type` = 11 AND `action_param1` = 4979;
