-- "The Three Sisters" is a cauldron (a quest object) that takes "Cardinal Sin" (gameplay video and the user's screenshot of
-- its quest window). The world database had no such object; this adds it with the stock bubbling cauldron model, to be
-- placed in game where the Three Sisters are.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`) VALUES
(2300801, 2, 216, 'The Three Sisters', '', '', '', 1.42) ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`);
DELETE FROM `gameobject_questender` WHERE `id` = 2300801 AND `quest` = 175204;
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES
(2300801, 175204);
