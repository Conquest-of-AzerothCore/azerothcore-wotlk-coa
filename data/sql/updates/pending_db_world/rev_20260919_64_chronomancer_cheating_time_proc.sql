-- Cheating Time (524945): "Casting Shatter Echo now extends the duration of your Flux Emitter by
-- $/1000;524944s1 sec. Cannot be extended beyond maximum duration." Its effect 0 is aura 42 (proc trigger
-- spell) triggering 524944, whose single effect is 173 (SPELL_EFFECT_ASCENSION_REFRESH_AURA, handler
-- Spell::EffectAscensionRefreshAura at SpellEffects.cpp:410) with EffectBasePoints 3999 / DieSides 1 ->
-- 4000 ms, EffectMiscValue 804435 (Flux Emitter) and EffectMiscValueB 1, which selects the additive
-- branch `duration = aura->GetDuration() + damage`. The payload is implemented; Spell.dbc gives 524945's
-- record ProcFlags 0 and no `spell_proc` row existed, so LoadSpellProcs skips it (SpellMgr.cpp:2249) and
-- Aura::GetProcEffectMask returns 0 without a proc entry (SpellAuras.cpp:2150-2154). Proc on Shatter Echo
-- (family 28, word2 0x10 = 16, the bit carried by 804503 and its ranks 572417 and 807950-807953), the
-- only ability the tooltip names. Shatter Echo is Spell.dbc DmgClass 3 (RANGED) without
-- SPELL_ATTR2_AUTO_REPEAT, so Spell::prepareDataForTriggerSystem sets m_procAttacker to
-- PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 0x100 = 256 (Spell.cpp:2278-2288) in Spell::prepare, before
-- Spell::cast reuses it for the cast-phase event (Spell.cpp:4017-4047). SpellPhaseMask is 1
-- (PROC_SPELL_PHASE_CAST, SpellMgr.h:248) because the tooltip says "Casting", not "damage dealt by".
-- SpellTypeMask is 7 (PROC_SPELL_TYPE_MASK_ALL): at the CAST phase no damage or heal has happened yet, so
-- Unit::ProcSkillsAndAuras sets the event's spellTypeMask to PROC_SPELL_TYPE_MASK_ALL
-- (Unit.cpp:7121-7128), and the column mirrors that instead of narrowing it. HitMask stays 0; for a DONE
-- flag at the CAST phase SpellMgr::CanSpellTriggerProcOnEvent skips the hit check entirely unless the
-- entry sets one (SpellMgr.cpp:946-949). Chance is the record's own ProcChance (100 - always, as the
-- tooltip states no percentage).
DELETE FROM `spell_proc` WHERE `SpellId` = 524945;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(524945, 0, 28, 0, 0, 16, 256, 7, 1, 0, 0, 0, 0, 100, 0, 0);
