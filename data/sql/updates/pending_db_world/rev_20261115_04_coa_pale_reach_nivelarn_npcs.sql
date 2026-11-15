-- Gorlin (9962259): rev_20261108_9941 sat him on the floor with an UPDATE, but he had no creature_addon row, so he
-- kept standing.
DELETE FROM `creature_addon` WHERE `guid` = 9962259;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(9962259, 0, 0, 1, 1, 0, 0, '');

-- Tholgrim Copperweigh, Nivelarn's last open merchant (npc_text 1200361 "take a look"), trades in front of his
-- cart instead of inside the hovel. The realm stock is unknown; he sells common trade goods.
UPDATE `creature` SET `position_x` = -6417.77, `position_y` = 77.4868, `position_z` = 519.039, `orientation` = 2.3878,
    `Comment` = 'Tholgrim Copperweigh, Nivelarn: in front of his cart' WHERE `guid` = 9985021 AND `id` = 164387;
UPDATE `creature_template` SET `npcflag` = 129 WHERE `entry` = 164387;

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 1200361;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(1200361, 0, 1, 'I want to browse your goods.', 3370, 3, 128, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `npc_vendor` WHERE `entry` = 164387;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(164387, 0, 2320, 0, 0, 0, 0),
(164387, 0, 2321, 0, 0, 0, 0),
(164387, 0, 2324, 0, 0, 0, 0),
(164387, 0, 2678, 0, 0, 0, 0),
(164387, 0, 2880, 0, 0, 0, 0),
(164387, 0, 2901, 0, 0, 0, 0),
(164387, 0, 3371, 0, 0, 0, 0),
(164387, 0, 3372, 0, 0, 0, 0),
(164387, 0, 3466, 0, 0, 0, 0),
(164387, 0, 3857, 0, 0, 0, 0),
(164387, 0, 4289, 0, 0, 0, 0),
(164387, 0, 4291, 0, 0, 0, 0),
(164387, 0, 4399, 0, 0, 0, 0),
(164387, 0, 4400, 0, 0, 0, 0),
(164387, 0, 5956, 0, 0, 0, 0),
(164387, 0, 6217, 0, 0, 0, 0),
(164387, 0, 6530, 0, 0, 0, 0),
(164387, 0, 6532, 0, 0, 0, 0),
(164387, 0, 39354, 0, 0, 0, 0),
(164387, 1, 2692, 0, 0, 0, 0),
(164387, 2, 3713, 0, 0, 0, 0);

-- Nivelarn mailbox in the Kharanos style (142102), placed by the user.
DELETE FROM `gameobject` WHERE `guid` = 9999570;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9999570, 142102, 0, 0, 0, 1, 1, -6433.068, 70.999, 520.139, 1.505115, 0, 0, 0.683518, 0.729934, 300, 0, 1, 'Pale Reach: Nivelarn mailbox');
