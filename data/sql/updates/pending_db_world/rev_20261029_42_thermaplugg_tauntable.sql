-- Gnomeregan: Mekgineer Thermaplugg kept stock AzerothCore's taunt immunity (row -230: NO_TAUNT, Attack Me, Bind). Like
-- the other Gnomeregan bosses he takes row -229, the same mechanic immunities without the taunt immunity (#9673).
UPDATE `creature_template` SET `CreatureImmunitiesId` = -229 WHERE `entry` IN (7800, 107800, 207800);
