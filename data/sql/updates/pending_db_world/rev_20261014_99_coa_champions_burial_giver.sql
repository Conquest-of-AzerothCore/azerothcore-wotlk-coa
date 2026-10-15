-- "A Champion's Burial" is given by General Baugwolf in Dun Kazad: a gameplay video shows it accepted from his quest window
-- together with Assist At Metantenna Outpost and Boreos Fort, which he already gives (youtu.be/MmMb3MxRb0A?t=1618).
DELETE FROM `creature_queststarter` WHERE `id` = 164392 AND `quest` = 175166;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164392, 175166);
