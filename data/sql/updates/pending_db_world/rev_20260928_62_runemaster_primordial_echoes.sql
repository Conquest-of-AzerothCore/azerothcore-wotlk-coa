-- Primordial Echoes 705572 (#2742): "Your critical strikes dealt with Primordial Blast now have a 40% chance to
-- strike an additional time." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 40, trigger 547525, but
-- Spell.dbc ProcFlags is 0 and no spell_proc row exists, so it never fires. Primordial Blast (502823-502827,
-- 800732) is family 38, SpellFamilyFlags0/1/2 4194304/1048576/64, SPELL_EFFECT_SCHOOL_DAMAGE on the enemy
-- (harmful), DmgClass magic, so a hit-phase event carries PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000);
-- HitMask is restricted to PROC_HIT_CRITICAL (0x2) to match "critical strikes" exactly, SpellTypeMask 0x1
-- (damage), SpellPhaseMask 0x2 (hit); Chance 0 keeps the Spell.dbc 40%.
DELETE FROM `spell_proc` WHERE `SpellId` = 705572;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705572, 0, 38, 4194304, 1048576, 64, 0x00010000, 0x1, 0x2, 0x2, 0, 0, 0, 0, 0, 0);
