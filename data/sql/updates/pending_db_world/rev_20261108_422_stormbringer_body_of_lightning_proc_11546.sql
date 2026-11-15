-- #11546 Body of Lightning never deals its additional Nature damage
--
-- Body of Lightning (500041) promises "While active, damage dealt now deals an additional 800406 Nature Damage to
-- up to N enemies". Its effect 0 is SPELL_AURA_PROC_TRIGGER_SPELL on 800406 (SCHOOL_DAMAGE, TargetA 6, ChainTarget 4),
-- but the record has ProcFlags 0 and no spell_proc row existed, so SpellMgr::LoadSpellProcs skipped it and
-- Aura::GetProcEffectMask returned a zero mask: the aura could never proc. Same shape as Storm Clouds
-- (rev_20260922_05) and Lord of Lightning (rev_20260922_07).
--
-- "Damage dealt" is read as every direct and periodic damage event of the buffed ally, any school and any source
-- (same ProcFlags value as the Palm Sigils row -805380: done melee and ranged auto attacks, done spell damage in
-- every class and done periodic damage), at the hit phase of a damage spell. The row sets no
-- PROC_ATTR_TRIGGERED_CAN_PROC, so the triggered 800406 cannot proc itself. DisableEffectsMask 6 keeps the periodic
-- mana effect and the energize effect out of the proc. Chance 100 is the record's own ProcChance.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 500041;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(500041, 0, 0, 0, 0, 0, 332116, 1, 2, 0, 0, 6, 0, 100, 0, 0);
COMMIT;
