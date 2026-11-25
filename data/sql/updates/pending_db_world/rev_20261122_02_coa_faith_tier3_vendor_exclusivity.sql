-- Vestments of Faith already has slot- and difficulty-matched Tier 3 offers.
DELETE FROM `npc_vendor`
WHERE (`entry` BETWEEN 91000005 AND 91000008 OR `entry` BETWEEN 91000109 AND 91000116)
    AND `item` IN (SELECT `entry` FROM `item_template` WHERE `ItemSet` = 525);
