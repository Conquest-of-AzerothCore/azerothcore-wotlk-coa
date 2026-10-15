-- Malediction (800776): "Condemn an enemy, dealing ... Shadow damage over $704120d and increasing the
-- damage they take from your next 5 direct damage spells by $704120s1%." 800776's single effect is
-- 64 SPELL_EFFECT_TRIGGER_SPELL on 704120, which is native. 704120 carries the whole contract:
-- effect 0 is aura 271 SPELL_AURA_MOD_DAMAGE_FROM_CASTER, BasePoints 19 -> +20%, with
-- EffectSpellClassMask (262144, 2826240, 0); effect 1 is aura 3 SPELL_AURA_PERIODIC_DAMAGE, Amplitude
-- 3000 over DurationIndex 29 = 12000 ms. Both halves work. The missing half is "next 5": Spell.dbc gives
-- 704120 ProcCharges 0 and StackAmount 0 and no `spell_proc` row existed, so Aura::CalcMaxCharges
-- returned 0, Aura::IsUsingCharges was false, and the +20% applied to every matching spell for the full
-- 12 seconds instead of the first five.
--
-- `Charges` 5 is the tooltip's own number and is what Aura::CalcMaxCharges reads in preference to the
-- DBC ProcCharges; Aura::PrepareProcToTrigger spends one per qualifying event and Aura::ConsumeProcCharges
-- removes the aura when the last one is spent.
--
-- `SpellFamilyName` 26 with `SpellFamilyMask` (262144, 2826240, 0) is a literal copy of effect 0's own
-- EffectSpellClassMask, so a charge is spent by exactly the spells the +20% applies to and by no others.
-- Read out of Spell.dbc family 26, those bits are Valanar's Vengeance 560315/561027-561029/572793-572795
-- (262144, 0, 0), Bloodmoon Blast 500125/501607-501614/572332 (0, 8192, 0), Atherann's Anguish 500448
-- (0, 65536, 0), Bloodbolt 804685/806928-806932/578304/578305 (0, 131072, 0), Vampiric Fang
-- 804726/504093-504097/553271/553272 (0, 524288, 0) and Sanguine Rupture 800775/802496 (0, 2097152, 0).
-- All 36 of those records are DmgClass 1 (SPELL_DAMAGE_CLASS_MAGIC) and SchoolMask 32 (Shadow).
--
-- `ProcFlags` 131072 = PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG: the aura sits on the victim, so the
-- event is the taken side, and Spell::DoAllEffectOnTarget raises exactly this flag for a negative
-- DmgClass MAGIC spell. PROC_FLAG_TAKEN_PERIODIC is deliberately left out: the tooltip says "direct
-- damage spells", so a damage-over-time tick from one of those spells must not spend a charge.
-- `SpellTypeMask` 1 (PROC_SPELL_TYPE_DAMAGE) keeps a zero-damage cast from spending one -
-- Unit::ProcSkillsAndAuras only sets that bit when the event carried damage or an absorb.
-- `SpellPhaseMask` is 0 on purpose: TAKEN flags are outside REQ_SPELL_PHASE_PROC_FLAG_MASK, so
-- SpellMgr::CanSpellTriggerProcOnEvent never reads it and SpellMgr::LoadSpellProcs logs an error for a
-- row that sets it anyway. `HitMask` 0 takes the native taken-proc default (PROC_HIT_NORMAL |
-- PROC_HIT_CRITICAL), so a critical strike spends a charge like an ordinary hit. `Chance` 100 is the
-- record's own ProcChance. `Cooldown` 0: five consecutive spells must each spend one.
--
-- Known consequence, stated rather than hidden: 704120 fuses both halves of the tooltip into one record,
-- so Aura::ConsumeProcCharges removes the whole aura when the fifth charge is spent and the remaining
-- damage-over-time ticks go with it. Splitting the two halves would need a second record that the shipped
-- data does not contain, so the native charge behaviour is used as-is. In practice the Bloodmage's
-- in-mask spells cast in 2 to 6 seconds, so five of them rarely fit far inside the 12 second window.
--
-- The companion script aura_ascension_bloodmage_malediction
-- (modules/mod-ascension-compat/src/AscensionBloodmageProcs.cpp) adds the one restriction no column
-- carries, "your": the charges belong to the Bloodmage who cast Malediction. Without it a second
-- Bloodmage attacking the same victim would spend the first one's charges, because although
-- AuraEffect::CheckEffectProc rejects SPELL_AURA_MOD_DAMAGE_FROM_CASTER for a foreign actor, that only
-- clears effect 0 from the proc mask - effect 1's periodic damage keeps the mask non-zero and
-- Aura::PrepareProcToTrigger still takes a charge. The two changes belong together.
DELETE FROM `spell_proc` WHERE `SpellId` = 704120;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(704120, 0, 26, 262144, 2826240, 0, 131072, 1, 0, 0, 0, 0, 0, 100, 0, 5);

DELETE FROM `spell_script_names` WHERE `spell_id` = 704120 AND `ScriptName` = 'aura_ascension_bloodmage_malediction';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704120, 'aura_ascension_bloodmage_malediction');
