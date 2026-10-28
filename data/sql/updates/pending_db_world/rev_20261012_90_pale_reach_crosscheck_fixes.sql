-- Pale Reach fixes from the palereach_todo.txt crosscheck of 2026-10-12; untested in game.
-- Sources: core code, the installed client and two archives approved for this change:
-- the SUB client caches (WDB build 12340, captured 2026-09-05; db.exil.es dump 2026-10-04)
-- and the live harvest (Descension c485e601, captured 2026-08-30).

-- Equipment: these spawns use equipment_id 0, so they ignore their creature_equip_template
-- row ID 1 and appear unarmed (Road Bandit/Marauder, Graysky, Dun Kazad, Stormwind and
-- Shadowburn NPCs, Marcelin Pastore, Captain Kildar).
UPDATE `creature` SET `equipment_id` = 1
WHERE `id` IN (
    164020, 164021, 164027, 164242, 164376, 164403,
    164427, 164428, 164469, 164476, 164479, 164489
) AND `equipment_id` = 0;

-- Todo #13: remove the purple glow (28126 Spirit Particles (purple)) from the road bandits.
UPDATE `creature_template_addon` SET `auras` = NULL WHERE `entry` IN (164020, 164021);
UPDATE `creature_addon` SET `auras` = ''
WHERE `guid` IN (9920316, 9920324, 9920328, 9920329, 9920343, 9920344, 9920345)
  AND `auras` = '28126';

-- Todo #79: the trapdoor and ladder teleported on the click (GOSSIP_HELLO filter 0).
-- Filter 2 (reportUse) runs the teleport when the use cast completes.
DELETE FROM `smart_scripts` WHERE `source_type` = 1 AND `entryorguid` IN (2310423, 2310427);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2310423, 1, 0, 0, 64, 0, 100, 0, 2, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -7213.14, 910.491, 241.637, 4.84847, 'Trapdoor - On Use Cast Complete - Teleport into the passage below Graysky'),
(2310427, 1, 0, 0, 64, 0, 100, 0, 2, 0, 0, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -7171.71, 959.261, 289.805, 1.9668, 'Ladder - On Use Cast Complete - Teleport back up to the trapdoor');

-- Todo #17: Skymaw's respawn emote was sent to the whole zone (TextRange 2).
UPDATE `creature_text` SET `TextRange` = 0 WHERE `CreatureID` = 164161 AND `GroupID` = 0 AND `ID` = 0;

-- Todo #45: Graysky Guard Horse used faction 7 (attackable); match Graysky Horse 164369.
UPDATE `creature_template` SET `faction` = 35 WHERE `entry` = 164368;

-- Gameobject templates from the client caches (WDB, Rexxar and Bronzebeard, build 12340).
-- 2300658 and 2300696 are not in any cache; they come from the SUB gameobject table.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300625, 10, 300491, 'Rune FX 01', 'interact', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300626, 10, 300492, 'Rune FX 02', 'interact', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300627, 10, 300493, 'Rune FX 03', 'interact', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300628, 10, 300494, 'Rune FX 04', 'interact', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300653, 0, 300553, 'Stomwind Keep Door', 'questinteract', '', '', 1, 0, 0, 5000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300658, 5, 1018856, 'Tomb', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300671, 1, 295, 'Lever', '', '', '', 0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300696, 10, 300451, 'Rope', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300719, 10, 300547, 'Boat', 'questinteract', '', '', 1, 57, 175214, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300720, 10, 300548, 'Campfire remains', 'questinteract', '', '', 1, 57, 175217, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300724, 31, 8196, 'Doodad_InstanceNewPortal_Purple01', '', '', '', 2, 940, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300725, 31, 8197, 'Doodad_InstanceNewPortal_Purple_Skull01', '', '', '', 2, 940, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300726, 31, 9040, 'Doodad_InstancePortal_Green_5Man_Mythic01', '', '', '', 1.75, 940, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300727, 31, 8196, 'Doodad_InstanceNewPortal_Purple01', '', '', '', 2, 941, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300728, 31, 8197, 'Doodad_InstanceNewPortal_Purple_Skull01', '', '', '', 2, 941, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2300729, 31, 9040, 'Doodad_InstancePortal_Green_5Man_Mythic01', '', '', '', 1.75, 941, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2310417, 5, 1020938, 'Portal to Temple of Anzuldin', '', '', '', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2310434, 5, 300557, 'Wilted Flowers', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2310436, 0, 300559, '[PH] Puente mazmorra enana', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2310444, 0, 300568, 'templeofembers 1st boss barrier', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2310445, 0, 300569, 'templeofembers 1st boss door', '', '', '', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(2310461, 5, 300553, 'SWS door', '', '', '', 1.05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`);

-- Live positions: only single-sighting, stationary harvest rows are used. Multi-sighting
-- rows (council nobles, North Gate citizens) are centroids of far-apart sightings and stay.
UPDATE `creature` SET `position_x` = -7620.09, `position_y` = 1197.55, `position_z` = 160.091, `orientation` = 3.4932 WHERE `guid` = 9920637; -- Dornes
UPDATE `creature` SET `position_x` = -7783.97, `position_y` = 790.605, `position_z` = 150.656, `orientation` = 3.0752 WHERE `guid` = 9920337; -- Captain Hedgar
UPDATE `creature` SET `orientation` = 2.6077 WHERE `guid` = 9920636; -- Holga (todo #76)
UPDATE `creature` SET `orientation` = 0.0969 WHERE `guid` = 9920617; -- Guard Grimsbane
UPDATE `creature` SET `orientation` = 3.0231 WHERE `guid` = 9920212; -- Guard Thair Spada
UPDATE `creature` SET `orientation` = 5.4258 WHERE `guid` = 9920616; -- Shopkeeper Mercel
UPDATE `creature` SET `orientation` = 6.0704 WHERE `guid` = 9920439; -- Miller Bartren
UPDATE `creature` SET `orientation` = 4.3927 WHERE `guid` = 9920100; -- Little Mickey
