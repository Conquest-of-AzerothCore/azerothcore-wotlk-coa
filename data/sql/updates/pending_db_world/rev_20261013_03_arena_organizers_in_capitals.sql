-- Arena Organizer (26012) in the eight capitals outside the never-active Arena Tournament event (31),
-- standing on the ground where its tournament pedestal stood, so arena team charters can be bought there.
DELETE FROM `game_event_creature` WHERE `eventEntry` = 31 AND `guid` IN (95137, 95240, 95491, 95677, 95919, 96079, 96214, 96439);

UPDATE `creature` SET `position_z` = 60.6701 WHERE `guid` = 95137 AND `id` = 26012;
UPDATE `creature` SET `position_z` = 14.5456 WHERE `guid` = 95240 AND `id` = 26012;
UPDATE `creature` SET `position_z` = 131.236 WHERE `guid` = 95491 AND `id` = 26012;
UPDATE `creature` SET `position_z` = 7.48746 WHERE `guid` = 95677 AND `id` = 26012;
UPDATE `creature` SET `position_z` = 501.537 WHERE `guid` = 95919 AND `id` = 26012;
UPDATE `creature` SET `position_z` = 94.356 WHERE `guid` = 96079 AND `id` = 26012;
UPDATE `creature` SET `position_z` = -0.234778 WHERE `guid` = 96214 AND `id` = 26012;
UPDATE `creature` SET `position_z` = 1341.48 WHERE `guid` = 96439 AND `id` = 26012;
