-- TheSepulchercoa.awe -> AzerothCore creature placements
-- Generated from uploaded AWE project; review GUID matches before importing.
-- Import into the WORLD database (coa_bots_world), NOT characters/auth.
START TRANSACTION;

-- Move Apothecary Renferrel (GUID 17612, entry 1937)
UPDATE creature SET position_x=516.173391317, position_y=1625.8584609, position_z=128.01, orientation=4.37993 WHERE guid=17612 AND id=1937 AND map=0;

-- Move Dalar Dawnweaver (GUID 17613, entry 1938)
UPDATE creature SET position_x=564.860741884, position_y=1597.161045824, position_z=131.427609175, orientation=5.116269285 WHERE guid=17613 AND id=1938 AND map=0;

-- Move Deathguard Podrig (GUID 17867, entry 6389)
UPDATE creature SET position_x=493.114953717, position_y=1548.284913653, position_z=128.069268014, orientation=4.47532352 WHERE guid=17867 AND id=6389 AND map=0;

-- Move Silverpine Deathguard (GUID 17870, entry 7489)
UPDATE creature SET position_x=486.659172962, position_y=1573.544531635, position_z=127.031945472, orientation=3.530967624 WHERE guid=17870 AND id=7489 AND map=0;

-- Move Spirit Healer (GUID 40542, entry 6491)
UPDATE creature SET position_x=512.710528097, position_y=1578.498085961, position_z=127.546553262, orientation=3.230043822 WHERE guid=40542 AND id=6491 AND map=0;

-- Move Mura Runetotem (GUID 17633, entry 8385)
UPDATE creature SET position_x=458.772535061, position_y=1615.478301005, position_z=140.73451376, orientation=4.400502611 WHERE guid=17633 AND id=8385 AND map=0;

-- Add Silverpine Deathguard (new GUID 9970191, entry 7489)
-- If this GUID already exists, the INSERT will skip it; check the database before import.
INSERT INTO creature (guid, id, map, spawnMask, phaseMask, position_x, position_y, position_z, orientation, spawntimesecs) SELECT 9970191, 7489, 0, 1, 1, 485.838074527, 1589.764042081, 125.947929417, 3.530967624, 275 WHERE NOT EXISTS (SELECT 1 FROM creature WHERE guid=9970191);

COMMIT;
-- Check UPDATE affected-row counts and verify 7 GUIDs after importing.
-- Custom appearance/equipment of the new spawn is not included here.
