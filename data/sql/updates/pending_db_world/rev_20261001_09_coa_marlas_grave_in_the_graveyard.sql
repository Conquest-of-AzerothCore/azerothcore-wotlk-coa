-- Marla's Grave 178090 (Marla's Last Wish 6395) goes back to its stock spot in the Deathknell graveyard, on the
-- grave frame among the tombstones (DUSKWOODGRAVEFRAME doodad 0.2 yd away), as CoA footage shows it.
-- rev_20260926_10 had moved it to the client's track point ST6961, which lies on the road by Deathguard
-- Randolph (issues 5927, 5975). Its map marker moves with it.
UPDATE `gameobject` SET `position_x` = 1876.89, `position_y` = 1624.95, `position_z` = 94.7472, `orientation` = -1.8675,
    `rotation2` = -0.803856, `rotation3` = 0.594824 WHERE `guid` = 45015 AND `id` = 178090;
UPDATE `quest_poi_points` SET `X` = 1877, `Y` = 1625 WHERE `QuestID` = 6395 AND `Idx1` = 0 AND `Idx2` = 0;
