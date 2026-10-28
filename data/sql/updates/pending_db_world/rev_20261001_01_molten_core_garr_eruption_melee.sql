-- Firesworn's on-death Eruption (19497 Normal/Heroic, 350126 Mythic/Ascended sibling) carries a vanilla,
-- self-centered 100 yd radius (SpellRadius.dbc id 12, shared by unrelated spells, so left untouched) --
-- effectively the whole Garr room. spell_firesworn_eruption_melee_coa (boss_garr.cpp) trims the target
-- list down to melee range after the native area selection; this binds it to both difficulty ids.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (19497, 350126) AND `ScriptName` = 'spell_firesworn_eruption_melee_coa';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(19497, 'spell_firesworn_eruption_melee_coa'),
(350126, 'spell_firesworn_eruption_melee_coa');
