START TRANSACTION;

UPDATE `item_template`
SET `RequiredSkill` = 755, `RequiredSkillRank` = 450,
    `spellid_1` = 8700101, `spelltrigger_1` = 0, `spellcharges_1` = -1,
    `spellcooldown_1` = -1, `spellcategorycooldown_1` = -1
WHERE `entry` = 21752;

DELETE FROM `trainer_spell` WHERE `SpellId` = 8700102 AND `ReqSkillLine` = 755;
DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 8700100 AND `SkillLine` = 755;
DELETE FROM `skilllineability_dbc` WHERE `ID` = 8700100 AND `SkillLine` = 755 AND `Spell` = 8700102;

DELETE FROM `disables` WHERE `sourceType` = 0 AND `entry` = 8700102;
INSERT INTO `disables` (`sourceType`, `entry`, `flags`, `comment`) VALUES
(0, 8700102, 1, 'Prismatic Setting crafting was replaced by using Thorium Setting directly');

COMMIT;
