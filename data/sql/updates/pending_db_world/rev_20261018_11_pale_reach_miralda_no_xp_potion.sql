-- Innkeeper Miralda (Pale Reach) does not sell the Potion of Experience.
DELETE FROM `npc_vendor` WHERE `entry` = 164036 AND `item` = 135060;
