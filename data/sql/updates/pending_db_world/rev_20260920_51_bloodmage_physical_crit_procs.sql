-- Enraging Wounds (300978) and Relentless (704652): two Bloodmage level-40 passives gated on physical
-- critical strikes. Both carry a single SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) effect, Spell.dbc
-- ProcFlags 0 and no `spell_proc` row, so SpellMgr::LoadSpellProcs generates no fallback entry
-- ("Skip if no proc flags in DBC"), Aura::GetProcEffectMask returns 0 and the auras never fire.
--
-- Enraging Wounds (300978): "Melee critical strikes now leech ... health from the target, scaling with your
-- Stamina." Effect 0 is aura 42 on Enraging Wound 560589, a native SPELL_EFFECT_HEALTH_LEECH (9) with
-- BasePoints 95, SchoolMask 32 (Shadow), DmgClass 2 and TargetA 6 (enemy), already registered for scaling
-- in AscensionScalingBaseData.h. Note that 560589 carries CasterAuraSpell 800157 (Eternal Curse), so the
-- leech only lands while the Bloodmage is in Cursed Form; that gate is the record's, not this row's.
-- ProcFlags 20 = PROC_FLAG_DONE_MELEE_AUTO_ATTACK (0x4) | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS (0x10):
-- exactly "melee", white swings and melee-damage-class abilities, nothing ranged, magic or periodic.
-- SpellTypeMask 1 (PROC_SPELL_TYPE_DAMAGE), SpellPhaseMask 2 (HIT), HitMask 2 (PROC_HIT_CRITICAL).
--
-- Relentless (704652): "Physical critical strikes now reduce the cooldown of Aortic Assault by 1 sec and
-- grant you Relentless." Effect 0 is aura 42 on Relentless 807357. Same ProcFlags 20 and HitMask 2 as
-- above: Aortic Assault is DmgClass 2 and the tooltip says "Physical critical strikes".
--
-- Relentless 807357 (the buff itself) carries a second dead proc: besides its two native aura 108
-- modifiers scoped to Aortic Assault (EffectSpellClassMask (2048,0,0)), its effect 2 is aura 42 on 807359,
-- a SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION (177) with BasePoints 1999 and MiscValue 800772 - the
-- tooltip's "each strike now extends the duration of Taldaram's Torment by 2 sec". 807357 also has
-- ProcFlags 0 and no row, so that clause was dead too. The event that is "a strike" is Aortic Assault's own
-- periodic child 806502 "Aortic Assault" (Deals $s1 Physical Damage), which Spell.dbc gives SpellFamilyName
-- 26 and SpellFamilyFlags (0, 4194304, 0) - not the channel 806212's (2048, 0, 0). Hence
-- SpellFamilyName 26 with SpellFamilyMask1 4194304 and ProcFlags 16 (PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS;
-- 806502 is DmgClass 2). Only one other family-26 record shares that bit, Clotting 806214 (0, 5242880, 0),
-- Aortic Assault's own closing burst, and no finer bit exists to separate them. 806502 is cast as a
-- triggered spell by 806212's aura 227, but it carries SPELL_ATTR3_NOT_A_PROC (AttributesEx3 0x200), which
-- Aura::GetProcEffectMask accepts without PROC_ATTR_TRIGGERED_CAN_PROC, so AttributesMask stays 0 here.
-- 807359's own TargetA is 6 (enemy) and the proc path hands it eventInfo.GetActionTarget(), so the
-- extension lands on the struck enemy's Taldaram's Torment, which is where the DoT lives.
--
-- The tooltip's remaining clause, "reduce the cooldown of Aortic Assault by $/1000;807358s1 sec", is
-- carried by Relentless 807358 - a single SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN (165), BasePoints -1001,
-- MiscValue 806212 - but nothing casts 807358: it is not the EffectTriggerSpell of any effect on 704652 or
-- 807357, and it appears nowhere in `src/`, `modules/` or `data/sql/`. The `spell_linked_spell` row below
-- gives it its caster: type 0 (SPELL_LINK_CAST) fires 807358 whenever 807357 is cast, i.e. on the same
-- critical strike that grants the buff, which is what the tooltip describes as one event.
--
-- Chance stays 0 in both rows so the records' own ProcChance (100) is used, per
-- rev_20260919_20_coa_proc_chance_parity.sql.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300978, 704652, 807357);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300978, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(704652, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(807357, 0, 26, 0, 4194304, 0, 16, 1, 2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 807357 AND `spell_effect` = 807358;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(807357, 807358, 0, 'Relentless - cast the orphaned Aortic Assault cooldown reduction with the buff');
