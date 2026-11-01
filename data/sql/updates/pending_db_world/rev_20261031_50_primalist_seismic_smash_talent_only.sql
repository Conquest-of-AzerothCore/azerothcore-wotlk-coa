-- Primalist Seismic Smash rank 1 (300693) is the Mountain King capstone talent (CharacterAdvancement entry 7498,
-- 23 points invested in the tab), not a trainer spell. rev_20261027_61 taught it at the Primalist class trainer
-- (900031), which let any level 59 Primalist skip the capstone and made every switch to Mountain King refuse its
-- build. Ranks 2-4 keep their trainer rows and still require rank 1 from the talent.
DELETE FROM `trainer_spell` WHERE `TrainerId` = 900031 AND `SpellId` = 300693;
