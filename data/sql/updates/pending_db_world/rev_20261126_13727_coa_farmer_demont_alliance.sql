-- Farmer Demont (157002) is a Westfall Stormwind farmer (faction 12, matching
-- Farmer Saldean 233, Farmer Furlbrow 237, and other Westfall humans), and his
-- Riverpaw Genocide quests (17011, 17012) award Stormwind reputation (72) for
-- Alliance races only (AllowableRaces 1101, matching stock Westfall quests).

UPDATE `creature_template`
SET `faction` = 12
WHERE `entry` = 157002 AND `faction` = 35;

UPDATE `quest_template`
SET `AllowableRaces` = 1101
WHERE `ID` IN (17011, 17012) AND `AllowableRaces` = 0;
