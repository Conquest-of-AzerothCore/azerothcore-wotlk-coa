-- Eliza's Pendant's Gravechill debuff reads "Movement speed slowed by 0%" in the client because the Spell.dbc
-- ToolTip of 303051/312850/316850/320850 references $303019s2 / $312813s2 / $320813s2, the second effect of
-- the old "Run 'em down!" helper, whose effect slot is empty in every rank - the aura's own value is effect 0.
--
-- The CoA server component already ships client Spell text through `coa_client_spell_description`
-- (LoadClientSpellDescriptions -> the SMSG_PATCH_SPELL stream at login), so the tooltip can be corrected
-- without touching the client tables: give each rank a self-reference, the same effect value its own equip
-- dummy's tooltip quotes ($303051s1 / $312850s1 / $316850s1 / $320850s1), and the matching self-referenced
-- description. Ids without a row keep their client text.
DELETE FROM `coa_client_spell_description` WHERE `ID` IN (303051, 312850, 316850, 320850);
INSERT INTO `coa_client_spell_description` (`ID`, `Description`, `ToolTip`) VALUES
(303051, 'Reduces a creatures movement speed by $s1% for $d.', 'Movement speed slowed by $s1%.'),
(312850, 'Reduces a creatures movement speed by $s1% for $d.', 'Movement speed slowed by $s1%.'),
(316850, 'Reduces a creatures movement speed by $s1% for $d.', 'Movement speed slowed by $s1%.'),
(320850, 'Reduces a creatures movement speed by $s1% for $d.', 'Movement speed slowed by $s1%.');
