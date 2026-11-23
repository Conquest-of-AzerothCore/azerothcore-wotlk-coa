-- Crushing Impact 270706: Battle Charge 270697 ("This uses Charge modifiers") applies it like Charge 100/6178/11578
UPDATE `coa_mystic_enchant_proc` SET `spells` = '100 6178 11578 270697'
WHERE `enchant_spell` = 270706 AND `effect` = 0 AND `rule` = 0;
