-- Destiny Weaver: the mirror-image presets, and the six creatures that were missing.
--
-- The live realm did not draw these NPCs from `modelid1`.  Every Weaver carries
-- type_flags 134217728 and, in the client's own creature cache, the matching render flag:
-- Ascension renders custom NPCs as *mirror images*, so the whole look - race, gender, skin,
-- face, hair, haircolour, facial hair and eleven equipped item displays - is sent by the
-- server when the client asks for it (CMSG_GET_MIRRORIMAGE_DATA).  That data lived only in
-- packet logs; the client, DB, datamine and archive carry none of it.
--
-- The mechanism is already in the tree: `AscensionCreaturePresetMgr` (PR #3983) answers
-- that request from `creature_display_preset`, keyed by (entry, display_id), and flags any
-- creature with a row.  This revision fills it.  The looks are sourced from real dressed
-- character displays of the same race and gender, so none of them is hand-drawn.
--
-- Recovered from the captures (season-10-freepick, season-9): every name, the subname, the
-- Speak icon, type_flags 134217728, HealthModifier 1.64062, movementId 999, and one display
-- id per pair - 449292 troll, 449293 dwarf, 449294 undead, 449295 draenei, 449296 night elf,
-- 449297 blood elf, 449298 orc, 449299 human.  Ten of the sixteen were already placed.
--
-- Inferred, and the one thing here that is: the race each of the last three pairs belongs
-- to.  The client ships CoA character art for exactly six races - dwarf, night elf, draenei,
-- orc, undead, troll (CreatureDisplayInfoExtra 466900-466911) - and the two pairs whose art
-- has no such source are human and blood elf, so the three pairs left over are the three
-- remaining CoA races, which also balances the factions four and four.  Changing a pair's
-- race is one UPDATE of `race`/`gender` plus the item columns.
--
-- The descriptions of 449294, 449295 and 449298 are added to CreatureDisplayInfo.dbc and
-- CreatureDisplayInfoExtra.dbc the way CoA authors its own: a self-referencing extra row
-- carrying that race's character art.  Both files ship in patch-B, patch-M and COA/Data/dbc.

-- ---------------------------------------------------------------------------
-- 1. The six creatures that were never placed
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_template` (`entry`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `flags_extra`, `ScriptName`, `VerifiedBuild`) VALUES
(449343, 'Veylae', 'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449344, 'Saltheris Dawnborn', 'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449346, 'Waerun Cliffwalker', 'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449353, 'Veylin', 'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449354, 'Salthoril Dawnspire', 'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340),
(449356, 'Waeric Cliffstrider', 'Destiny Weaver', 'Speak', 0, 40, 40, 35, 1, 1, 1.14286, 20, 0, 0, 1, 2000, 2000, 1, 768, 2048, 0, 0, 7, 134217728, '', 0, 1, 1.64062, 1, 1, 1, 0, 999, 1, 2, 'npc_destiny_weaver', 12340);

-- ---------------------------------------------------------------------------
-- 2. Their models: the three display ids the captures name for these pairs
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(449343, 0, 449294, 1, 1, NULL) /* Veylae, undead */,
(449353, 0, 449294, 1, 1, NULL) /* Veylin, undead */,
(449344, 0, 449295, 1, 1, NULL) /* Saltheris Dawnborn, draenei */,
(449354, 0, 449295, 1, 1, NULL) /* Salthoril Dawnspire, draenei */,
(449346, 0, 449298, 1, 1, NULL) /* Waerun Cliffwalker, orc */,
(449356, 0, 449298, 1, 1, NULL) /* Waeric Cliffstrider, orc */;

-- ---------------------------------------------------------------------------
-- 3. Model info for those three displays - the core refuses a display without a row
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(449294, 0.347, 1.5, 0, 0),
(449295, 0.347, 1.5, 0, 0),
(449298, 0.347, 1.5, 0, 0);

-- ---------------------------------------------------------------------------
-- 4. Their spawns: beside the innkeeper of each race's capital and starting village
-- ---------------------------------------------------------------------------
DELETE FROM `creature` WHERE `guid` BETWEEN 9000021 AND 9000026;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9000021, 449343, 0, 0, 0, 1, 1, 0, 1638.0, 226.0, -43.02, 4.7, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Veylae (Undercity)'),
(9000022, 449353, 0, 0, 0, 1, 1, 0, 2272.5, 248.0, 34.34, 2.0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Veylin (Brill)'),
(9000023, 449344, 530, 0, 0, 1, 1, 0, -3742.0, -11692.0, -105.77, 1.0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Saltheris Dawnborn (Exodar)'),
(9000024, 449354, 530, 0, 0, 1, 1, 0, -2913.5, 4016.5, 0.51, 4.0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Salthoril Dawnspire (Azure Watch)'),
(9000025, 449346, 1, 0, 0, 1, 1, 0, 1630.5, -4433.0, 15.76, 1.6, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Waerun Cliffwalker (Orgrimmar)'),
(9000026, 449356, 1, 0, 0, 1, 1, 0, 336.0, -4681.0, 16.54, 3.5, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Destiny Weaver: Waeric Cliffstrider (Razor Hill)');

-- ---------------------------------------------------------------------------
-- 5. The presets: every Weaver's look, all sixteen
--
-- `item_*` columns are item *display* ids, which is what SMSG_MIRRORIMAGE_DATA carries
-- (the core sends `item->GetTemplate()->DisplayInfoID`).  Each row copies a dressed
-- character display of the same race and gender verbatim; the source id is in the comment.
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_display_preset` (`entry`, `display_id`, `race`, `gender`, `class`, `skin`, `face`, `hair`, `haircolor`, `facialhair`, `guild_id`, `item_head`, `item_shoulders`, `item_body`, `item_chest`, `item_waist`, `item_legs`, `item_feet`, `item_wrists`, `item_hands`, `item_back`, `item_tabard`) VALUES
(449340, 449292, 8, 0, 0, 3, 2, 7, 1, 4, 0, 25488, 53351, 28691, 28692, 25487, 25486, 34270, 25460, 50924, 52659, 0) /* Tav'vin, troll, look of display 19788 */,
(449350, 449292, 8, 0, 0, 3, 2, 7, 1, 4, 0, 25488, 53351, 28691, 28692, 25487, 25486, 34270, 25460, 50924, 52659, 0) /* Tav'ral, troll, look of display 19788 */,
(449342, 449293, 3, 0, 0, 9, 0, 4, 2, 8, 0, 41413, 41414, 37958, 37959, 37960, 41415, 0, 27475, 10389, 28579, 1) /* Thrain Galewin, dwarf, look of display 16090 */,
(449352, 449293, 3, 0, 0, 9, 0, 4, 2, 8, 0, 41413, 41414, 37958, 37959, 37960, 41415, 0, 27475, 10389, 28579, 1) /* Thrainnor Galestrom, dwarf, look of display 16090 */,
(449343, 449294, 5, 0, 0, 1, 7, 2, 9, 0, 0, 49457, 50482, 49458, 49459, 49460, 49461, 39650, 50020, 50925, 52650, 0) /* Veylae, undead, look of display 18921 */,
(449353, 449294, 5, 0, 0, 1, 7, 2, 9, 0, 0, 49457, 50482, 49458, 49459, 49460, 49461, 39650, 50020, 50925, 52650, 0) /* Veylin, undead, look of display 18921 */,
(449344, 449295, 11, 0, 0, 16, 9, 11, 9, 0, 0, 43662, 46182, 46183, 41405, 44380, 41448, 46731, 41449, 46853, 18764, 0) /* Saltheris Dawnborn, draenei, look of display 17930 */,
(449354, 449295, 11, 0, 0, 16, 9, 11, 9, 0, 0, 43662, 46182, 46183, 41405, 44380, 41448, 46731, 41449, 46853, 18764, 0) /* Salthoril Dawnspire, draenei, look of display 17930 */,
(449345, 449296, 4, 1, 0, 8, 6, 1, 6, 4, 0, 40757, 7696, 42415, 40759, 40760, 40761, 23935, 41477, 40183, 42416, 0) /* Elundra Moonsong, night elf, look of display 16652 */,
(449355, 449296, 4, 1, 0, 8, 6, 1, 6, 4, 0, 40757, 7696, 42415, 40759, 40760, 40761, 23935, 41477, 40183, 42416, 0) /* Elundrel Moonsinger, night elf, look of display 16652 */,
(449341, 449297, 10, 1, 0, 3, 2, 10, 8, 0, 0, 146593, 148098, 149499, 151349, 153458, 24288, 156541, 24289, 158509, 158669, 0) /* Magistrix Benjamin, blood elf, look of display 13656 */,
(449351, 449297, 10, 1, 0, 3, 2, 10, 8, 0, 0, 146593, 148098, 149499, 151349, 153458, 24288, 156541, 24289, 158509, 158669, 0) /* Magistrix Belanor, blood elf, look of display 13656 */,
(449346, 449298, 2, 0, 0, 3, 3, 6, 2, 2, 0, 24408, 48191, 23977, 32502, 30437, 23974, 23973, 23975, 40869, 18764, 0) /* Waerun Cliffwalker, orc, look of display 18453 */,
(449356, 449298, 2, 0, 0, 3, 3, 6, 2, 2, 0, 24408, 48191, 23977, 32502, 30437, 23974, 23973, 23975, 40869, 18764, 0) /* Waeric Cliffstrider, orc, look of display 18453 */,
(449347, 449299, 1, 0, 0, 1, 7, 15, 0, 8, 0, 23922, 23919, 47440, 23926, 24529, 47441, 34286, 23925, 40183, 32247, 0) /* Galric Olim, human, look of display 8177 */,
(449357, 449299, 1, 0, 0, 1, 7, 15, 0, 8, 0, 23922, 23919, 47440, 23926, 24529, 47441, 34286, 23925, 40183, 32247, 0) /* Galrin Olemar, human, look of display 8177 */;

-- ---------------------------------------------------------------------------
-- 6. A readable check
-- ---------------------------------------------------------------------------
-- SELECT p.entry, t.name, p.race, p.gender, p.display_id, p.item_chest, p.item_legs
--   FROM creature_display_preset p JOIN creature_template t ON t.entry = p.entry
--  ORDER BY p.entry;
