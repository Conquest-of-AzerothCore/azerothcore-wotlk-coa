-- Fierce Blow (975011) deals 100% weapon damage in the client data, and Ascension's combat logs show these bosses'
-- Fierce Blow landing for about one melee swing. The kit rows overrode effect 0 with 200, which doubled it on top of
-- the DamageModifier calibrated to the same logs (rev_20261005_20).
UPDATE `coa_dungeon_boss_kit` SET `base_points` = 0 WHERE `spell` = 975011 AND `base_points` = 200;
