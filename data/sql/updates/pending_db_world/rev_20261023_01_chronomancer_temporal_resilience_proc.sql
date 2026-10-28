-- Temporal Resilience (#6968, 680389 and ranks 536258-536263): the buff's second effect is aura 42
-- (SPELL_AURA_PROC_TRIGGER_SPELL) on Temporally Warped 536265, but Spell.dbc gives every rank ProcFlags 0
-- and no `spell_proc` row existed, so SpellMgr::LoadSpellProcs skipped the record and Aura::GetProcEffectMask
-- returned 0 for it: being struck could never apply the attack-speed debuff, matching the report's
-- "nothing in the logs".
--
-- ProcFlags 40 (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK 0x8 | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS 0x20) is the
-- engine's "an enemy strikes you" pair; it is the same value the shipped 557325 row uses for the same clause.
-- SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE) and SpellPhaseMask 2 (PROC_SPELL_PHASE_HIT) restrict the row to a
-- landed damaging strike; HitMask 3 admits normal and critical hits. Chance 0 defers to the record's own
-- ProcChance 100, and the tooltip names no internal cooldown, so Cooldown stays 0.
-- 536265's own EffectImplicitTargetA is 6 (TARGET_UNIT_TARGET_ENEMY), so the native proc dispatch applies it
-- to the striker rather than to the buff holder.
DELETE FROM `spell_proc` WHERE `SpellId` IN (680389, 536258, 536259, 536260, 536261, 536262, 536263);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680389, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(536258, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(536259, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(536260, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(536261, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(536262, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0),
(536263, 0, 0, 0, 0, 0, 40, 1, 2, 3, 0, 0, 0, 0, 0, 0);
