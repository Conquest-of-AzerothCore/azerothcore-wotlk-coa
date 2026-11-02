-- COA-9626: the Looter's Cap (uncommon cloth head, item level 18) had no disenchant loot, so Disenchant refused it.
-- Stock uncommon armour of item level 18 uses DisenchantID 2 with RequiredDisenchantSkill 1, as the cap already does.
UPDATE `item_template` SET `DisenchantID` = 2 WHERE `entry` = 2060043 AND `DisenchantID` = 0;
