-- Sun Cleric class-audit batch, group D (radiance).
--
-- #2442 Champion's Arrival (704905): Spell.dbc's own SPELLMOD_DURATION classMask on 704905
-- matches the Chains of Light debuff (806697) but not Champion of the Sun (800612, whose own
-- SpellFamilyFlags_1 0x20 hits neither of 704905's two remaining classMask bits -- see
-- AscensionSunClericRadiance.cpp for the full evidence trail). aura_ascension_champion_of_the_sun_arrival
-- extends 800612's own duration by 5 sec on apply when the caster knows 704905.
--
-- #2452 Vindicator (704938 rank 1, 707773 rank 2): both ranks are contract-patched (see
-- ApplyAscensionSunClericRadianceContracts) onto SPELL_AURA_ASCENSION_MOD_IGNORE_ARMOR_PCT with
-- Glorious Execution's (800626) own family-flag classMask. aura_ascension_vindicator_vow_gate
-- keeps that cached amount at 0 unless Vow of the Valkyr (807749) is currently active, matching
-- "while Vow of the Valkyr is active" in the tooltip.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_champion_of_the_sun_arrival';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_vindicator_vow_gate';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(800612, 'aura_ascension_champion_of_the_sun_arrival'),
(704938, 'aura_ascension_vindicator_vow_gate'),
(707773, 'aura_ascension_vindicator_vow_gate'),
(807749, 'aura_ascension_vindicator_vow_gate');
