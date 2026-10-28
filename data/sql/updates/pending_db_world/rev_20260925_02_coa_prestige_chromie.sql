-- mod-coa-prestige: Chromie (178081), the Prestige Mode NPC, and her two shops.
--
-- The client already knows her: Creature.dbc row 178081 is "Chromie" with display 10008, and
-- AscensionUI/Gossips/PrestigeMode.lua replaces her gossip window with the Prestige window. The
-- world database had no row for her. The template follows the Andorhal Chromie (10667), who
-- wears the same model; her gossip comes from the module script npc_coa_prestige_chromie.
INSERT INTO `creature_template`
  (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
   `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `AIName`,
   `MovementType`, `HealthModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES
  (178081, 'Chromie', 'Prestige', 0, 63, 63, 35, 131, 1, 1.14286, 1, 33536, 2048, 2, '', 0, 1.35, 1, 2,
   'npc_coa_prestige_chromie'),
  (990782, 'Chromie - Experience Items', NULL, 0, 1, 1, 35, 128, 1, 1.14286, 1, 0, 0, 7, '', 0, 1, 1, 0, '')
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `subname` = VALUES(`subname`), `gossip_menu_id` = VALUES(`gossip_menu_id`),
  `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`),
  `npcflag` = VALUES(`npcflag`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`),
  `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`),
  `unit_flags2` = VALUES(`unit_flags2`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`),
  `MovementType` = VALUES(`MovementType`), `HealthModifier` = VALUES(`HealthModifier`),
  `RegenHealth` = VALUES(`RegenHealth`), `flags_extra` = VALUES(`flags_extra`),
  `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (178081, 990782);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(178081, 0, 10008, 1, 1),
(990782, 0, 10008, 1, 1);

-- Where she stood is NOT recovered. The client's tutorials place her "by the Call Board in your
-- Capital City", and no call board survives as a spawn. These two are chosen beside the
-- Worldforged guardian, who is placed by the call boards for the same reason
-- (modules/mod-worldforged-upgrades): a few yards from him on the same street, with the height
-- taken from the NPCs standing around them. Should the call boards turn up, move her with
-- `.npc move` and rewrite these rows. The guid is left to AUTO_INCREMENT; the DELETE
-- by id clears any earlier rows, so re-applying the file never collides.
DELETE FROM `creature` WHERE `id` = 178081;
INSERT INTO `creature`
  (`id`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`,
   `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`,
   `MovementType`)
VALUES
(178081, 0, 1, 1, 0, -8820.67, 625.782, 94.0, 3.78035, 300, 0, 0, 0, 0, 0),
(178081, 1, 1, 1, 0, 1581.6, -4418.4, 8.2, 3.38266, 300, 0, 0, 0, 0, 0);

