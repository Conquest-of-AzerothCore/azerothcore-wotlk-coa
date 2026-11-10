-- Road to De Other Side (map 937): Venomous Breath of the Gutdevourers hit well outside its cone graphic. Its hit spell
-- 256908 targets TARGET_UNIT_CONE_ENEMY_54, which the core reads as 54 degrees; the client draws the cone with
-- spells\spell_evoker_firebreath_cone.m2 at a fixed 0.3 (SpellVisualEffectName 589816, min and max scale 0.3), whose
-- texture outlines about 26 degrees from an apex 2 yards behind the caster to 12 yards in front. 30 degrees from the
-- caster keeps every hit inside those lines; the reach stays the DBC radius of 11 yards (SpellRadius 42).
DELETE FROM `spell_cone` WHERE `ID` = 256908;
INSERT INTO `spell_cone` (`ID`, `ConeDegrees`) VALUES (256908, 30);
