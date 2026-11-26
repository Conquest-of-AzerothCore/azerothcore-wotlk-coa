-- #13690, #13606: remember the summon across evades; SmartAI clears its data on respawn.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10737 AND `source_type` = 0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,
 `event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,
 `target_z`,`target_o`,`comment`) VALUES
(10737,0,0,0,0,0,100,0,5000,5000,5000,10000,0,0,
 11,14100,0,0,0,0,0,2,0,0,0,0,
 0,0,0,0,'Shy-Rotam - In Combat - Cast \'Terrifying Roar\' (No Repeat) (Normal Dungeon)'),
(10737,0,1,0,0,0,100,0,7000,9000,22000,27000,0,0,
 11,13443,0,0,0,0,0,2,0,0,0,0,
 0,0,0,0,'Shy-Rotam - In Combat - Cast \'Rend\' (No Repeat) (Normal Dungeon)'),
(10737,0,2,0,0,0,100,0,2000,3000,15000,20000,0,0,
 11,3604,0,0,0,0,0,2,0,0,0,0,
 0,0,0,0,'Shy-Rotam - In Combat - Cast \'Tendon Rip\' (No Repeat) (Normal Dungeon)'),
(10737,0,3,4,0,0,100,1,0,50,0,0,0,0,
 12,10741,1,180000,0,0,0,8,0,0,0,0,
 8074.84,-3840,690.061,4.6,'Shy-Rotam - In Combat - Summon Creature \'Sian-Rotam\' (No Repeat) (Normal Dungeon)'),
(10737,0,4,0,61,0,100,0,0,0,0,0,0,0,
 45,13690,1,0,0,0,0,1,0,0,0,0,
 0,0,0,0,'Shy-Rotam - On Link - Remember Sian-Rotam Summon');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 4
  AND `SourceEntry` = 10737 AND `SourceId` = 0 AND `ConditionTypeOrReference` = 104
  AND `ConditionTarget` = 1 AND `ConditionValue1` = 13690;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,
 `ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,
 `ErrorTextId`,`ScriptName`,`Comment`) VALUES
(22,4,10737,0,0,104,1,13690,0,0,0,0,0,'','Shy-Rotam - Summon Sian-Rotam once per life');
