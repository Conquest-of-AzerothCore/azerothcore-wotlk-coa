-- Keeping the Oath 92109 effect 2 triggers Recently Parried or Dodged 681170, the caster aura the client requires
-- for Sacred Swing. Taken procs only match normal and critical hits by default, so dodges and parries need a HitMask.
DELETE FROM `spell_proc` WHERE `SpellId` = 92109;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(92109, 0, 0, 0, 0, 0, 40, 7, 2, 48, 0, 3, 0, 100, 0, 0);
