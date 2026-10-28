-- Guidance (532261, Farstrider row 7 col 2) reads "Increases your Physical and Nature damage dealt by 1%
-- for each War Falcon or Dragonhawk you have active." Its single effect is
-- SPELL_AURA_MOD_DAMAGE_PERCENT_DONE with BasePoints 0, and nothing recalculated it, so the passive
-- contributed nothing at all. aura_ascension_ranger_guidance now derives the amount by counting the
-- owner's live War Falcons and Dragonhawks inside each presence aura's radius - the same companions and
-- the same radius test aura_ascension_ranger_wingman already uses for the 680278/681394 presence auras -
-- so one companion is the tooltip's 1%, and the 500 ms refresh makes a summon or despawn count
-- immediately.
--
-- "Physical and Nature" is already carried by the record: effect 0's MiscValue is 9 (SPELL_SCHOOL_MASK_NORMAL
-- | SPELL_SCHOOL_MASK_NATURE), and MiscValue is the school filter every SPELL_AURA_MOD_DAMAGE_PERCENT_DONE
-- reader in Unit.cpp applies. The spell's own SchoolMask (1) does not scope the aura, so nothing rewrites it.
--
-- Plumes of War (705071, Farstrider row 9 col 5) reads "Increases the critical strike chance of
-- Falconstrike and Emerald Arrow by 15%. In addition, critical strikes with Falconstrike now increase the
-- damage of subsequent Falconstrikes by 5% for 15 seconds, stacking 5 times." The 15% is effect 1
-- (SPELL_AURA_ADD_FLAT_MODIFIER) and is native; the second clause is effect 2, aura 42 on 705078, which is
-- an Add % Modifier of 5 for 15 sec stacking 5 - a native payload. What was missing was the proc event, and
-- the row is the shipped Forest Fighter 706282 row verbatim, because the event is the same event: a
-- critical strike with Falconstrike. SpellFamilyName 27 with SpellFamilyMask1 4194304 names Falconstrike
-- and nothing else in family 27, ProcFlags 256 is PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS (Falconstrike is
-- DefenseType 3), HitMask 2 is PROC_HIT_CRITICAL and is the whole point of the clause, SpellTypeMask 1
-- keeps healing ticks out, SpellPhaseMask 2 is mandatory because 0x100 sits in
-- REQ_SPELL_PHASE_PROC_FLAG_MASK, and Chance 0 lets the record's own ProcChance supply the "critical
-- strikes", which the tooltip states without a number.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_ranger_guidance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(532261, 'aura_ascension_ranger_guidance');
DELETE FROM `spell_proc` WHERE `SpellId` = 705071;
INSERT INTO `spell_proc`
    (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
     `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
     `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
(705071, 0, 27, 0, 4194304, 0, 256, 1, 2, 2, 0, 0, 0, 0, 0, 0);
