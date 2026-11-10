-- #10810: Gutspill (6170) drops the Gutspill Cloak (450585) every kill, as on Ascension.
DELETE FROM `creature_loot_template` WHERE `Entry` = 6170 AND `Item` = 450585;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`,
    `MinCount`, `MaxCount`, `Comment`) VALUES
(6170, 450585, 0, 100, 0, 1, 0, 1, 1, 'Gutspill - Gutspill Cloak');
