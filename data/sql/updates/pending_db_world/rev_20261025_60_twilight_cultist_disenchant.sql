-- COA-7173: the Twilight Cultist Cowl, Mantle and Robe (uncommon armour, item level 60) had no disenchant loot,
-- so Disenchant did nothing on them. Give them the bracket their CoA copies already use (DisenchantID 10).
UPDATE `item_template` SET `DisenchantID` = 10 WHERE `entry` IN (20406, 20407, 20408);
