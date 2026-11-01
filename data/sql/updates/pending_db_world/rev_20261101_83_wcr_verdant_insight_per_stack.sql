-- Verdant Insight (1586130): "Periodic healing from Lifebloom has a 3% chance per stack to trigger Omen of Clarity".
-- The rule rolled a flat 3% from the proc entry; the chance is now 3% per Lifebloom stack on the target, rolled by the
-- rule alone.
UPDATE `coa_mystic_enchant_proc` SET `chance_per_combo` = 3, `target_aura` = `spells`
WHERE `enchant_spell` = 1586130 AND `effect` = 0;
UPDATE `spell_proc` SET `Chance` = 100 WHERE `SpellId` = 1586130;
