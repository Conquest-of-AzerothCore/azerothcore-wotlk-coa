-- Thunderbrew Distillery, the Kharanos inn (#9216): area trigger 710 covers the inn (35 yd around Innkeeper Belm)
-- but had no tavern row, and the area (2102) carries no rest-zone flag, so resting there never started.
DELETE FROM `areatrigger_tavern` WHERE `id` = 710;
INSERT INTO `areatrigger_tavern` (`id`, `name`, `faction`) VALUES
(710, 'Dun Morogh - Kharanos - Thunderbrew Distillery', 2);
