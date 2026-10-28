-- Ironaya (Uldaman, entry 7228) carries base unit_flags 33554434 = 0x02000002
-- (UNIT_FLAG_NON_ATTACKABLE 0x2 | UNIT_FLAG_NOT_SELECTABLE 0x02000000). mod-destiny-weaver's
-- ViewableCreature() reads the static template/spawn unit_flags, not the live flags a SmartAI
-- RemoveFlag action toggles once the Keystone puzzle is solved (smart_scripts.sql:38166), so
-- Ironaya stays permanently excluded from per-viewer dungeon level scaling and keeps her
-- authored level 40 for every party regardless of their own level (#9074, #9076, #9576).
-- GO_IRONAYA_SEAL_DOOR already gates physical access to her chamber independently
-- (instance_uldaman.cpp DATA_IRONAYA_DOORS), and every other Uldaman boss (Archaedas, Grimlok,
-- Revelosh, Ancient Stone Keeper) spawns with unit_flags = 0, so clearing these two bits here
-- only removes a redundant, scaling-breaking exemption; it does not change who can reach her.
-- The Keystone's own RemoveFlag action on these bits becomes a harmless no-op.

UPDATE `creature_template` SET `unit_flags` = `unit_flags` & ~0x02000002 WHERE `entry` = 7228;
