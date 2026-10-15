-- Aortic Aegis (806274): "Your Blood Veil now applies to the party members of the target."
-- Its single effect is SPELL_AURA_PROC_TRIGGER_SPELL (aura 42) on Aortic Aegis 806275, a single
-- SPELL_EFFECT_TRIGGER_SPELL (64) on Blood Veil 504263 with TargetA 33 (caster area party) and radius
-- index 11 - exactly the fan-out the tooltip describes. Spell.dbc gives 806274 ProcFlags 0 and no
-- `spell_proc` row existed, so SpellMgr::LoadSpellProcs generated no entry ("Skip if no proc flags in
-- DBC"), SpellMgr::GetSpellProcEntry returned nullptr and Aura::GetProcEffectMask returned 0.
-- The row is scoped to Blood Veil by SpellFamilyName 26 and SpellFamilyMask1 536870912, the
-- SpellFamilyFlags (0, 536870912, 0) that Spell.dbc gives all four Blood Veil ranks (504263, 572277-572279).
-- Two other family-26 records carry that bit - Bat Bite 802358 and Shadow Bat 802577, the Shadow Bat
-- summon's own spells - but they are damage records, and the positive-only ProcFlags below cannot match
-- them.
-- ProcFlags 16384 = PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS: Blood Veil is DmgClass 1 (magic) and a
-- beneficial absorb (two aura 69 effects), which is the bit Spell::DoAllEffectOnTarget picks for a positive
-- magic-damage-class spell. SpellPhaseMask 2 (HIT). SpellTypeMask 0 (unset) because an absorb application
-- carries neither damage nor heal information and therefore reports PROC_SPELL_TYPE_NO_DMG_HEAL; the family
-- mask already narrows the row to Blood Veil, so no further type restriction is wanted. HitMask 0 leaves
-- the done-proc defaults. Chance 0 defers to the record's own ProcChance 101, i.e. always.
--
-- AttributesMask must stay 0. The chain is 806274 -> 806275 -> 504263, and the re-cast Blood Veil is a
-- triggered spell; Aura::GetProcEffectMask refuses to proc an aura from a triggered spell unless
-- PROC_ATTR_TRIGGERED_CAN_PROC is set (504263 carries neither SPELL_ATTR3_CAN_PROC_FROM_PROCS nor
-- SPELL_ATTR3_NOT_A_PROC). That refusal is what stops the party fan-out from re-triggering itself on every
-- member it reaches. Setting AttributesMask 2 here would be an infinite-loop bug.
--
-- Known divergence, not fixed here: the tooltip says "party members of the target" while 806275's TargetA
-- is 33 (caster area party). The two differ only when the Bloodmage shields someone outside their own
-- party; changing it would mean editing the DBC record, not this table.
DELETE FROM `spell_proc` WHERE `SpellId` = 806274;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806274, 0, 26, 0, 536870912, 0, 16384, 0, 2, 0, 0, 0, 0, 0, 0, 0);
