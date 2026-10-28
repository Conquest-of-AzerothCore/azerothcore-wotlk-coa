-- Path to Ascension: Novice Rider (4420430-4420439) is offered by the racial riding trainers from level 5,
-- the level their Novice Riding (33379) training unlocks. The imported rows carried a level 8 minimum, so a
-- character who bought the training below 8 never saw the quest, and its "Learn Novice Riding" credit was
-- unreachable. The client's own Quest data gives these rows a minimum level of 5.
UPDATE `quest_template` SET `MinLevel` = 5
WHERE `ID` IN (4420430, 4420431, 4420432, 4420433, 4420434, 4420435, 4420436, 4420437, 4420438, 4420439);
