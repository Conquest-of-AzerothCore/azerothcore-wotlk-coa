-- Sunstrider Isle's zone quests took only blood elves (stock AllowableRaces 512), although the Travel Permit
-- 977028 sends every Horde race there and the isle's own 8547, 9704, 9705 and 8350 already take every Horde
-- race (690), as Deathknell's Rude Awakening 363 does. The class quests keep their blood elf mask.
UPDATE `quest_template` SET `AllowableRaces` = 690
WHERE `ID` IN (8325, 8326, 8327, 8330, 8334, 8335, 8336, 8338, 8345, 8346, 8347) AND `AllowableRaces` = 512;
