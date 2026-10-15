-- Wand Mastery (806216): "Wand of Time and Shatter Echo now have a $h% chance to unleash Crystal Cannon,
-- launching 2 quick lesser Wand auto attacks at the enemy over $704481d, scaling with Spirit. While
-- Paradox Cannon is active, the chance to trigger this effect is increased by $806203s2%." Its effect 0
-- is aura 42 (proc trigger spell) triggering 704481, the repeating wand-attack channel
-- (SPELL_AURA_PERIODIC_TRIGGER_SPELL, Amplitude 500, Trigger 560134), which is native and already
-- exercised by apps/coa-gameplay-test/scenarios/chronomancer-crystal-cannon-from-discordance.json. The
-- "while Paradox Cannon is active" clause is native too: 806203's effect 1 is
-- SPELL_AURA_ADD_FLAT_MODIFIER with EffectMiscValue 18 (SPELLMOD_CHANCE_OF_SUCCESS, SpellDefines.h:94),
-- EffectBasePoints 9 / DieSides 1 -> +10 and EffectSpellClassMask [0, 8388608, 0], matching 806216's own
-- SpellFamilyFlags [0, 8388608, 0] exactly; Aura::IsProcTriggeredOnEvent applies it at
-- SpellAuras.cpp:2313. Spell.dbc gives 806216's record ProcFlags 0 and no `spell_proc` row existed, so
-- LoadSpellProcs skips it (SpellMgr.cpp:2249) and Aura::GetProcEffectMask returns 0 without a proc entry
-- (SpellAuras.cpp:2150-2154); the chance modifier is dead code only because the roll never happens. Proc
-- on the ranged class damage of Wand of Time (family 28, word1 0x100000 = 1048576, carried by 520175 and
-- ranks 520702-520707, 524960, 520165) and Shatter Echo (family 28, word2 0x10 = 16, carried by 804503
-- and ranks 572417, 807950-807953): SpellInfo::IsAffected ORs the three mask words, so one row covers
-- both named abilities. Both are Spell.dbc DmgClass 3 (RANGED) without SPELL_ATTR2_AUTO_REPEAT, so their
-- events carry PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS = 0x100 = 256 (Spell.cpp:2278-2288,
-- SpellMgr.h:122), and both deal weapon-based damage, so the HIT event reports damage and
-- Unit::ProcSkillsAndAuras computes SpellTypeMask PROC_SPELL_TYPE_DAMAGE (1) (Unit.cpp:7121-7133).
-- SpellPhaseMask is 2 (PROC_SPELL_PHASE_HIT) so the channel is unleashed at the enemy the attack landed
-- on. HitMask stays 0 for the default normal/critical/absorb set. Chance is the record's own ProcChance
-- (25), unchanged; the Paradox Cannon modifier raises it at runtime. This is the direct sibling of the
-- merged rev_20260918_34_chronomancer_crystal_cannon_proc.sql (806204, same trigger 704481).
DELETE FROM `spell_proc` WHERE `SpellId` = 806216;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806216, 0, 28, 0, 1048576, 16, 256, 1, 2, 0, 0, 0, 0, 25, 0, 0);
