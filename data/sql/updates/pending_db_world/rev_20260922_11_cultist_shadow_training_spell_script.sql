-- aura_ascension_cultist_shadow_training (AscensionCultistAbilities.cpp) is a database-bound
-- AuraScript (GenericSpellAndAuraScriptLoader::IsDatabaseBound() == true). Registering it in C++
-- only adds it to the script registry; without this spell_script_names row ObjectMgr never binds
-- it to 805607, so its DoEffectCalcSpellMod hook is never installed and Gaze of C'Thun's heal
-- never receives the +100% modifier.
DELETE FROM `spell_script_names` WHERE `spell_id` = 805607 AND `ScriptName` = 'aura_ascension_cultist_shadow_training';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (805607, 'aura_ascension_cultist_shadow_training');
