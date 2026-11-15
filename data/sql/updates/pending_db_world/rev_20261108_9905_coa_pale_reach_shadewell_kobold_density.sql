-- Shadewell Kobolds (164237), placed by the user in game: one moved clear of its neighbours and five removed to thin the
-- camp.
UPDATE `creature` SET `position_x` = -8236.059, `position_y` = -57.275, `position_z` = 281.887, `orientation` = 5.1511
WHERE `guid` = 9961640 AND `id` = 164237;

DELETE FROM `creature_addon` WHERE `guid` IN (9961617, 9961680, 9961701, 9961709, 9961734);
DELETE FROM `creature` WHERE `guid` IN (9961617, 9961680, 9961701, 9961709, 9961734) AND `id` = 164237;
