--
-- #10355: Righteous Vengeance's tooltip ("Direct critical strikes with spells and abilities...")
-- is unrestricted, but the effective spell_proc row for -53380 (all ranks) narrows the proc to
-- Judgement/Crusader Strike/Divine Storm via SpellFamilyMask0/1. Zero both masks so it procs off
-- any direct critical strike with spells and abilities, matching the tooltip.
UPDATE `spell_proc` SET `SpellFamilyMask0` = 0, `SpellFamilyMask1` = 0 WHERE `SpellId` = -53380;
