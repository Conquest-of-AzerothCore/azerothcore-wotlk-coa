-- "Bitter Legacy of the War" is handed back to the NPC who gives it (decided by the user; no video shows the hand-in).
DELETE FROM `creature_questender` WHERE `id` = 164376 AND `quest` = 175131;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164376, 175131);
