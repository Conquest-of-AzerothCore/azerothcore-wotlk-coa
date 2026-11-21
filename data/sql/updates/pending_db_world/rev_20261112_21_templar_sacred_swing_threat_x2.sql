-- Sacred Swing reads "High Threat Weapon Damage". Owner ruling 2026-11-12 (Q-r3a-1): "High Threat" in a Templar
-- tooltip means threat x2, as Faith 706466 and Armor of Faith 801546 already have. The 301061 flat part stays.
DELETE FROM `spell_threat` WHERE `entry` IN (705293, 748501, 748502, 748503, 748504, 572769);
INSERT INTO `spell_threat` (`entry`, `flatMod`, `pctMod`, `apPctMod`) VALUES
(705293, 0, 2, 0),
(748501, 0, 2, 0),
(748502, 0, 2, 0),
(748503, 0, 2, 0),
(748504, 0, 2, 0),
(572769, 0, 2, 0);
