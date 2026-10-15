-- Taldaram's Torment (802568-802573, 802580, 7 ranks, SpellFamilyName 26, EffectSpellClassMask4 131072):
-- "Corrupt an enemy's heart, causing them to bleed for $o1 Shadow damage over $d. Generates
-- $/10;582765s1 Rage every time it deals damage." Every rank's only effects are aura 3
-- SPELL_AURA_PERIODIC_DAMAGE (idx0, Amplitude 3000) and aura 308 SPELL_AURA_MOD_CRIT_CHANCE_FOR_CASTER
-- (idx1); EffectTriggerSpell is 0 on both, so the engine's generic proc/trigger pipeline never casts
-- 582765 "Energize Rage" (SPELL_EFFECT_ENERGIZE, EffectBasePoints 29 + DieSides 1 = 30, MiscValue 1 =
-- POWER_RAGE, EffectRealPointsPerLevel 0). Rage is stored internally at 10x the displayed value
-- (Unit.cpp:17038, `ModifyPower(POWER_RAGE, uint32(addRage * 10))`), and Spell::EffectEnergize passes a
-- DBC EffectBasePoints straight to EnergizeBySpell with no further scaling, so 582765's raw 30 is
-- already the internal amount for 3 displayed Rage; the description's "$/10;582765s1" only divides that
-- 30 by 10 for the tooltip's displayed number, a level-invariant constant (RealPointsPerLevel 0). A
-- `spell_proc` row cannot fix this: idx0 is periodic damage, not a proc-capable aura type. This needs a
-- native OnEffectPeriodic hook on the periodic-damage effect, energizing 30 (internal) Rage per tick,
-- matching aura_ascension_bloodmage_taldarams_torment in AscensionBloodmageTalents.cpp.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (802568, 802569, 802570, 802571, 802572, 802573, 802580)
    AND `ScriptName` = 'aura_ascension_bloodmage_taldarams_torment';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(802568, 'aura_ascension_bloodmage_taldarams_torment'),
(802569, 'aura_ascension_bloodmage_taldarams_torment'),
(802570, 'aura_ascension_bloodmage_taldarams_torment'),
(802571, 'aura_ascension_bloodmage_taldarams_torment'),
(802572, 'aura_ascension_bloodmage_taldarams_torment'),
(802573, 'aura_ascension_bloodmage_taldarams_torment'),
(802580, 'aura_ascension_bloodmage_taldarams_torment');
