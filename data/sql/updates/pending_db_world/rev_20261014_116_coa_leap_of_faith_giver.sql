-- "A Leap of Faith" (one version to inform Bishop Beorn, one Patriarch Khazemil) follows Holdor Stonefist's funeral at
-- Snowveil Cemetery: Bilna Stonefist, his widow, who takes "A Champion's Burial", offers both.
DELETE FROM `creature_queststarter` WHERE `id` = 164453 AND `quest` IN (175168, 175169);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164453, 175168),
(164453, 175169);
