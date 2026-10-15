--
-- Bring Me Their Bones (#457): qualify pet ability hits against this owner's marked target,
-- count five hits, and consume only that owner's stacks. White swings do not qualify.
DELETE FROM `spell_proc` WHERE `SpellId` = 806378;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806378, 0, 0, 0, 0, 0, 332048, 1, 2, 0, 2, 0, 0, 100, 0, 0);

-- The native listener retains the Primalist original caster, matching the visible 50% AP formula.
DELETE FROM `spell_bonus_data` WHERE `entry` = 806553;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(806553, 0, 0, 0.5, 0, 'Primalist: Bring Me Their Bones - fifth pet ability hit');

DELETE FROM `spell_script_names` WHERE (`spell_id` = 806552 AND `ScriptName` IN ('spell_ascension_bring_their_bones', 'aura_ascension_bones_mark')) OR (`spell_id` = 806378 AND `ScriptName` = 'aura_ascension_bones_listener') OR (`spell_id` = 806553 AND `ScriptName` = 'spell_ascension_bones_damage');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(806552, 'spell_ascension_bring_their_bones'),
(806552, 'aura_ascension_bones_mark'),
(806378, 'aura_ascension_bones_listener'),
(806553, 'spell_ascension_bones_damage');
