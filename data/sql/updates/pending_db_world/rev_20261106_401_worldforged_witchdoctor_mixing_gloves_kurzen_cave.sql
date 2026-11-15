-- jealous-sound/azerothcore-wotlk-coa#11425: the Witchdoctor Mixing Gloves pickup (95745, guid 6941346) stands on the
-- terrain above Kurzen's cave. Return it to the stockpile spot a player recorded in game (former guid 6901168).
UPDATE `gameobject` SET `position_x` = -11397.557, `position_y` = -799.914, `position_z` = 14.972,
    `orientation` = 2.73909, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.979817, `rotation3` = 0.199897
WHERE `guid` = 6941346 AND `id` = 95745 AND `map` = 0
  AND `position_x` BETWEEN -11381.7 AND -11379.7 AND `position_y` BETWEEN -779.6 AND -777.6
  AND `position_z` BETWEEN 118 AND 119.2;
