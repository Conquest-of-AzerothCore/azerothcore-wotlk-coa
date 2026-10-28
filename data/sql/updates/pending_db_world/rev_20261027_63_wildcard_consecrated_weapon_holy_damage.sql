-- Consecrated Weapon 200809-200817 applies hidden buff 200819-200827 (DBC ProcFlags 0x14, EFFECT_0 SPELL_AURA_DUMMY,
-- min=max additional Holy damage scaled by weapon speed in its effect amount), but had no script, so auto attacks
-- and melee abilities dealt no bonus Holy damage even though the SP/AP bonuses (effects 1/2) already worked.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_wildcard_consecrated_weapon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(200819, 'aura_wildcard_consecrated_weapon'),
(200820, 'aura_wildcard_consecrated_weapon'),
(200821, 'aura_wildcard_consecrated_weapon'),
(200822, 'aura_wildcard_consecrated_weapon'),
(200823, 'aura_wildcard_consecrated_weapon'),
(200824, 'aura_wildcard_consecrated_weapon'),
(200825, 'aura_wildcard_consecrated_weapon'),
(200826, 'aura_wildcard_consecrated_weapon'),
(200827, 'aura_wildcard_consecrated_weapon');
