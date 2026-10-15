-- Soldier Rulven gives "The Hand Guiding the Frostmane" (gameplay video youtu.be/pNxA-cq_KhQ?t=4914, confirmed by the user).
DELETE FROM `creature_queststarter` WHERE `id` = 164070 AND `quest` = 175059;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164070, 175059);
