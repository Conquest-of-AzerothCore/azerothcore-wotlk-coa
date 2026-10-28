-- Ranger Bushcraft: Waterskin ranks 2-8 at the Ranger class trainer (900021).
-- Crude Waterskin 802808 (rank 1) comes with the Bushcraft skill at character creation (SkillLineAbility
-- AcquireMethod 2); ranks 2-8 are SkillLine 505 recipes with AcquireMethod 0 and nothing taught them.
-- ReqLevel is each spell's Spell.dbc BaseLevel, which Exiles DB also lists as "Level required" (14, 22, 30, 38,
-- 44, 50, 56); ReqAbility1 is the rank below. MoneyCost is SpellbookCostData::Price at that level for a utility
-- row, so the trainer and the Book of Ascension (SpellbookRankData) charge the same.
DELETE FROM `trainer_spell` WHERE `TrainerId` = 900021 AND `SpellId` IN (802810, 802812, 802813, 802814, 802815,
    802816, 802817);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`,
    `ReqAbility2`, `ReqAbility3`, `ReqLevel`)
VALUES
(900021, 802810, 490, 0, 0, 802808, 0, 0, 14),
(900021, 802812, 1331, 0, 0, 802810, 0, 0, 22),
(900021, 802813, 2475, 0, 0, 802812, 0, 0, 30),
(900021, 802814, 4332, 0, 0, 802813, 0, 0, 38),
(900021, 802815, 5808, 0, 0, 802814, 0, 0, 44),
(900021, 802816, 7500, 0, 0, 802815, 0, 0, 50),
(900021, 802817, 10192, 0, 0, 802816, 0, 0, 56);
