-- Two Pale Reach quests nobody gave out or took back: Shadowbone Depths (175126) is given and taken by Deirdre, and
-- Sins Beyond Mercy (175200) by Confessor Mourn at Hallow Wind Abbey (from the user's server).
DELETE FROM `creature_queststarter` WHERE `quest` IN (175126, 175200);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(164355, 175126),
(164556, 175200);
DELETE FROM `creature_questender` WHERE `quest` IN (175126, 175200);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(164355, 175126),
(164556, 175200);
