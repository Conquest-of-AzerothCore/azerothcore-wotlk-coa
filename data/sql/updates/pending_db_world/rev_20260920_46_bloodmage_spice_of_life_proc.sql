-- Spice of Life (680823): "Your periodic damage and healing now has a $h% chance to grant a stack of
-- Pooled Vitality." Effect 0 is aura 42 (SPELL_AURA_PROC_TRIGGER_SPELL) on Pooled Vitality 680687, the
-- Bloodmage's registered custom resource (src/server/game/Spells/AscensionPooledVitality.h,
-- modules/mod-ascension-compat/src/AscensionCustomResourceData.h; StackAmount 10, TargetA 1 = caster, so
-- casting it grants one stack). But Spell.dbc gives 680823 ProcFlags 0 and no `spell_proc` row existed, so
-- SpellMgr::LoadSpellProcs skipped the record ("Skip if no proc flags in DBC") and
-- Aura::GetProcEffectMask returned a zero mask: the aura could never fire. Same reasoning and shape as
-- rev_20260917_80_bloodmage_blood_rush_proc, which fixes the same defect for the same kind of periodic
-- tooltip.
--
-- `ProcFlags` 262144 is PROC_FLAG_DONE_PERIODIC alone - the tooltip says "your periodic damage and
-- healing", which is the caster's own ticks and nothing else. `SpellTypeMask` 3 is
-- PROC_SPELL_TYPE_DAMAGE | PROC_SPELL_TYPE_HEAL, the literal "damage and healing"; it keeps ticks that
-- neither damage nor heal out. `SpellPhaseMask` 2 (PROC_SPELL_PHASE_HIT) is required because
-- PROC_FLAG_DONE_PERIODIC is inside REQ_SPELL_PHASE_PROC_FLAG_MASK, and it is the phase the periodic proc
-- path uses (same value as rev_20260917_80). `HitMask` stays 0, which for a DONE proc defaults to
-- NORMAL | CRITICAL | ABSORB.
--
-- `Chance` 10 is the record's own ProcChance, which is also what the tooltip's $h renders.
-- `SpellFamilyName`/`SpellFamilyMask`/`SchoolMask` are 0: the tooltip names no ability and no school.
-- AttributesMask is 0 (PROC_ATTR_TRIGGERED_CAN_PROC not set): a periodic tick is delivered by the aura
-- itself, not by a helper spell cast as a triggered effect of something else. `Cooldown` is 0: unlike
-- Blood Rush, this tooltip states no internal cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` = 680823;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680823, 0, 0, 0, 0, 0, 262144, 3, 2, 0, 0, 0, 0, 10, 0, 0);
