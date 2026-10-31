-- The Three Apex Hunts are normal quests: as Method 0 the client shows the
-- required-items turn-in panel and never offers the accept window. Restate the
-- shipped level and flags, and give each hunt its faction's playable-race mask
-- (the same masks stock faction quests use) so every race of that faction can
-- take it and cross-faction characters cannot. Idempotent; the file name sorts
-- after the parity migration, so it wins on a fresh database.
UPDATE `quest_template`
SET `QuestType` = 2,
    `MinLevel` = 58,
    `Flags` = 524296,
    `AllowableRaces` = 1101
WHERE `ID` = 17839;

UPDATE `quest_template`
SET `QuestType` = 2,
    `MinLevel` = 58,
    `Flags` = 524296,
    `AllowableRaces` = 690
WHERE `ID` = 17844;
