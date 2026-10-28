-- Thirst (706613) description: "Generates $/10;681202s1 Rage and then increases the health costs of your
-- spells by $s1%...and increases their damage by $s3%. Stacks $u times." All three of 706613's own effects
-- are aura 108 SPELL_AURA_ADD_PCT_MODIFIER (health cost, crit, damage); none energizes Rage, and
-- EffectTriggerSpell is 0 on every effect, so the generic proc/trigger pipeline never touched 681202
-- "Thirst SLS2" (SPELL_EFFECT_ENERGIZE, EffectBasePoints 49 + DieSides 1 = 50, MiscValue 1 = POWER_RAGE,
-- EffectRealPointsPerLevel 0 - the raw internal amount the description's "$/10;681202s1" divides by 10 for
-- display, per Unit.cpp's 10x internal Rage storage). `grep -rn "681202"` across src/server/coa and
-- pending_db_world returns nothing. This needs a native per-stack-gain hook (a `spell_proc` row cannot
-- distinguish "a new stack was granted" from "the aura refreshed at its existing/max stack"), matching
-- aura_ascension_bloodmage_thirst_rage in AscensionResourceTalents.cpp, registered alongside the existing
-- aura_ascension_resource_talent_refresh binding for the same spell.
DELETE FROM `spell_script_names` WHERE `spell_id` = 706613
    AND `ScriptName` = 'aura_ascension_bloodmage_thirst_rage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(706613, 'aura_ascension_bloodmage_thirst_rage');
