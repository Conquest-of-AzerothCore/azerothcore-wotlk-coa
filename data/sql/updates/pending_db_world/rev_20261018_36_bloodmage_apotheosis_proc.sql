-- Bloodmage Apotheosis (804195) / Dark Feast (804203): "heal for all (Shadow)
-- damage you deal" did nothing at all. Both records carry a lone aura 354
-- effect, and aura 354 has no entry in AuraEffectHandler, no case in
-- AuraEffect::HandleProc and is not an isTriggerAura; on top of that both
-- records have ProcFlags 0 with no `spell_proc` row, so SpellMgr's
-- generator skipped them and Aura::GetProcEffectMask returned 0, and no
-- AuraScript was bound to either spell. The buff sat inert while rage
-- drained natively. This mirrors the shipped Blood Moon fix
-- (rev_20260920_86_bloodmage_blood_moon_proc.sql): proc on every
-- damage-done flag (332116 = melee/ranged auto, melee/ranged/none/magic
-- spell damage, periodic), SpellTypeMask 1 (damage), SpellPhaseMask 2
-- (hit), family/masks 0 (unrestricted, as the tooltips state), Chance 100
-- (no percentage stated). 804195 converts Shadow damage only, so its row
-- carries SchoolMask 32; 804203 converts all damage but only once per
-- second, so its row carries Cooldown 1000. The school gate and the heal
-- share live in aura_ascension_bloodmage_apotheosis, bound below, which
-- heals through each rank's own TriggerSpell (807857/807934, HEAL with
-- BasePoints 0, amount supplied by the caller).
DELETE FROM `spell_proc` WHERE `SpellId` IN (804195, 804203);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(804195, 32, 0, 0, 0, 0, 332116, 1, 2, 0, 0, 0, 0, 100, 0, 0),
(804203, 0, 0, 0, 0, 0, 332116, 1, 2, 0, 0, 0, 0, 100, 1000, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` IN (804195, 804203) AND `ScriptName` = 'aura_ascension_bloodmage_apotheosis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(804195, 'aura_ascension_bloodmage_apotheosis'),
(804203, 'aura_ascension_bloodmage_apotheosis');
