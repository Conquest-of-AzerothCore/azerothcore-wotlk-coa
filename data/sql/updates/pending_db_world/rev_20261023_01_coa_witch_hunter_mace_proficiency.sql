DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 0 AND `classmask` = 16384 AND `Spell` = 198;
INSERT INTO `playercreateinfo_spell_custom` (`racemask`, `classmask`, `Spell`, `Note`) VALUES
(0, 16384, 198, 'Witch Hunter baseline: one-handed mace proficiency');

DELETE FROM `trainer_spell` WHERE `TrainerId` = 900015 AND `SpellId` = 198;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`) VALUES
(900015, 198, 1000, 0, 0, 0, 0, 0, 1, 0);
