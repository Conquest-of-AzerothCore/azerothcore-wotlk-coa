-- Clients with Ascension's HD patch crash (0x0082EFEB, last call GetCollisionFacets utherstatue.m2) when a CoA Templar
-- statue comes into view: display 6815's HD model UtherStatue.M2 in patch-Z.MPQ has malformed collision (3,494
-- indices, not a multiple of three), so building the object's collision reads past its data. A Witch Doctor logging in
-- beside the Shadowglen statue crashed on every login. The statues take the Scarlet Monastery paladin statue (display
-- 6820), whose collision is sound in every copy, as the Deathknell Hidden Statue already does.
UPDATE `gameobject_template` SET `displayId` = 6820 WHERE `displayId` = 6815
    AND `entry` IN (9301105, 9301155, 9301204, 9301301, 9301355);
