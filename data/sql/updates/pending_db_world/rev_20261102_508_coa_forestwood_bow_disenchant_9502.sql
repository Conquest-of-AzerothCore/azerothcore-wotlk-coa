-- COA-9502: the Forestwood Bow (uncommon item level 10) had no disenchant loot, so Disenchant refused it.
-- Its peers (Forestwood Crossbow, Forestwood Buckler) and stock uncommon gear of this level use DisenchantID 21.
UPDATE `item_template` SET `DisenchantID` = 21 WHERE `entry` = 1061534 AND `DisenchantID` = 0;
