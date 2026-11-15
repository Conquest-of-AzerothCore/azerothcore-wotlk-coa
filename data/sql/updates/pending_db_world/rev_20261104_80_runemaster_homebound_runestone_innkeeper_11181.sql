-- #11181: Homebound Runestone (560316) "allows you to set your Hearthstone at its destination" and its aura 803022
-- reads "The Runemaster can set their Hearthstone here", but the Primordial Portal it summons (50058) had no npc
-- flags, so nothing could be done with it. Gossip and innkeeper let it offer the native "Make this inn your home".
-- SummonProperties 61 summons it as a guardian, which follows its owner; rooted keeps it where it was created.
UPDATE `creature_template` SET `npcflag` = 65537 WHERE `entry` = 50058;
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 50058;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(50058, 1, 0, 0, 1);
