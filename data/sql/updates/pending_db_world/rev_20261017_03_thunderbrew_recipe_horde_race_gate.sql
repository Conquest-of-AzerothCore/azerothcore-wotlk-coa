-- Lost Thunderbrew Recipe 4134 is the Horde mirror of Hurley Blackbreath 4126
-- (same recipe item 11312, mirrored turn-ins: Ragnar Thunderbrew for Alliance,
-- Vivian Lagrave for Horde), but ships AllowableRaces 0 while every sibling
-- carries its faction mask (4126 = 1101 Alliance, the other Horde dungeon
-- quests = 690). The neutral Wondrous Wisdomball offers dungeon quests directly,
-- bypassing the Horde-only giver, so anyone could take both versions (#7940).
-- Gate 4134 to Horde; the ball's existing SatisfyQuestRace check then offers
-- each faction only its own version, as it already does everywhere else.
UPDATE `quest_template` SET `AllowableRaces` = 690 WHERE `ID` = 4134;
