-- Sacred Swing reads "High Threat Weapon Damage" but has no spell_threat row, so its damage generates 1.0x
-- threat plus only the small flat from its 301061 slow trigger. Give the full rank chain the Revenge
-- multiplier (2.25x, the avoid-gated tank-strike precedent); the flat component already comes from 301061.
DELETE FROM `spell_threat` WHERE `entry` IN (705293, 748501, 748502, 748503, 748504, 572769);
INSERT INTO `spell_threat` (`entry`, `flatMod`, `pctMod`, `apPctMod`) VALUES
(705293, 0, 2.25, 0),
(748501, 0, 2.25, 0),
(748502, 0, 2.25, 0),
(748503, 0, 2.25, 0),
(748504, 0, 2.25, 0),
(572769, 0, 2.25, 0);
