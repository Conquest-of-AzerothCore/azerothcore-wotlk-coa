-- Wildcard Nether Portal buff (290443): while it lasts, Shadow Bolt, Incinerate and Soul Fire summon the
-- portal's demons (aura_wildcard_nether_portal).
DELETE FROM `spell_script_names` WHERE `spell_id` = 290443 AND `ScriptName` = 'aura_wildcard_nether_portal';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (290443, 'aura_wildcard_nether_portal');

DELETE FROM `spell_proc` WHERE `SpellId` = 290443;
INSERT INTO `spell_proc` (`SpellId`, `SpellFamilyName`, `ProcFlags`, `SpellPhaseMask`, `Chance`, `AttributesMask`) VALUES
(290443, 5, 65536, 1, 100, 0);
