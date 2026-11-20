-- Tempest Calling 707615: Effect1 is aura 354 (40%, TriggerSpell 802750), but DBC ProcFlags 0 and no spell_proc row
-- kept it from ever proccing, so Aeroblast never dealt its delayed second hit. Restrict it to Aeroblast hits.
DELETE FROM `spell_proc` WHERE `SpellId` = 707615;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707615, 0, 22, 8388608, 0, 0, 65536, 1, 2, 0, 0, 1, 0, 100, 0, 0);
