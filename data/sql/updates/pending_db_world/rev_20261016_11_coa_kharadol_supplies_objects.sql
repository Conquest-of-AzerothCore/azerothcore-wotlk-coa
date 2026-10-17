-- Kharadol Supplies (175058): pick-up objects for the three quest items on Kharadol Bridge, lootable only while on the quest.
-- 2300803 Medical Supplies (bandage pile), 2300804 Kharadol Blunderbuss (fallen blunderbuss), 2300805 Guard Ammunition (ammo crate).
DELETE FROM `gameobject_template` WHERE `entry` IN (2300803, 2300804, 2300805);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data3`, `Data8`, `Data10`, `Data12`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(2300803, 3, 6491, 'Medical Supplies', '', '', '', 1, 1689, 2300803, 1, 175058, 1, 1, '', '', 0),
(2300804, 3, 515473, 'Kharadol Blunderbuss', '', '', '', 1, 1689, 2300804, 1, 175058, 1, 1, '', '', 0),
(2300805, 3, 335, 'Guard Ammunition', '', '', '', 1, 1689, 2300805, 1, 175058, 1, 1, '', '', 0);
DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (2300803, 2300804, 2300805);
INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(2300803, 559883, 0, 100, 1, 1, 0, 1, 1, 'Medical Supplies - Kharadol Supplies'),
(2300804, 559884, 0, 100, 1, 1, 0, 1, 1, 'Kharadol Blunderbuss - Kharadol Supplies'),
(2300805, 559885, 0, 100, 1, 1, 0, 1, 1, 'Guard Ammunition - Kharadol Supplies');
