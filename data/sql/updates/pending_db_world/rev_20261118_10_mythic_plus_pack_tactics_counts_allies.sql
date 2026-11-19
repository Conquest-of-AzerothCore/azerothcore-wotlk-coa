-- Mythic+ affix Pack Tactics (80054) links Pack Tactics 80055, a 10 yd friendly area aura worth 11% damage dealt and
-- 8% less damage taken. Its owner no longer counts itself, as with Horde: a player gets one 80055 per nearby ally, at
-- most four in a party of five, against the 35% / 33% of 80054.
DELETE FROM `spell_script_names` WHERE `spell_id` = 80055 AND `ScriptName` = 'spell_coa_mythic_horde';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (80055, 'spell_coa_mythic_horde');
