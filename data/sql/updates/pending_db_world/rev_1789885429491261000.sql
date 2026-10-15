--
-- Thane's Guidance (#625): one second from Mountain Hammer and Primal Rush per successful auto-attack.
DELETE FROM `spell_proc` WHERE `SpellId` = 680410;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(680410, 0, 0, 0, 0, 0, 4, 0, 0, 3, 0, 0, 0, 100, 0, 0);

-- Apply the reduction to every stored rank; suppress the unused Earthen Avatar reset slot.
DELETE FROM `spell_script_names` WHERE `spell_id` = 680411 AND `ScriptName` = 'spell_ascension_thanes_guidance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680411, 'spell_ascension_thanes_guidance');
