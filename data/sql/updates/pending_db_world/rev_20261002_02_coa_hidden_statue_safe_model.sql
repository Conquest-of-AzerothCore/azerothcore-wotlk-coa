-- Hidden Statue 9301257 (A Quiet Life 200081) crashed clients with HD patches (0x0082EFEB/0x0082F00C, last call
-- GetCollisionFacets on utherstatue.m2): HD patch-Z.MPQ's UtherStatue.M2 lists 3494 collision indices, not a
-- multiple of three, and 2544 face normals for 1164 faces, so building the object's collision reads past its
-- data. Blizzard's copy is sound, and as a world doodad the model is never asked for facets. The statue now uses
-- the Scarlet Monastery paladin statue (display 6820, statueHMpaladin.m2), whose collision is sound in both
-- copies, at life size: the quest text calls it a statue of a paladin.
UPDATE `gameobject_template` SET `displayId` = 6820, `size` = 1 WHERE `entry` = 9301257;
