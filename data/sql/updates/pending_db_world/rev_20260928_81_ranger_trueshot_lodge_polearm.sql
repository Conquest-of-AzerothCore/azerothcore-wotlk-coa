-- #3310 Trueshot Lodge Training (803113/803855): "While wielding a polearm, the damage of your bleed effects
-- is increased by ...%." The 10 sec periodic helper 803854 carries EquippedItemClass/EquippedItemSubClassMask
-- (polearm) but no SPELL_ATTR3_REQUIRES_MAIN_HAND_WEAPON/_OFF_HAND_WEAPON, so Spell::CheckItems never runs
-- Item::IsFitToSpellRequirements for it and the bleed bonus applied with any weapon equipped, or none.
-- spell_ascension_ranger_polearm_gate (src/server/coa/AscensionRangerSecondary.cpp) gates the cast
-- with the same weapon-fit check natively used for the ATTR3 case. The same inert-gate shape recurs on
-- other Ranger helpers (707887 #2496, 712481 #3159), so the script is generic and shared across all three.
DELETE FROM `spell_script_names` WHERE `spell_id` = 803854 AND `ScriptName` = 'spell_ascension_ranger_polearm_gate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(803854, 'spell_ascension_ranger_polearm_gate');
