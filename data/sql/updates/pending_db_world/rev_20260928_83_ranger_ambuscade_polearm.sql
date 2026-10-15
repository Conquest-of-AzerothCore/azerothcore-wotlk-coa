-- #2496 Ambuscade (705053): "... plus an additional 35% if you have a polearm equipped." The 10 sec
-- periodic helper 707887 carries EquippedItemClass/EquippedItemSubClassMask (polearm) but no
-- SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON/_OFF_HAND_WEAPON, so Spell::CheckItems never runs
-- Item::IsFitToSpellRequirements for it and the +35% bonus applied with any weapon equipped, or none.
-- Same shape as #3310 (rev_20260928_81); spell_ascension_ranger_polearm_gate is the shared script.
DELETE FROM `spell_script_names` WHERE `spell_id` = 707887 AND `ScriptName` = 'spell_ascension_ranger_polearm_gate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707887, 'spell_ascension_ranger_polearm_gate');
