-- Judgement of The Three Hammers (280210): "...dealing direct damage with spells and abilities has a
-- $h% chance to hurl 3 hammers over $280211d..." A native SPELL_AURA_PROC_TRIGGER_SPELL aura
-- (EffectApplyAuraName[0]=42, EffectTriggerSpell[0]=280211) with raw DBC ProcChance=20, ProcFlags=0,
-- ProcCharges=0. With no spell_proc row, SpellMgr::LoadSpellProcs never fills mSpellProcMap for it,
-- so Aura::GetProcEffectMask always returns 0 and the aura never triggers, regardless of caster.
-- ProcFlags 69972 = 4 + 16 + 64 + 256 + 4096 + 65536: every "direct damage done" flag (melee and
-- ranged auto attacks, melee/ranged-class spells, and none/magic-class negative spells), matching
-- "dealing direct damage with spells and abilities" without the periodic (DoT tick) flag, consistent
-- with the "direct damage" wording. HitMask 0 keeps the default done-proc set (normal, critical,
-- absorb), so any landed hit counts. SpellTypeMask 1 (damage) and SpellPhaseMask 2 (hit) match the
-- pattern used for Hammer of Life (rev_20260916_72) and Dark Sigil (rev_20260920_85). Chance is the
-- record's own ProcChance (20); Cooldown/Charges stay 0, matching ProcCooldown/ProcCharges.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 280210;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(280210, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 20, 0, 0);
COMMIT;
