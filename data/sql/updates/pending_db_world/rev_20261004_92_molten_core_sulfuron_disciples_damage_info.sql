-- Sulfuron's disciples' Shadow Bolts (Cull the Destroyer 2105961, Proxima the Opressor 2105957, Ebon the
-- Cruel 2105959) deal their DBC placeholder damage (base points 1, about 2 per hit) because no
-- coa_spell_damage_info row binds them to real damage. Spell.dbc carries the family for them:
-- "Harbinger Priests - Damage Info" 2105950-2105953 (D0..D3, base points 1600/2128/2656/3200), whose
-- description reads "Sulfuron Harbinger's Priests pull their base spells BASE DAMAGE from this Aura".
-- The recorded hits (four Sulfuron pulls, 2026-05-28 to 2026-08-23) have per-pull medians of 1194-2286
-- for Cull (50+ hits per pull), no crits and a 5250 maximum, the same order as the family; the pulls'
-- difficulty is not recorded.

DELETE FROM `coa_spell_damage_info` WHERE `spell_id` IN (2105957, 2105959, 2105961);
INSERT INTO `coa_spell_damage_info` (`spell_id`, `info_d0`, `info_d1`, `info_d2`, `info_d3`, `comment`) VALUES
(2105957, 2105950, 2105951, 2105952, 2105953, 'Proxima the Opressor Shadow Bolt'),
(2105959, 2105950, 2105951, 2105952, 2105953, 'Ebon the Cruel Shadow Bolt'),
(2105961, 2105950, 2105951, 2105952, 2105953, 'Cull the Destroyer Shadow Bolt');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105957, 2105959, 2105961)
  AND `ScriptName` = 'spell_coa_damage_info_hit';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105957, 'spell_coa_damage_info_hit'),
(2105959, 'spell_coa_damage_info_hit'),
(2105961, 'spell_coa_damage_info_hit');