-- "I would like to purchase Prestige items!": the 104 Prestige offers. Every price is an
-- ItemExtendedCost row of the client's own ItemExtendedCost.dbc, paid in Tokens of Prestige
-- (90004), and every item exists in item_template.
DELETE FROM `npc_vendor` WHERE `entry` IN (178081, 990782);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
(178081, 0, 97279, 0, 0, 20001),
(178081, 1, 97280, 0, 0, 20002),
(178081, 2, 97281, 0, 0, 20001),
(178081, 3, 97282, 0, 0, 20002),
(178081, 4, 97283, 0, 0, 20001),
(178081, 5, 97295, 0, 0, 20002),
(178081, 6, 97296, 0, 0, 20002),
(178081, 7, 97297, 0, 0, 20002),
(178081, 8, 97299, 0, 0, 20009),
(178081, 9, 1777039, 0, 0, 20055),
(178081, 10, 1518202, 0, 0, 20037),
(178081, 11, 1518203, 0, 0, 20037),
(178081, 12, 1642896, 0, 0, 20037),
(178081, 13, 1642897, 0, 0, 20037),
(178081, 14, 1642898, 0, 0, 20037),
(178081, 15, 1642899, 0, 0, 20037),
(178081, 16, 1642900, 0, 0, 20037),
(178081, 17, 1642901, 0, 0, 20037),
(178081, 18, 1642902, 0, 0, 20037),
(178081, 19, 1642944, 0, 0, 20037),
(178081, 20, 1642945, 0, 0, 20037),
(178081, 21, 1642948, 0, 0, 20037),
(178081, 22, 1644091, 0, 0, 20037),
(178081, 23, 1644094, 0, 0, 20037),
(178081, 24, 1644096, 0, 0, 20037),
(178081, 25, 1648716, 0, 0, 20037),
(178081, 26, 3140350, 0, 0, 20037),
(178081, 27, 3148335, 0, 0, 20037),
(178081, 28, 1642846, 0, 0, 20001),
(178081, 29, 1642943, 0, 0, 20001),
(178081, 30, 1642947, 0, 0, 20001),
(178081, 31, 1642999, 0, 0, 20001),
(178081, 32, 1644093, 0, 0, 20001),
(178081, 33, 1648718, 0, 0, 20001),
(178081, 34, 3142943, 0, 0, 20001),
(178081, 35, 1642991, 0, 0, 20039),
(178081, 36, 1644097, 0, 0, 20039),
(178081, 37, 1644098, 0, 0, 20039),
(178081, 38, 1642949, 0, 0, 20038),
(178081, 39, 1642950, 0, 0, 20038),
(178081, 40, 1642952, 0, 0, 20038),
(178081, 41, 1642984, 0, 0, 20038),
(178081, 42, 1642985, 0, 0, 20038),
(178081, 43, 1644099, 0, 0, 20038),
(178081, 44, 1644100, 0, 0, 20038),
(178081, 45, 1644101, 0, 0, 20038),
(178081, 46, 1644102, 0, 0, 20038),
(178081, 47, 1644103, 0, 0, 20038),
(178081, 48, 1644105, 0, 0, 20038),
(178081, 49, 1644107, 0, 0, 20038),
(178081, 50, 3142949, 0, 0, 20038),
(178081, 51, 1648677, 0, 0, 20040),
(178081, 52, 1648685, 0, 0, 20040),
(178081, 53, 1648687, 0, 0, 20040),
(178081, 54, 1648689, 0, 0, 20040),
(178081, 55, 1648691, 0, 0, 20040),
(178081, 56, 3148685, 0, 0, 20040),
(178081, 57, 1339120, 0, 0, 44846),
(178081, 58, 1339121, 0, 0, 44846),
(178081, 59, 1339122, 0, 0, 44846),
(178081, 60, 1339124, 0, 0, 44846),
(178081, 61, 1339125, 0, 0, 44846),
(178081, 62, 1339126, 0, 0, 44846),
(178081, 63, 1339076, 0, 0, 44845),
(178081, 64, 1339078, 0, 0, 44845),
(178081, 65, 1339092, 0, 0, 44846),
(178081, 66, 1339093, 0, 0, 44846),
(178081, 67, 1339094, 0, 0, 44846),
(178081, 68, 1339096, 0, 0, 44846),
(178081, 69, 1339097, 0, 0, 44846),
(178081, 70, 1339098, 0, 0, 44846),
(178081, 71, 1339113, 0, 0, 20037),
(178081, 72, 1339114, 0, 0, 20037),
(178081, 73, 1339115, 0, 0, 20037),
(178081, 74, 1339117, 0, 0, 20037),
(178081, 75, 1339118, 0, 0, 20037),
(178081, 76, 1339119, 0, 0, 20037),
(178081, 77, 1339099, 0, 0, 44846),
(178081, 78, 1339100, 0, 0, 44846),
(178081, 79, 1339101, 0, 0, 44846),
(178081, 80, 1339103, 0, 0, 44846),
(178081, 81, 1339104, 0, 0, 44846),
(178081, 82, 1339105, 0, 0, 44846),
(178081, 83, 1339106, 0, 0, 44846),
(178081, 84, 1339107, 0, 0, 44846),
(178081, 85, 1339108, 0, 0, 44846),
(178081, 86, 1339110, 0, 0, 44846),
(178081, 87, 1339111, 0, 0, 44846),
(178081, 88, 1339112, 0, 0, 44846),
(178081, 89, 1339127, 0, 0, 44845),
(178081, 90, 1339128, 0, 0, 44845),
(178081, 91, 1339129, 0, 0, 44845),
(178081, 92, 1339131, 0, 0, 44845),
(178081, 93, 1339132, 0, 0, 44845),
(178081, 94, 1339133, 0, 0, 44845),
(178081, 95, 1339079, 0, 0, 44845),
(178081, 96, 1339081, 0, 0, 44845),
(178081, 97, 1339082, 0, 0, 44845),
(178081, 98, 1339084, 0, 0, 44846),
(178081, 99, 1339085, 0, 0, 44846),
(178081, 100, 1339086, 0, 0, 44846),
(178081, 101, 1339087, 0, 0, 44846),
(178081, 102, 1339088, 0, 0, 44846),
(178081, 103, 1339089, 0, 0, 44846),
-- "Experience Items": Potion of Experience and Aura of Experience, paid in Bazaar Tokens (975001).
(990782, 0, 818046, 0, 0, 41021),
(990782, 1, 818059, 0, 0, 2990);
