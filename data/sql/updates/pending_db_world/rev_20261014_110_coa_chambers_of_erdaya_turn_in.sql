-- "The Chambers of Erdaya" ends with "Find the survivor inside the Chambers": Enilith Naemyl, down in the Chambers, who
-- gives the next quest of the chain (A Cult Within the Embassy).
DELETE FROM `creature_questender` WHERE `id` = 164309 AND `quest` = 175100;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164309, 175100);
