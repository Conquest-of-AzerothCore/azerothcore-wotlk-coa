-- #13097 Everlasting Fire (281571): Crusader Strike, Divine Storm, Exorcism, Hammer of Wrath and Judgement extend
-- the caster's Holy Fire of any rank by 3 s. The DBC mask covered Exorcism only, and its helper 281572 matched
-- Holy Fire rank 1 by id and reset the duration to 3 s.
-- #13110 Holy Ascension (273252): periodic Holy Fire damage has a 15% chance to grant Surge of Light. The generated
-- DBC proc fired on any direct magic hit instead.
DELETE FROM `spell_proc` WHERE `SpellId` IN (281571, 273252);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(281571, 0, 0, 0, 0, 0, 332116, 7, 2, 0, 2, 0, 0, 100, 0, 0),
(273252, 0, 0, 0, 0, 0, 262144, 7, 2, 0, 2, 0, 0, 15, 0, 0);

-- #13104 Righteous Radiance (270326): direct Fire damage also grants the Righteous Radiance buff (270308), which only
-- an unlearned Ascension companion spell triggered.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (281571, 273252) AND `ScriptName` = 'aura_wildcard_skillcard_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 270326 AND `ScriptName` = 'aura_wildcard_righteous_radiance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(281571, 'aura_wildcard_skillcard_proc'),
(273252, 'aura_wildcard_skillcard_proc'),
(270326, 'aura_wildcard_righteous_radiance');
