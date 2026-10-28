-- Shadowhound (#267): the client's CreatureFamily.dbc row 551 'Shadowhound' names the pet skill line 11805
-- 'Pet - Shadowhound': Shadow Growl 680239 (taunt), Shadow Claw 800697 (up to 3 enemies), Track 500181 (leap,
-- up to 5 enemies) and the passive Shadowhound Visual 500036. creature_template.family is a tinyint and cannot
-- hold 551, so the Houndmaster's Whistle pet takes them as its default spells, which
-- Pet::InitLevelupSpellsForLevel teaches at each spell's level.
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 50124;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`) VALUES
(50124, 0, 680239),
(50124, 1, 800697),
(50124, 2, 500181),
(50124, 3, 500036);
