-- Ratchet: the Outlaw's Contract Board was imported without a facing and turned along the street; it now faces the
-- road to the Crossroads. The level 60 Worldforged String of Ears stood 0.33 yd into the ground: it keeps its
-- Ascension map pin position on the ground, facing the same way.
UPDATE `gameobject` SET `orientation` = 1.5708, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.707107,
    `rotation3` = 0.707107 WHERE `guid` = 1804481 AND `id` = 1804480;
UPDATE `gameobject` SET `position_z` = 7.371, `orientation` = 1.5708, `rotation0` = 0, `rotation1` = 0,
    `rotation2` = 0.707107, `rotation3` = 0.707107 WHERE `guid` = 6975031 AND `id` = 1345143;
