-- Pale Reach fixes on top of #7047, from the user's in-game work (PR #7948 values the port did not carry over).

-- The House of Nobles (175001): the council scene as captured in game - Lord Servin Darengar is answered by Lord Broldin
-- Feandor and Lady Asia Mortel, every line voiced (client sounds 215200-215206, sound\scadeald\Scadeald1-7.wav), with the
-- captured pauses. The scene still ends with this branch's credit for "Listen to the nobles' meeting" (164500).
DELETE FROM `creature_text` WHERE (`CreatureID` = 164001 AND `GroupID` IN (0, 1, 2)) OR (`CreatureID` = 164211 AND `GroupID` IN (0, 1, 2)) OR (`CreatureID` = 164212 AND `GroupID` = 0) OR `CreatureID` IN (164217, 164218);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(164001,0,0,'I believe I have made my stance clear. Trolls, bandits, Ealdir... what more must happen before we resolve to intervene?',12,0,100,0,0,215200,0,0,'Lord Servin Darengar - House of Nobles'),
(164001,1,0,'If we do nothing, there will be nothing left to rule! Tell me, do we only help the drowning if they still have the voice to beg?',12,0,100,0,0,215204,0,0,'Lord Servin Darengar - House of Nobles'),
(164001,2,0,'Lady Serenya\'s pride will be our undoing. We must--!',12,0,100,0,0,215205,0,0,'Lord Servin Darengar - House of Nobles'),
(164217,0,0,'And we, I believe, have made ours clear, Lord Darengar.',12,0,100,0,0,215201,0,0,'Lord Broldin Feandor - House of Nobles'),
(164217,1,0,'Even if there were unanimity, this council cannot simply march the army into Scadeald without the consent of House Coldmere.',12,0,100,0,0,215202,0,0,'Lord Broldin Feandor - House of Nobles'),
(164217,2,0,'You are wasting your time barking up the wrong tree, Lord Darengar. Our laws exist for a reason. This session is adjourned.',12,0,100,0,0,215206,0,0,'Lord Broldin Feandor - House of Nobles'),
(164218,0,0,'And do remember that it is the Coldmeres, and not yourself, who rule Scadeald.',12,0,100,0,0,215203,0,0,'Lady Asia Mortel - House of Nobles');
DELETE FROM `smart_scripts` WHERE `entryorguid` = 16400100 AND `source_type` = 9;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(16400100,9,0,0,0,0,100,0,2000,2000,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'House of Nobles scene - Lord Servin Darengar line 0'),
(16400100,9,1,0,0,0,100,0,10000,10000,0,0,0,0,1,0,0,0,0,0,0,19,164217,30,0,0,0,0,0,0,'House of Nobles scene - Lord Broldin Feandor line 0'),
(16400100,9,2,0,0,0,100,0,7000,7000,0,0,0,0,1,1,0,0,0,0,0,19,164217,30,0,0,0,0,0,0,'House of Nobles scene - Lord Broldin Feandor line 1'),
(16400100,9,3,0,0,0,100,0,10000,10000,0,0,0,0,1,0,0,0,0,0,0,19,164218,30,0,0,0,0,0,0,'House of Nobles scene - Lady Asia Mortel line 0'),
(16400100,9,4,0,0,0,100,0,9000,9000,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'House of Nobles scene - Lord Servin Darengar line 1'),
(16400100,9,5,0,0,0,100,0,10000,10000,0,0,0,0,1,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'House of Nobles scene - Lord Servin Darengar line 2'),
(16400100,9,6,0,0,0,100,0,6000,6000,0,0,0,0,1,2,0,0,0,0,0,19,164217,30,0,0,0,0,0,0,'House of Nobles scene - Lord Broldin Feandor line 2'),
(16400100,9,7,0,0,0,100,0,12000,12000,0,0,0,0,33,164500,0,0,0,0,0,18,40,0,0,0,0,0,0,0,'Lord Servin Darengar - Council - Listen to the nobles\' meeting credit');

-- Kharadol Supplies (175058): the guns the user laid out on Kharadol Bridge replace the nine standing Kharadol Blunderbuss
-- pickups - four fallen blunderbusses (Fallen Blunderbuss model) and a rifle on the upper floor (Waterlogged Rifle model),
-- each giving one Kharadol Blunderbuss while on the quest and back after two minutes.
UPDATE `gameobject_template` SET `displayId` = 515473, `size` = 1 WHERE `entry` = 2300665;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data3`, `Data8`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300807, 3, 515034, 'Kharadol Blunderbuss', '', '', '', 1, 57, 2300665, 1, 175058, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data3` = VALUES(`Data3`), `Data8` = VALUES(`Data8`);
DELETE FROM `gameobject` WHERE `id` = 2300665 AND `guid` IN (9983039, 9983040, 9983041, 9983042, 9983043, 9983086, 9983087, 9983088, 9983089);
DELETE FROM `gameobject` WHERE `guid` IN (9963470, 9963482, 9963483, 9963484, 9963485);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9963482, 2300665, 0, 0, 0, 1, 1, -7008.5135, 265.5827, 353.459, 1.6568, -0.516454, 0.473843, -0.52557, -0.482207, 120, 0, 1, '', 0, 'Kharadol Blunderbuss: lower floor, fallen by the north gun rack'),
(9963483, 2300665, 0, 0, 0, 1, 1, -7011.0435, 264.8063, 353.559, 2.0299, -0.595377, 0.369835, -0.605886, -0.376363, 120, 0, 1, '', 0, 'Kharadol Blunderbuss: lower floor, fallen under the gun rack'),
(9963484, 2300665, 0, 0, 0, 1, 1, -7010.4399, 265.0189, 353.559, 2.1281, -0.612811, 0.340168, -0.623628, -0.346173, 120, 0, 1, '', 0, 'Kharadol Blunderbuss: lower floor, fallen under the gun rack'),
(9963485, 2300665, 0, 0, 0, 1, 1, -7015.2884, 263.8356, 353.459, 1.9475, -0.579639, 0.394044, -0.58987, -0.401, 120, 0, 1, '', 0, 'Kharadol Blunderbuss: lower floor, fallen by the west gun rack'),
(9963470, 2300807, 0, 0, 0, 1, 1, -7020.3621, 248.5521, 360.504, 5.1684, -0.374043, -0.600078, -0.374041, 0.600076, 120, 0, 1, '', 0, 'Kharadol Blunderbuss: upper floor, rifle on the south side');
