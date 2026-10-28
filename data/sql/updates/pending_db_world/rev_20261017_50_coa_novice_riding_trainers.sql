-- Riding trainers teach Novice Riding (skill 50) free from level 5; each later rank needs the one before it
DELETE FROM `trainer_spell` WHERE `SpellId` = 33379;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT `TrainerId`, 33379, 0, 0, 0, 0, 0, 0, 5, 0 FROM `trainer_spell` WHERE `SpellId` = 33388;
UPDATE `trainer_spell` SET `MoneyCost` = 34000, `ReqSkillLine` = 762, `ReqSkillRank` = 50 WHERE `SpellId` = 33388;
UPDATE `trainer_spell` SET `ReqSkillRank` = 75 WHERE `SpellId` = 33391;
UPDATE `trainer_spell` SET `ReqSkillRank` = 150 WHERE `SpellId` = 34090;
UPDATE `trainer_spell` SET `ReqSkillRank` = 225 WHERE `SpellId` IN (34091, 54197);

-- Draenei start beside the Night Elves and Blood Elves beside the Forsaken, so Jartsam and Velma Warnam teach them too
UPDATE `conditions` SET `ConditionValue1` = `ConditionValue1` | 1024
WHERE `ConditionTypeOrReference` = 16 AND `SourceGroup` = 4019
    AND ((`SourceTypeOrReferenceId` = 15 AND `SourceEntry` = 0) OR (`SourceTypeOrReferenceId` = 14 AND `SourceEntry` = 4877));
UPDATE `conditions` SET `ConditionValue1` = `ConditionValue1` & ~1024
WHERE `ConditionTypeOrReference` = 16 AND `SourceGroup` = 4019 AND `SourceTypeOrReferenceId` = 14 AND `SourceEntry` = 5862;
UPDATE `conditions` SET `ConditionValue1` = `ConditionValue1` | 512
WHERE `ConditionTypeOrReference` = 16 AND `SourceGroup` = 4015
    AND ((`SourceTypeOrReferenceId` = 15 AND `SourceEntry` = 0) OR (`SourceTypeOrReferenceId` = 14 AND `SourceEntry` = 4873));
UPDATE `conditions` SET `ConditionValue1` = `ConditionValue1` & ~512
WHERE `ConditionTypeOrReference` = 16 AND `SourceGroup` = 4015 AND `SourceTypeOrReferenceId` = 14 AND `SourceEntry` = 5859;

-- The ten racial starter mounts (the Novice Rider tutorial's mounts) can be learned with Novice Riding
UPDATE `item_template` SET `RequiredLevel` = 5, `RequiredSkillRank` = 50
WHERE `entry` IN (5656, 5665, 5873, 8588, 13322, 13333, 15277, 28927, 29744, 47100) AND `RequiredSkill` = 762;
