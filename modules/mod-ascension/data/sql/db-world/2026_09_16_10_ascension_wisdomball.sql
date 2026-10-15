-- Wondrous Wisdomball (creature 79025, item 101169, summon 83050).
--
-- The companion that lists the quests of the dungeon you are standing in - chains and other
-- prerequisites included - and takes them back at the ball itself. Ascension's own item and
-- summon spell survived in the world DB and in the realm's Spell.dbc; the creature they point
-- at did not, which is why the item did nothing. This adds it back, plus a way to obtain it.
--
-- The ball is a non-combat pet and a quest giver. Its gossip list, its quest mark and the three
-- quest packets a quest giver normally answers are handled by the module's script
-- (AscensionWisdomball.cpp), because the ball appears in none of the quest relation tables.

REPLACE INTO `creature_template`
(`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`,
 `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`,
 `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`,
 `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`,
 `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`,
 `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
 `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`,
 `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
VALUES
(79025, 0, 0, 0, 0, 0,
 'Wondrous Wisdomball', NULL, NULL, 0, 1, 1, 0, 35, 3,
 1, 1.14286, 1, 1, 20, 0, 0,
 1, 2000, 2000, 1, 1, 1,
 0, 0, 0, 0, 12, 0, 0, 0,
 0, 0, 0, 0, 0, '', 0, 1,
 1, 1, 1, 1, 0, 0,
 1, 0, 0, 'npc_wondrous_wisdomball', 51831);

-- Display 49183 is the crystal ball the ball has always used: model 5860,
-- world\expansion06\doodads\7xp_crystalball_khadgar01.mdx. The client has both records; the
-- server's own CreatureDisplayInfo and CreatureModelData tables are trimmed and carry neither,
-- and a display the server cannot resolve is dropped along with the creature that names it. The
-- native DBC SQL loader reads these overrides, so the records are supplied from the same values
-- the client renders, without replacing a binary DBC.
DELETE FROM `creaturedisplayinfo_dbc` WHERE `ID` = 49183;
INSERT INTO `creaturedisplayinfo_dbc`
(`ID`, `ModelID`, `CreatureModelScale`, `CreatureModelAlpha`, `TextureVariation_1`) VALUES
(49183, 5860, 1.25, 255, NULL);

DELETE FROM `creaturemodeldata_dbc` WHERE `ID` = 5860;
INSERT INTO `creaturemodeldata_dbc`
(`ID`, `Flags`, `ModelName`, `ModelScale`, `CollisionWidth`, `CollisionHeight`, `MountHeight`) VALUES
(5860, 0, 'world\\expansion06\\doodads\\7xp_crystalball_khadgar01.mdx', 1, 0.6111, 2.031, 0);

-- Use the core's default bounds and reach for the newly registered display.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 49183;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`) VALUES
(49183, 0.389, 1.5, 2);

REPLACE INTO `creature_template_model`
(`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
(79025, 0, 49183, 1, 1, 51831);

-- Where it can be bought. Ascension sold it from the reliquary vendor's pet trade; here it joins
-- the companion suppliers that exist, so both factions can reach one while leveling and again at
-- the top: Goldshire and Orgrimmar early, Shattrath and Dalaran later.
REPLACE INTO `npc_vendor`
(`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
VALUES
(6367, 0, 101169, 0, 0, 0, 51831),   -- Donni Anthania, Elwynn Forest
(8404, 0, 101169, 0, 0, 0, 51831),   -- Xan'tish, Orgrimmar
(20980, 0, 101169, 0, 0, 0, 51831),  -- Dealer Rashaad, Shattrath
(28951, 0, 101169, 0, 0, 0, 51831);  -- Breanni, Dalaran

-- Priced with the other exotic companions rather than given away.
UPDATE `item_template` SET `BuyPrice` = 500000, `SellPrice` = 83333 WHERE `entry` = 101169;
