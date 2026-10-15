-- Darkmoon - Season 10 Wildcard content exists only on a Wildcard realm (CoAChallenges.GameModes.Realm = WildCard):
-- the worldserver starts this internal event there at startup. It spawns Silas Darkmoon and Burth and offers the
-- Season 10 Call Board quests of mod-hero-call-board.
SET @EVENT := 194;
DELETE FROM `game_event` WHERE `eventEntry` = @EVENT;
INSERT INTO `game_event` (`eventEntry`, `description`, `world_event`, `announce`) VALUES
(@EVENT, 'Darkmoon - Season 10 Wildcard', 5, 0);
DELETE FROM `game_event_creature` WHERE `eventEntry` = @EVENT;
INSERT INTO `game_event_creature` (`eventEntry`, `guid`)
SELECT @EVENT, `guid` FROM `creature` WHERE `guid` BETWEEN 9950001 AND 9950100 AND `id` IN (642827, 342828);
