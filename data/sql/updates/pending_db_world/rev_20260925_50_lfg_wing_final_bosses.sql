-- Dungeon Finder: every Ascension wing dungeon gets its final boss, so finishing it completes the
-- dungeon and gives the random dungeon reward. Final bosses are the ones the client names for each
-- wing in DungeonEncounterExtra.dbc. The whole-dungeon entries these bosses ended before
-- (1 Wailing Caverns, 2 Scholomance, 14 Gnomeregan, 22 Uldaman) are level 100 in LFGDungeons.dbc.
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1003 WHERE `entry` = 586; -- Lord Cobrahn: Wailing Caverns - Pit of Fangs
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1031 WHERE `entry` = 589; -- Skum: Wailing Caverns - Winding Chasm
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1035 WHERE `entry` = 591; -- Verdan the Everliving: Wailing Caverns - Crag of the Everliving
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1039 WHERE `entry` = 592; -- Mutanus the Devourer: Wailing Caverns - Dreamer's Rock
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1004 WHERE `entry` = 380; -- Electrocutioner 6000: Gnomeregan - Launch Bay
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1037 WHERE `entry` = 381; -- Crowd Pummeler 9-60: Gnomeregan - Engineering Labs
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1033 WHERE `entry` = 382; -- Mekgineer Thermaplugg: Gnomeregan - Tinker's Court
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1007 WHERE `entry` = 549; -- Ironaya: Uldaman - Hall of the Crafters
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1006 WHERE `entry` = 553; -- Grimlok: Uldaman - The Stone Vault
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 1005 WHERE `entry` = 554; -- Archaedas: Uldaman - Map Chamber
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 601 WHERE `entry` = 237; -- Golem Lord Argelmach: Blackrock Depths - Manufactory
UPDATE `instance_encounters` SET `lastEncounterDungeon` = 51 WHERE `entry` = 463; -- Darkmaster Gandling: Lower Scholomance
DELETE FROM `instance_encounters` WHERE `entry` = 3457;
INSERT INTO `instance_encounters` (`entry`, `creditType`, `creditEntry`, `lastEncounterDungeon`, `comment`) VALUES
(3457, 0, 10508, 54, 'Ras Frostwhisper');
