-- May We Be Reunited 254091 (#12443): 'Arvis Reunion Credit' 355229 gives the 254905 credit only to units whose
-- creature type is in its TargetCreatureType mask 211 (beast, dragonkin, giant, humanoid, critter). A Knight of
-- Xoroth with Demon's Blood 804345 is a demon, and a Necromancer or Reaper in its undead aura is undead
-- (Unit::GetCreatureType), so neither the reunion talk nor the caged worgen's gossip could credit them. Give the
-- same credit directly: Julie Addle's talk credits every player within the spell's 30 yards, and opening the
-- worgen's gossip credits the speaker while they carry 254091.
DELETE FROM `smart_scripts`
WHERE (`entryorguid` = 764561 AND `source_type` = 0 AND `id` = 3)
   OR (`entryorguid` = 25490600 AND `source_type` = 9 AND `id` = 11);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
  `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
  `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(764561, 0, 3, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 254905, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Nightbane Worgen - On Gossip Hello - Quest Credit ''May We Be Reunited'''),
(25490600, 9, 11, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 33, 254905, 0, 0, 0, 0, 0, 18, 30, 0, 0, 0, 0, 0, 0, 0, 'Julie Addle - Actionlist - Quest Credit ''May We Be Reunited'' to players within 30 yards');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 4 AND `SourceEntry` = 764561 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 4, 764561, 0, 0, 9, 0, 254091, 0, 0, 0, 0, 0, '', 'Nightbane Worgen - direct credit only on ''May We Be Reunited''');
