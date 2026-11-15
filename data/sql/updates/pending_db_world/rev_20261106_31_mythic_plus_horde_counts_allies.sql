-- Mythic+ affix Horde (80046) links Horde 80047, a 5 yd friendly area aura worth 1% damage. Its owner no longer
-- counts itself, so an enemy gets one 80047 per nearby ally and none when alone (#11453).
DELETE FROM `spell_script_names` WHERE `spell_id` = 80047 AND `ScriptName` = 'spell_coa_mythic_horde';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (80047, 'spell_coa_mythic_horde');
