-- D.R.I.V.E Karts (mount spells 908072-908076 -> creatures 110517-110521) carry
-- their two backseat merchants: Backseat Beauty (bank) and Backseat Babe
-- (vendor and repair).
--
-- Creature ids, names and type are the live creature-cache records of
-- 110522/110523. The cache lists display 11686 (InvisibleStalker), but live
-- video shows both riding visibly as unequipped blood elf women, so they use
-- the gear-less blood elf female displays 20370/20371; their roles are also
-- taken from that video.
-- The vehicle is a two-passenger copy of the Traveler's Tundra Mammoth
-- vehicle. Its ids lie inside the client tables' id ranges: the client's index
-- insert drops the old highest row whenever a new id lies past the top, so
-- ids above Vehicle 8225 / VehicleSeat 10000 lost a stock row and, on the
-- client's first login, the first new seat. VehicleSeat attachment ids are the model's attachment ids minus 26
-- (the mammoth's seats 13/14 are its points 39/40), so the seats use 14/15 =
-- the kart's passenger points 40/41, with offsets tuned in game for the blood
-- elf models. A seat whose point the model lacks falls back to the model
-- origin: passengers ignore the kart's animation and swing out of it on turns.
-- AscensionCompat streams vehicle_dbc and vehicleseat_dbc rows to clients at
-- login (SMSG_PATCH_VEHICLE / SMSG_PATCH_VEHICLE_SEAT).

DELETE FROM `vehicle_dbc` WHERE `ID` = 8223;
INSERT INTO `vehicle_dbc` VALUES
(8223, 1073741824, 3.142, 3.142, 0, 0, 0, 9996, 9997, 0, 0, 0, 0, 0, 0, 1, 1.5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', 0, 0, 0, 225, 0, 0, 0);

DELETE FROM `vehicleseat_dbc` WHERE `ID` IN (9996, 9997);
INSERT INTO `vehicleseat_dbc` VALUES
(9996, -570392565, 14, 0.29, 0, -0.33, 0, 10, 19.29, 0.6, 1, 1.5, 4, 37, 38, -1, 102, -1, -1, 0, 10, 19.29, 0.6, 2, 1.5, 2, 37, 38, 39, 0, 0, 0, -1, -1, -1, -1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1073741872, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(9997, -570392565, 15, 0.23, 0, -0.33, 0, 10, 19.29, 0.6, 1, 1.5, 4, 37, 38, -1, 102, -1, -1, 0, 10, 19.29, 0.6, 2, 1.5, 2, 37, 38, 39, 0, 0, 0, -1, -1, -1, -1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1073741872, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

UPDATE `creature_template` SET `VehicleId` = 8223 WHERE `entry` BETWEEN 110517 AND 110521;

-- Passengers: friendly to everyone (faction 35), civilian, immune like the
-- mammoth merchants. Banker (131072); vendor (128) + repair (4096).
INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `flags_extra`, `VerifiedBuild`) VALUES
(110522, 'Backseat Beauty', 80, 80, 2, 35, 131072, 1, 33536, 2048, 7, 2, 0),
(110523, 'Backseat Babe',   80, 80, 2, 35,   4224, 1, 33536, 2048, 7, 2, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
    `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `unit_class` = VALUES(`unit_class`),
    `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`),
    `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (110522, 110523);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(110522, 0, 20370, 1, 1, 0),
(110523, 0, 20371, 1, 1, 0);

-- Seat index 0 is the rider. minion = 1: the core unsummons them 2 s after they
-- step out. (Not minion, they do not stay attached to the kart on the client.)
DELETE FROM `vehicle_template_accessory` WHERE `entry` BETWEEN 110517 AND 110521 AND `seat_id` IN (1, 2);
INSERT INTO `vehicle_template_accessory` (`entry`, `accessory_entry`, `seat_id`, `minion`, `description`, `summontype`, `summontimer`) VALUES
(110517, 110522, 1, 1, 'PUR-PL3 D.R.I.V.E Kart - Backseat Beauty (bank)', 6, 30000),
(110517, 110523, 2, 1, 'PUR-PL3 D.R.I.V.E Kart - Backseat Babe (vendor, repair)', 6, 30000),
(110518, 110522, 1, 1, '0CN-DRFT D.R.I.V.E Kart - Backseat Beauty (bank)', 6, 30000),
(110518, 110523, 2, 1, '0CN-DRFT D.R.I.V.E Kart - Backseat Babe (vendor, repair)', 6, 30000),
(110519, 110522, 1, 1, 'GR-33N D.R.I.V.E Kart - Backseat Beauty (bank)', 6, 30000),
(110519, 110523, 2, 1, 'GR-33N D.R.I.V.E Kart - Backseat Babe (vendor, repair)', 6, 30000),
(110520, 110522, 1, 1, 'SC-4RL3T D.R.I.V.E Kart - Backseat Beauty (bank)', 6, 30000),
(110520, 110523, 2, 1, 'SC-4RL3T D.R.I.V.E Kart - Backseat Babe (vendor, repair)', 6, 30000),
(110521, 110522, 1, 1, 'G-0LD D.R.I.V.E Kart - Backseat Beauty (bank)', 6, 30000),
(110521, 110523, 2, 1, 'G-0LD D.R.I.V.E Kart - Backseat Babe (vendor, repair)', 6, 30000);

-- On dismount each passenger steps out beside her own seat instead of onto the
-- rider's spot (offsets are relative to the kart: x forward, y left).
DELETE FROM `vehicle_seat_addon` WHERE `SeatEntry` IN (9996, 9997);
INSERT INTO `vehicle_seat_addon` (`SeatEntry`, `SeatOrientation`, `ExitParamX`, `ExitParamY`, `ExitParamZ`, `ExitParamO`, `ExitParamValue`) VALUES
(9996, 0, -1.76, -2, 0, 0, 1),
(9997, 0, -1.76,  2, 0, 0, 1);

-- The passengers board with the generic Ride Vehicle Hardcoded click spell.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` BETWEEN 110517 AND 110521 AND `spell_id` = 46598;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(110517, 46598, 1, 0),
(110518, 46598, 1, 0),
(110519, 46598, 1, 0),
(110520, 46598, 1, 0),
(110521, 46598, 1, 0);

-- Backseat Babe sells what the mammoth vendor-and-repairer (Gnimo) sells.
DELETE FROM `npc_vendor` WHERE `entry` = 110523;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
SELECT 110523, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, 0 FROM `npc_vendor` WHERE `entry` = 32639;
