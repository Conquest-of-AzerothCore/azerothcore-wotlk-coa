-- Templar Faith 706466 ("High Threat" Holy) promises the tooltip convention rev_20261026_20 gave every other
-- "High Threat" rank (pctMod = 1 + value/100), but it was missed because its threat comes from a flat
-- SPELL_EFFECT_THREAT (100) rather than an EffectBasePoints percentage, so it carried no spell_threat row at all.
DELETE FROM `spell_threat` WHERE `entry` IN (706466);
INSERT INTO `spell_threat` (`entry`, `flatMod`, `pctMod`, `apPctMod`) VALUES
(706466, 0, 2, 0);
