-- Rude Awakening 363, Deathknell's first quest, took only Undead (stock AllowableRaces 16). It now takes every Horde
-- race (690), as Valley of Trials' 4641, Camp Narache's 747 and Deathknell's own next quests 364 and 3901 do.
UPDATE `quest_template` SET `AllowableRaces` = 690 WHERE `ID` = 363;
