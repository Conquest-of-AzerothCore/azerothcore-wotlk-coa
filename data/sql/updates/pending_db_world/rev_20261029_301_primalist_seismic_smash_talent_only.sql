-- Seismic Smash rank 1 (300693) is the Mountain King talent CharacterAdvancement 7498 (tab MountainKing, 1 TE,
-- 23 points invested), not a trainer spell; ranks 2-5 stay trainable behind it.
DELETE FROM `trainer_spell` WHERE `TrainerId` = 900031 AND `SpellId` = 300693;
