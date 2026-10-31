-- Pooled Vitality (680687) at ten stacks and the Cursed Form marker (802877) keep the Empowered indicator (524899).
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_bloodmage_empowered_indicator';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680687, 'aura_ascension_bloodmage_empowered_indicator'),
(802877, 'aura_ascension_bloodmage_empowered_indicator');
