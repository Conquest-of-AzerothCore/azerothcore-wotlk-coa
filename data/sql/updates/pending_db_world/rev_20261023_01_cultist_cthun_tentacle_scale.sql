-- CoA #8637 Tentacle of C'Thun (801153): the summon (50272) uses display 15788 (Eye Stalk of Kathune, 7.12 yd tall at
-- display scale 1). Template scale 0.7 made a 4.98 yd tentacle, the largest of the Old God tentacles; N'Zoth (28813 at
-- 0.5) stands 4.07 yd and Y'Shaarj (28814 at 0.15, #5319) stands 4.44 yd. 0.45 makes this one 3.20 yd, the size the
-- in-game pass settled on after 0.6 (4.27 yd) and 0.55 (3.91 yd).
UPDATE `creature_template_model` SET `DisplayScale` = 0.45 WHERE `CreatureID` = 50272 AND `Idx` = 0;
