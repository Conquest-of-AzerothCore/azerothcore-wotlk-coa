-- Time Is A Circle (806206): "Level 40 Passive. Casting Wand of Time now extends the duration of your
-- Continuum spells by $/1000;524962s1 sec. Continuum spells cannot be extended beyond their maximum
-- duration." Its effect 0 is aura 42 (proc trigger spell) triggering 524962 (named "Wand Master" in
-- Spell.dbc, a stale label), which carries three effect 177 entries
-- (SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION, handler Spell::EffectAscensionModifyAuraDuration at
-- SpellEffects.cpp), each EffectBasePoints 2999 / DieSides 1 -> 3000 ms, with EffectMiscValue 806203
-- (Paradox Cannon), 804435 (Flux Emitter) and 804436 (Aether Compression). The payload is implemented;
-- Spell.dbc gives 806206's record ProcFlags 0 and no `spell_proc` row existed, so LoadSpellProcs skips it
-- (SpellMgr.cpp:2249) and Aura::GetProcEffectMask returns 0 without a proc entry
-- (SpellAuras.cpp:2150-2154). Proc on Wand of Time (family 28, word1 0x100000 = 1048576: 520175's own
-- SpellFamilyFlags are [16781312, 1048576, 0] and ranks 520702-520707, 524960 and 520165 all carry that
-- word1 bit), the only ability the tooltip names. Wand of Time is Spell.dbc DmgClass 3 (RANGED) without
-- SPELL_ATTR2_AUTO_REPEAT, so Spell::prepareDataForTriggerSystem sets m_procAttacker to
-- PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 0x100 = 256 (Spell.cpp:2278-2288), which Spell::cast reuses for
-- the cast-phase event (Spell.cpp:4017-4047). SpellPhaseMask is 1 (PROC_SPELL_PHASE_CAST, SpellMgr.h:248)
-- because the tooltip says "Casting". SpellTypeMask is 7 (PROC_SPELL_TYPE_MASK_ALL) because at the CAST
-- phase Unit::ProcSkillsAndAuras sets the event's spellTypeMask to PROC_SPELL_TYPE_MASK_ALL
-- (Unit.cpp:7121-7128). HitMask stays 0; SpellMgr::CanSpellTriggerProcOnEvent skips the hit check for a
-- DONE flag at the CAST phase unless the entry sets one (SpellMgr.cpp:946-949). Chance is the record's
-- own ProcChance (100 - always, as the tooltip states no percentage).
DELETE FROM `spell_proc` WHERE `SpellId` = 806206;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806206, 0, 28, 0, 1048576, 0, 256, 7, 1, 0, 0, 0, 0, 100, 0, 0);
