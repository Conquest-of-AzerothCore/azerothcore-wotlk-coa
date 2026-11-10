-- The four Injured Andraste Soldiers (164153) captured on the top bunks of Andraste's Fortress stood on the mattress
-- (#10558, #10332). They lie down (stand state 3); the two facing across their bunk turn to its long axis, the yaw of
-- the Bunkbed01 under them. The floor soldiers keep standing.
UPDATE `creature` SET `orientation` = 3.778 WHERE `guid` = 9960724 AND `id` = 164153;
UPDATE `creature` SET `orientation` = 3.836 WHERE `guid` = 9961877 AND `id` = 164153;
DELETE FROM `creature_addon` WHERE `guid` IN (9960724, 9960725, 9961877, 9961880);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
`auras`) VALUES
(9960724, 0, 0, 3, 1, 0, 0, NULL),
(9960725, 0, 0, 3, 1, 0, 0, NULL),
(9961877, 0, 0, 3, 1, 0, 0, NULL),
(9961880, 0, 0, 3, 1, 0, 0, NULL);

-- A Family Cultist (164312) in the Chambers of Erdaya spawned under the cave's south rock overhang, hidden but
-- targetable (#10090). It spawns on open floor at a live sighting of the same spawn (38233).
UPDATE `creature` SET `position_x` = -7847.152, `position_y` = 168.689, `position_z` = 86.908
WHERE `guid` = 9960979 AND `id` = 164312;

-- Deirdre (164355) carries her staff on her back on the realm (Wo-WScrn-Shot-071226-082127); with no addon row she
-- held it drawn.
DELETE FROM `creature_addon` WHERE `guid` = 9960010;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9960010, 0, 0, 0, 0, 0, 0, '');

-- Injured Andraste Soldiers (164153, 164263) stand at a sliver of health until Heal Injured (257543) lands, as on the
-- live realm (video hxdp8nA91RA 02:38:56-02:39:30); a minute after being healed they are hurt again.
UPDATE `creature_template` SET `RegenHealth` = 0 WHERE `entry` IN (164153, 164263);
UPDATE `creature` SET `curhealth` = 70 WHERE `id` IN (164153, 164263);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164153, 164263) AND `source_type` = 0 AND `id` IN (0, 1, 2, 3);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164153, 0, 0, 1, 8, 0, 100, 0, 257543, 0, 60000, 60000, 0, 0, 33, 164263, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - On Heal Injured hit - Quest Credit'),
(164153, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - Linked - Hurt Again In 60 s'),
(164153, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - On Timed Event - Set Health 10%'),
(164153, 0, 3, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - On Respawn - Set Health 10%'),
(164263, 0, 0, 1, 8, 0, 100, 0, 257543, 0, 60000, 60000, 0, 0, 33, 164263, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - On Heal Injured hit - Quest Credit'),
(164263, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - Linked - Hurt Again In 60 s'),
(164263, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - On Timed Event - Set Health 10%'),
(164263, 0, 3, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 142, 10, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Injured Andraste Soldier - On Respawn - Set Health 10%');

-- Andraste Guards (164163, 164164) wear the Stormwind guard model and carry its sword and shield, as the Andraste
-- Recruits do.
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (164163, 164164) AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164163, 1, 1899, 143, 0, 0),
(164164, 1, 1899, 143, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` IN (164163, 164164);
