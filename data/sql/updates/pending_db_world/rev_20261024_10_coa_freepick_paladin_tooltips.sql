-- Freepick (Dawnrise) Paladin tree: abilities and talents match their tooltips.

-- Tooltip coefficients (Ascension's SP + AP formulas) where the rows disagree or are missing:
-- Exorcism "{1033+0.14*SPH+0.24*AP}" (row 0.15 / 0.15); Hammer of Wrath "{1367+0.286*SPH+0.286*AP}" (0.15 / 0.15);
-- Holy Wrath "{1058+0.15*SPH+0.15*AP}" (0.07 / 0.07, ranks 2-4 none); Consecration "8*(113+0.0264*SPH+0.022*AP)" per
-- tick (0.04 / 0.04); Avenger's Shield "{1100+0.07*SPH+0.07*AP}" (rank 2 had no row).
DELETE FROM `spell_bonus_data` WHERE `entry` IN (879, 5614, 5615, 10312, 10313, 10314, 27138, 48800, 48801, 24275, 24274, 24239, 27180, 48805, 48806, 2812, 2813, 2814, 2815, 10318, 27139, 48816, 48817, 26573, 26620, 26621, 20116, 20922, 20923, 20924, 27173, 48818, 48819, 31935, 31947, 32699, 32700, 48826, 48827);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(879, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(5614, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(5615, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(10312, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(10313, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(10314, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(27138, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(48800, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(48801, 0.14, 0, 0.24, 0, 'Paladin - Exorcism'),
(24275, 0.286, 0, 0.286, 0, 'Paladin - Hammer of Wrath'),
(24274, 0.286, 0, 0.286, 0, 'Paladin - Hammer of Wrath'),
(24239, 0.286, 0, 0.286, 0, 'Paladin - Hammer of Wrath'),
(27180, 0.286, 0, 0.286, 0, 'Paladin - Hammer of Wrath'),
(48805, 0.286, 0, 0.286, 0, 'Paladin - Hammer of Wrath'),
(48806, 0.286, 0, 0.286, 0, 'Paladin - Hammer of Wrath'),
(2812, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(2813, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(2814, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(2815, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(10318, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(27139, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(48816, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(48817, 0.15, 0, 0.15, 0, 'Paladin - Holy Wrath'),
(26573, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(26620, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(26621, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(20116, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(20922, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(20923, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(20924, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(27173, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(48818, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(48819, 0, 0.0264, 0, 0.022, 'Paladin - Consecration'),
(31935, 0.07, 0, 0.07, 0, 'Paladin - Avenger''s Shield'),
(31947, 0.07, 0, 0.07, 0, 'Paladin - Avenger''s Shield'),
(32699, 0.07, 0, 0.07, 0, 'Paladin - Avenger''s Shield'),
(32700, 0.07, 0, 0.07, 0, 'Paladin - Avenger''s Shield'),
(48826, 0.07, 0, 0.07, 0, 'Paladin - Avenger''s Shield'),
(48827, 0.07, 0, 0.07, 0, 'Paladin - Avenger''s Shield');

-- Talents whose proc auras carry no proc flags in Spell.dbc (and no usable spell_proc row)
DELETE FROM `spell_proc` WHERE `SpellId` IN (-53590, 53590, 53591, 53592, 20361, -31833, 760191, -20101, -20042, 25958, 20121,
    31881);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Touched by the Light: "When you receive effective healing from another player" (script: another player)
(53590, 0, 0, 0, 0, 0, 0x00008000, 2, 2, 0, 0, 0, 0, 0, 0, 0),
(53591, 0, 0, 0, 0, 0, 0x00008000, 2, 2, 0, 0, 0, 0, 0, 0, 0),
(53592, 0, 0, 0, 0, 0, 0x00008000, 2, 2, 0, 0, 0, 0, 0, 0, 0),
-- Sanctified Light capstone: "After using Blinding Light" (script: Blinding Light)
(20361, 0, 0, 0, 0, 0, 0x00015400, 0, 1, 0, 0, 0, 0, 0, 0, 0),
-- Light's Grace: "Gives your Holy Light spell a 33/66/100% chance" (the old row had no flags)
(-31833, 0, 10, 0x80000000, 0, 0, 0x00004000, 2, 2, 0, 0, 0, 0, 0, 0, 0),
-- A New Dawn capstone: "Targets healed by your Light of Dawn"
(760191, 0, 10, 0, 0, 0x00008000, 0x00004000, 2, 2, 0, 0, 0, 0, 0, 0, 0),
-- Benediction: "when you kill a target that gives experience or honor ... once every 5 seconds"
(-20101, 0, 0, 0, 0, 0, 0x00000002, 0, 0, 0, 0, 0, 0, 0, 5000, 0),
-- Improved Blessing of Might: "Casting Blessing of Might on an ally"
(-20042, 0, 10, 0x00000002, 0, 0, 0x00004000, 0, 2, 0, 0, 0, 0, 0, 0, 0),
-- Conviction capstone: "Your non-periodic damaging spell casts have a chance ... once every 6 seconds"
(20121, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 6000, 0),
-- Fanaticism capstone: targets of your Execution Sentence (aura_hero_paladin_fanaticism)
(31881, 0, 10, 0, 0, 0x02000000, 0x00015400, 0, 2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_hero_paladin_touched_by_the_light', 'aura_hero_paladin_sanctified_light',
    'aura_hero_paladin_improved_blessing_of_might', 'spell_hero_paladin_judgement_unsealed',
    'aura_hero_paladin_benediction', 'aura_hero_paladin_fanaticism', 'spell_hero_paladin_shield_of_righteousness');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(53590, 'aura_hero_paladin_touched_by_the_light'),
(53591, 'aura_hero_paladin_touched_by_the_light'),
(53592, 'aura_hero_paladin_touched_by_the_light'),
-- Improved Judgements capstone: Judgement casts grant Unsealed (Judgement cannot trigger procs)
(20271, 'spell_hero_paladin_judgement_unsealed'),
(53407, 'spell_hero_paladin_judgement_unsealed'),
(53408, 'spell_hero_paladin_judgement_unsealed'),
(20361, 'aura_hero_paladin_sanctified_light'),
(-20101, 'aura_hero_paladin_benediction'),
(31881, 'aura_hero_paladin_fanaticism'),
(-20042, 'aura_hero_paladin_improved_blessing_of_might'),
(53600, 'spell_hero_paladin_shield_of_righteousness');
