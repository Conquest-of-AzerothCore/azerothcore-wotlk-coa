-- Elder Thrymus the Astray takes "A Near-Forgotten Altar" as well as giving it (confirmed by the user).
DELETE FROM `creature_questender` WHERE `id` = 164448 AND `quest` = 175153;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164448, 175153);
