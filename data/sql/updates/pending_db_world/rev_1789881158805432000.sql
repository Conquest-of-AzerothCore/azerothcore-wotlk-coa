--
-- Nature's Blessing (#541): each Seismic Wave heal starts three ticks of 20% of that resolved heal.
DELETE FROM `spell_proc` WHERE `SpellId` = 807466;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(807466, 0, 37, 0, 256, 0, 16384, 2, 2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_natures_blessing';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(807466, 'aura_ascension_natures_blessing');

-- This payload already includes the original heal's bonuses; add no second AP/SP coefficient.
DELETE FROM `spell_bonus_data` WHERE `entry` = 807561;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(807561, 0, 0, 0, 0, 'Primalist - Natures Blessing resolved healing payload');
