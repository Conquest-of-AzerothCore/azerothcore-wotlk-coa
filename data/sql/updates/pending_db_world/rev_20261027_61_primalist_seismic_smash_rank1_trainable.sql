-- Primalist Seismic Smash rank 1 (300693, Spell.dbc BaseLevel 59) at the Primalist class trainer (900031).
-- Ranks 2-4 (301276-301279, levels 62/68/74/80) already train and gate on 300693 as ReqAbility1; the row
-- for rank 1 itself was never generated, so the base rank had no trainer row and no AscensionCompatData::
-- ClassSpells entry, matching the ReqLevel-equals-DBC-BaseLevel convention every other rank-1 row in this
-- trainer follows (500402 BaseLevel 1 -> ReqLevel 1, 801794 BaseLevel 12 -> ReqLevel 12, 570756 BaseLevel 60
-- -> ReqLevel 60). MoneyCost follows SpellbookCostData::Price(59, 300693) = (13*59*59+1)/2 = 22627 copper, the
-- same formula the rest of this file's rows use; 300693 is not in UtilitySpells, so no utility halving applies.
DELETE FROM `trainer_spell` WHERE `TrainerId` = 900031 AND `SpellId` = 300693;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`,
    `ReqAbility2`, `ReqAbility3`, `ReqLevel`)
VALUES
(900031, 300693, 22627, 0, 0, 0, 0, 0, 59);
