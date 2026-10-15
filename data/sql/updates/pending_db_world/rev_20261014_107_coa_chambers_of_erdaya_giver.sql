-- Lady Amaranthe Naemyl, who takes "All A Distraction", gives "The Chambers of Erdaya" (confirmed by the user).
DELETE FROM `creature_queststarter` WHERE `id` = 164278 AND `quest` = 175100;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164278, 175100);
