-- Food Fit for Gnolls (255113) needs 8 Gnoll Food Supplies, one per Gnoll Food Barrel (gameobject 255062). The ten
-- barrels stand in pairs at five gnoll camps and are consumed when looted, but took 2 minutes to come back, so a
-- player waiting at one camp needed about 6 minutes, more with other players around. They now respawn in 60 s, the
-- usual time for CoA quest chests.
UPDATE `gameobject` SET `spawntimesecs` = 60 WHERE `id` = 255062;
