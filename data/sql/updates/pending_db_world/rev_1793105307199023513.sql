-- Wildcard's Cursed Effigy (spell 280915) is SPELL_EFFECT_SUMMON with EffectMiscValue 50134, which has no
-- creature_template row, so Spell::EffectSummonType silently no-ops and the cast does nothing visible. The Witch
-- Doctor's own Cursed Effigy (creature 50121, 'npc_ascension_witch_doctor') already does exactly what this
-- tooltip promises, but that AI only arms itself for CLASS_WITCH_DOCTOR summoners. This gives the Wildcard's
-- effigy its own creature_template, cloned from 50121's name/stats/model, bound to a separate ScriptName that
-- is not class-gated.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`, `BaseAttackTime`, `RangeAttackTime`, `ScriptName`) VALUES
(50134, 'Cursed Effigy', 1, 1, 35, 1, 11, 2000, 2000, 'npc_ascension_wildcard_cursed_effigy') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`), `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 50134;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(50134, 0, 427391, 1, 1);
