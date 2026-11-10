-- #10243 / #9843: Atmospheric Pressure (803565) "causing you to generate additional Static on damage taken".
-- Effect 1 is SPELL_AURA_PROC_TRIGGER_SPELL -> 803568 (TRIGGER_SPELL 807945, Add 1 Static), but Spell.dbc
-- gives the spell ProcFlags 0 and no `spell_proc` row exists, so it never fires. Same shape as Gale Guard
-- (rev_20260929_86): proc on damage taken. Effects 0 and 2 are the enemy area auras, disabled here
-- (DisableEffectsMask 5) so enemies holding them proc nothing.
DELETE FROM `spell_proc` WHERE `SpellId` = 803565;
INSERT INTO `spell_proc`
    (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
     `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
     `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
    (803565, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 5, 0, 0, 0, 0);
