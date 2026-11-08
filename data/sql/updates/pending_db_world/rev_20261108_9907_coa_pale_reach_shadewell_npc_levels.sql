-- Shadewell's guards and townsfolk were left at level 1. On live they read max(base, player level - 2): Fernad and
-- Innkeeper Liora show 22 for a level-24 player, the Shadewell Guard 25, as the Dunshire and Cresthairn Guards are. Guards
-- and Andraste Troopers get 25, townsfolk and their livestock 22, matching the zone's level 21-22 creatures.
-- Grand Cheesemonger Almo keeps his live base level 8; the rabbits and the quest trigger stay level 1.
UPDATE `creature_template` SET `minlevel` = 25, `maxlevel` = 25 WHERE `entry` IN (164136, 164311);
UPDATE `creature_template` SET `minlevel` = 22, `maxlevel` = 22
WHERE `entry` IN (164137, 164141, 164142, 164145, 164146, 164147, 164148, 164149, 164150, 164151, 164152, 164159, 164235,
    164236, 164949);

-- A Shadewell Murloc Warrior moved by the user, out of aggro range of the Shadewell Guard's road patrol.
UPDATE `creature` SET `position_x` = -8181.288, `position_y` = -313.303, `position_z` = 235.385, `orientation` = 3.6274
WHERE `guid` = 9961540 AND `id` = 164154;
