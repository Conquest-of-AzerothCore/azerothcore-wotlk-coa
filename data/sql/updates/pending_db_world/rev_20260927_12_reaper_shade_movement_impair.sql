-- Shade 573038: the aura removes all movement impairing effects per its tooltip, but its DBC effects
-- (Transform, delayed trigger into Underwalk 800797, Mod Stealth) never call it. Bind
-- aura_ascension_reaper_shade to strip existing snares/roots when the Transform effect (EFFECT_0) applies.
DELETE FROM `spell_script_names` WHERE `spell_id` = 573038
  AND `ScriptName` = 'aura_ascension_reaper_shade';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(573038, 'aura_ascension_reaper_shade');
