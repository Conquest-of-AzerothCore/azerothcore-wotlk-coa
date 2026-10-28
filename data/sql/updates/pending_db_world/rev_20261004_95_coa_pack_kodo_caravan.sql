-- The Pack Kodo Caravan Cart (50470, Mulgore and Durotar) rolled without a kodo: its model HordeCaravanVehicle.m2
-- holds the wagon and its harness only (its textures are the wagon's, none a kodo's), so the kodos that
-- rev_20260924_50 took to be part of the model were never there and the Caravan Harness filled the empty draft seat.
-- A Pack Kodo now pulls each cart from draft seat 2, as the horses, rams, sabers and skeletal horses pull the other
-- carts: the Pack Kodo display 7933 that walks with the Gizelton caravan, the cart's Orgrimmar faction, and CoA's
-- RUN aura 992478 that npc_coa_caravan_cart lifts at each stop. The kodo is INFERRED; no source records the beast.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `exp`, `faction`,
    `npcflag`, `speed_walk`, `speed_run`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`,
    `unit_flags2`, `type`, `type_flags`, `VehicleId`, `AIName`, `MovementType`, `HealthModifier`, `ManaModifier`,
    `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
(9303001, 'Pack Kodo', NULL, NULL, 1, 1, 0, 29, 0, 1, 1.14286, 2000, 2000, 1, 768, 2048, 1, 0, 0, '', 0, 1, 1, 1, 1,
    8194, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_flags` = VALUES(`unit_flags`),
    `type` = VALUES(`type`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 9303001;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(9303001, 0, 7933, 1, 1);

DELETE FROM `creature_template_addon` WHERE `entry` = 9303001;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
    `auras`) VALUES
(9303001, 0, 0, 0, 0, 0, 3, '992478');

DELETE FROM `vehicle_accessory` WHERE `guid` IN (9006004, 9006005) AND `seat_id` = 2;
INSERT INTO `vehicle_accessory` (`guid`, `accessory_entry`, `seat_id`, `minion`, `description`, `summontype`,
    `summontimer`) VALUES
(9006004, 9303001, 2, 1, 'Pack Kodo', 8, 0),
(9006005, 9303001, 2, 1, 'Pack Kodo', 8, 0);
