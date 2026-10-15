-- Cursed Blood (681792): "Increases the damage dealt and spell power scaling of Bloodbolt, Bloodmoon Blast
-- and Crimson Tide by $s2%. In addition, damage dealt by Bloodbolt now reduces all resistances by
-- ${-($803722m1+$803722ppl1)} and increases the target's Magic damage taken by $803722s2% for $803722d."
-- The two modifier clauses already work: effects 1 and 2 are aura 108 SPELL_AURA_ADD_PCT_MODIFIER,
-- BasePoints 19, with EffectSpellClassMask (0, 139264, 0) and (16384, 0, 0), handled natively in
-- AuraEffect::CalculateSpellMod. The debuff clause was dead: effect 0 is
-- SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) on Cursed Blood 803722, but Spell.dbc gives 681792 ProcFlags 0
-- and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs generated no entry and
-- Aura::GetProcEffectMask returned 0.
-- 803722 itself is native and correct: aura 22 SPELL_AURA_MOD_RESISTANCE, BasePoints -21 with
-- RealPointsPerLevel -1.14583, MiscValue 126 (all magic schools), plus aura 87
-- SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN BasePoints 1 (+2%), both TargetA 6 (enemy), StackAmount 1.
-- The row is scoped to Bloodbolt by SpellFamilyName 26 and SpellFamilyMask1 131072, the SpellFamilyFlags
-- (0, 131072, 0) that Spell.dbc gives all eight Bloodbolt ranks (578304, 578305, 804685, 806928-806932) and
-- no other family-26 record. ProcFlags 65536 = PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG: Bloodbolt is
-- DmgClass 1 (magic) and harmful, which is the only event bit its damage can raise.
-- SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) for "damage dealt", SpellPhaseMask 2 (HIT), HitMask 0 so the
-- done-proc defaults NORMAL | CRITICAL | ABSORB apply. Chance 0 defers to the record's own ProcChance 100.
-- AttributesMask 0: Bloodbolt is cast by the player, not triggered, so PROC_ATTR_TRIGGERED_CAN_PROC would
-- only widen the row for no gain. The proc path casts 803722 at eventInfo.GetActionTarget(), the enemy
-- Bloodbolt just hit, so no script is needed to place the debuff.
DELETE FROM `spell_proc` WHERE `SpellId` = 681792;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(681792, 0, 26, 0, 131072, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0);
