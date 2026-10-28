DELETE FROM `spell_script_names` WHERE `spell_id` = 705087 AND `ScriptName` = 'aura_ascension_ranger_pilfering';
DELETE FROM `spell_script_names` WHERE `ScriptName` IN
    ('aura_ascension_ranger_dirty_blades', 'spell_ascension_ranger_dirty_blades');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680276, 'aura_ascension_ranger_dirty_blades'),
(520571, 'spell_ascension_ranger_dirty_blades');

DELETE FROM `spell_proc` WHERE `SpellId` IN (680276, 705087);
INSERT INTO `spell_proc`
    (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`)
VALUES
(680276, 4, 0, 0, 0, 0, 0);
