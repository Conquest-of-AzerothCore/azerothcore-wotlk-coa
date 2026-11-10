-- Yorin Hollowbrook sat on the front edge of his chair with the floor sitting pose and clipped the inn table. He now
-- sits in it with the medium chair stand state, facing the chair's way, raised and moved forward onto its tall seat.
-- Innkeeper Delyra moves to the spot the author picked in game.
UPDATE `creature` SET `position_x` = -7777.209, `position_y` = 599.323, `position_z` = 138.5, `orientation` = 4.515
WHERE `guid` = 9920430;
UPDATE `creature` SET `position_x` = -7767.307, `position_y` = 596.686, `position_z` = 138.28, `orientation` = 3.6834
WHERE `guid` = 9960021;

DELETE FROM `creature_addon` WHERE `guid` = 9920430;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
`auras`) VALUES
(9920430, 0, 0, 5, 1, 0, 0, '');
