-- Patrolman's Sword (#11800): the live item cache sends RequiredDisenchantSkill 1, but DisenchantID 0 made the server
-- refuse Disenchant. Bracket 21 is the uncommon weapon bracket for item level 5-15 (#7000, #9502).
UPDATE `item_template` SET `DisenchantID` = 21 WHERE `entry` = 450659 AND `DisenchantID` = 0;
