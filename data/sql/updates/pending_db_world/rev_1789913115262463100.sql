--
-- Mineralization (#900): completed spell casts at or below 35% health grant six seconds of healing taken.
DELETE FROM `spell_proc` WHERE `SpellId` = 520464;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520464, 0, 0, 0, 0, 0, 87312, 0, 1, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 24 AND `SourceEntry` = 520464;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
`ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
`NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(24, 0, 520464, 0, 0, 38, 0, 35, 4, 0, 0, 0, 0, '', 'Mineralization: caster health at or below 35 percent');
