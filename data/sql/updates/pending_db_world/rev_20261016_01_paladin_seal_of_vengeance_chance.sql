-- Seal of Vengeance's spell_proc row leaves Chance at 0 so the loader falls back to the DBC proc chance, which is
-- 100 in stock 3.3.5 but 0 in the CoA Spell.dbc. The seal never applied Holy Vengeance or dealt its Holy damage (#7832).
UPDATE `spell_proc` SET `Chance` = 100 WHERE `SpellId` = 31801;
