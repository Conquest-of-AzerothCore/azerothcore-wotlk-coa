-- #3159 Polearm Craft (707885): "While a polearm is equipped, your chance to trigger your Weapon Crafts
-- and their damage dealt is increased by 25%." The 10 sec periodic helper 712481 carries
-- EquippedItemClass/EquippedItemSubClassMask (polearm) but no
-- SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON/_OFF_HAND_WEAPON, so Spell::CheckItems never runs
-- Item::IsFitToSpellRequirements for it and the bonus applied with any weapon equipped, or none.
-- Same shape as #3310 (rev_20260928_81); spell_ascension_ranger_polearm_gate is the shared script.
DELETE FROM `spell_script_names` WHERE `spell_id` = 712481 AND `ScriptName` = 'spell_ascension_ranger_polearm_gate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(712481, 'spell_ascension_ranger_polearm_gate');
