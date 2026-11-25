START TRANSACTION;

INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `BuyCount`, `InventoryType`, `AllowableClass`,
    `AllowableRace`, `ItemLevel`, `RequiredLevel`, `stackable`, `spellid_1`, `spelltrigger_1`, `spellcharges_1`,
    `spellcooldown_1`, `spellcategorycooldown_1`)
VALUES
(8700100, 0, 6, 'Prismatic Setting', 45823, 3, 1, 0, -1, -1, 60, 60, 20, 8700101, 0, -1, -1, -1)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `spellid_1` = VALUES(`spellid_1`);

DELETE FROM `item_dbc` WHERE `ID` = 8700100;
INSERT INTO `item_dbc`
    (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`)
VALUES (8700100, 0, 6, -1, 0, 45823, 0, 0);

DELETE FROM `spell_dbc` WHERE `ID` IN (8700101, 8700102);
INSERT INTO `spell_dbc`
    (`ID`, `Attributes`, `AttributesEx`, `Targets`, `CastingTimeIndex`, `InterruptFlags`, `ProcChance`,
    `RangeIndex`, `Reagent_1`, `ReagentCount_1`, `Reagent_2`, `ReagentCount_2`, `EquippedItemClass`,
    `Effect_1`, `EffectBasePoints_1`, `ImplicitTargetA_1`, `EffectItemType_1`, `EffectMiscValue_1`,
    `Name_Lang_enUS`, `Description_Lang_enUS`, `SchoolMask`)
VALUES
(8700101, 256, 0, 16, 15, 15, 101, 1, 0, 0, 0, 0, -1, 53, 0, 1, 0, 3848,
    'Prismatic Setting',
    'Adds a prismatic socket to eligible gear in place of its permanent enhancement. Applying a permanent enhancement removes this socket and returns its gem to your bags.',
    1),
(8700102, 65568, 1024, 0, 34, 15, 101, 1, 21752, 1, 23445, 5, -1, 24, 0, 1, 8700100, 0,
    'Prismatic Setting', 'Craft a Prismatic Setting.', 1);

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (8700101, 8700102);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`)
SELECT `ID`, `Description_Lang_enUS` FROM `spell_dbc` WHERE `ID` IN (8700101, 8700102);

DELETE FROM `skilllineability_dbc` WHERE `ID` = 8700100;
INSERT INTO `skilllineability_dbc`
    (`ID`, `SkillLine`, `Spell`, `MinSkillLineRank`, `TrivialSkillLineRankHigh`, `TrivialSkillLineRankLow`)
VALUES (8700100, 755, 8700102, 450, 450, 450);

DELETE FROM `coa_client_skill_line_ability` WHERE `ID` = 8700100;
INSERT INTO `coa_client_skill_line_ability` (`ID`, `SkillLine`) VALUES (8700100, 755);

DELETE FROM `trainer_spell` WHERE `SpellId` = 8700102;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`)
SELECT `grand_master`.`TrainerId`, 8700102, 100000, 755, 450
FROM `trainer_spell` AS `grand_master`
WHERE `grand_master`.`SpellId` = 51310 AND `grand_master`.`ReqSkillLine` = 755;

COMMIT;
