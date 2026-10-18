-- Animated Blood leech (504711): "healing you for $504711s1% of the damage
-- dealt" never healed. The record carries a lone aura 354 effect with
-- ProcFlags 0 and no `spell_proc` row, so no proc entry existed, and no
-- AuraScript was bound to it: same inert-aura disease as Apotheosis
-- (#7430). The amalgam now carries this aura from summon (see
-- npc_ascension_animated_blood) and strikes with Blood Strike 589023 on
-- a 3 s timer on top of scaled melee. Proc on every damage-done flag
-- (332116, mirroring the Blood Moon row), Chance 100, unrestricted
-- family/masks: whatever the pet lands converts at the record's own
-- 50% (BasePoints 49 + DieSides 1) through
-- aura_ascension_bloodmage_animated_blood_leech, bound below, which pays
-- the owner directly.
DELETE FROM `spell_proc` WHERE `SpellId` = 504711;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504711, 0, 0, 0, 0, 0, 332116, 1, 2, 0, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 504711 AND `ScriptName` = 'aura_ascension_bloodmage_animated_blood_leech';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(504711, 'aura_ascension_bloodmage_animated_blood_leech');
