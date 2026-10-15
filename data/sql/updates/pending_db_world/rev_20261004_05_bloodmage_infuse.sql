-- Infuse (#509).
--
-- 681403 Infuse applies a dummy aura (effect 0, TriggerSpell 681404) plus a SCHOOL_ABSORB
-- effect (effect 1) that doubles as the stored-damage pool. aura_ascension_bloodmage_infuse
-- unleashes the pool as 681404 when the 10 second debuff expires, and
-- bloodmage_infuse_accumulation (a UnitScript, no assignment needed) accumulates 10% of the
-- damage the caster's group deals to the target, capped at three times the caster's health, and
-- spends the pool absorbing healing done to the target.
--
-- Scripts registered from C++ are only attached when the object manager can resolve their name
-- through spell_script_names, so without this row the aura script never runs and Infuse expires
-- silently. The UnitScript alone cannot unleash the stored damage.

-- 681404's own ValueMultiplier/DamageMultiplier (0.15) make the plain damage pipeline deal less
-- than the stored amount it is cast with, so spell_ascension_bloodmage_infuse_unleash hands the
-- accumulated value straight to the hit, the same way Atherann's Anguish hands over its explosion.
DELETE FROM `spell_script_names` WHERE `spell_id` = 681403
    AND `ScriptName` = 'aura_ascension_bloodmage_infuse';
DELETE FROM `spell_script_names` WHERE `spell_id` = 681404
    AND `ScriptName` = 'spell_ascension_bloodmage_infuse_unleash';

-- Cruel Intent (#2336): "When you Lunge at an enemy you now strike them 3 times with auto attacks."
-- 704653 carries aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) with EffectTriggerSpell 707599 (Dark Intent's
-- SPELL_EFFECT_ADD_EXTRA_ATTACKS, BasePoints 2 + DieSides 1 = 3 extra auto attacks on the caster) but
-- Spell.dbc ProcFlags is 0 and no spell_proc row existed, so SpellMgr::LoadSpellProcs skipped it and
-- the aura never procced. Lunge 500126 is the only family-26 record carrying SpellFamilyFlags
-- (16777216, 0, 0); it has DmgClass NONE and is harmful, so ProcFlags 4096 =
-- PROC_FLAG_DONE_SPELL_NONE_DMG_CLASS_NEG - the same shape the merged Dark Intent heal row
-- (707622 in rev_20260920_61) uses for the same ability. SpellPhaseMask 2 (HIT) so the extra attacks
-- follow a landed Lunge; Chance 0 keeps the record's own ProcChance of 100.
DELETE FROM `spell_script_names` WHERE (`spell_id` = 681403
    AND `ScriptName` = 'aura_ascension_bloodmage_infuse')
    OR (`spell_id` = 681404 AND `ScriptName` = 'spell_ascension_bloodmage_infuse_unleash');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(681403, 'aura_ascension_bloodmage_infuse'),
(681404, 'spell_ascension_bloodmage_infuse_unleash');

DELETE FROM `spell_proc` WHERE `SpellId` = 704653;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(704653, 0, 26, 16777216, 0, 0, 4096, 0, 2, 0, 0, 0, 0, 0, 0, 0);
