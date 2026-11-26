-- Bloodmage secondary conformance fixes (Lot 3): Eyes In The Night (806723), Festering Maw (706683),
-- and Sacrificial Rite Cursed Blood (573250 / 806163).
--
-- 806723 Eyes In The Night (Shadow Colony, owner ruling Q-bm-14 / O-10):
--   Supersedes rev_20261025_03_coa_eyes_in_the_night_proc.sql by aligning the internal cooldown to
--   3000 ms (matching 801959's tooltip "Can only occur once every 3 sec." and the 2026-09-01 client
--   archive) while keeping every other column identical to rev_20261025_03.
--
-- 706683 Festering Maw ("Healing with Bite Wound now reduces the cooldown of Lunge by 1 sec."):
--   Spell.dbc gives 706683 ProcFlags 4 (PROC_FLAG_DONE_MELEE_AUTO_ATTACK), causing auto-attacks
--   without Bite Wound to trigger 706718. Setting DisableEffectsMask 1 disables the DBC Effect[0]
--   auto-proc (ProcFlags 0 inherits DBC ProcFlags 4 so LoadSpellProcs logs no error); 706718 is
--   triggered directly by aura_ascension_bloodmage_bite_wound::HealCaster in
--   src/server/coa/AscensionBloodmageSecondary.cpp whenever Bite Wound actually heals.
--
-- 573250 / 806163 Sacrificial Rite (Cursed Blood):
--   573250 carries Spell.dbc ProcFlags 0 and no spell_proc row, so Effect[1] (aura 42 triggering
--   806163) never fired when the cursed attacker dealt damage. ProcFlags 69908
--   (DONE_MELEE_AUTO_ATTACK 0x4 | DONE_SPELL_MELEE_DMG_CLASS 0x10 | DONE_SPELL_RANGED_DMG_CLASS
--   0x100 | DONE_SPELL_NONE_DMG_CLASS_NEG 0x1000 | DONE_SPELL_MAGIC_DMG_CLASS_NEG 0x10000),
--   SpellTypeMask 1 (DAMAGE), SpellPhaseMask 2 (HIT), DisableEffectsMask 1 (excludes Effect[0]
--   healing reduction), Chance 100, Cooldown 1000 (matching 806163's "Can only occur once per sec.")
--   fires Effect[1] solely when the cursed attacker deals damage. aura_ascension_bloodmage_cursed_blood
--   redirects the cast so the Bloodmage casts 806163 at the attacker, and spell_bonus_data adds the
--   tooltip's +0.5 SP and +0.1 AP scaling (${$806163m1+$806163ppl1+$sps*.5+$AP*.1}).

DELETE FROM `spell_proc` WHERE `SpellId` IN (806723, 706683, 573250);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806723, 0, 0, 0, 0, 0, 139944, 1, 2, 0, 0, 0, 0, 0, 3000, 0),
(706683, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0),
(573250, 0, 0, 0, 0, 0, 69908, 1, 2, 0, 0, 1, 0, 100, 1000, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 573250 AND `ScriptName` = 'aura_ascension_bloodmage_cursed_blood';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(573250, 'aura_ascension_bloodmage_cursed_blood');

DELETE FROM `spell_bonus_data` WHERE `entry` = 806163;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(806163, 0.5, 0, 0.1, 0, 'Bloodmage - Sacrificial Rite (Cursed Blood)');
