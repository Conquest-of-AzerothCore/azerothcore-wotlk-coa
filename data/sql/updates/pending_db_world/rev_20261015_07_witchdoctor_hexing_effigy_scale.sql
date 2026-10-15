-- Hexing Effigy 50120 uses the world doodad 8tr_ancientblood_headstatue01.m2 (display 412985), which the client draws
-- at world size. The CoA alpha creature cache records the creature at scale 0.2, but the statue still towers over the
-- player at that size, so the summon is stepped down to 0.07, the size the class's other stationary totems occupy.
-- Swift Idol 50118 and Shadow Effigy 50119 keep their captured 1.0.
UPDATE `creature_template_model` SET `DisplayScale` = 0.07 WHERE `CreatureID` = 50120 AND `CreatureDisplayID` = 412985;
