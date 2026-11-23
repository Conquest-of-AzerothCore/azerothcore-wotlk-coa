-- Core / stock-script changes the dummy fixes needed (tools/dummy_census/SYSTEMS-BRIEF.md, task A "core"). The C++ lives
-- in the stock files (Unit.cpp, SpellInfo.cpp, SpellAuras.cpp, SpellAuraEffects.cpp, StatSystem.cpp, spell_mage.cpp,
-- spell_rogue.cpp, spell_priest.cpp, spell_dk.cpp) and the class files AscensionDummyFix{Mage,Rogue,Warlock}.cpp.

-- Edge of Fury (talent 276397, toggle 985227): Killing Spree's teleport lands without moving the rogue
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_dummyfix_rogue_edge_of_fury_teleport';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(57840, 'spell_dummyfix_rogue_edge_of_fury_teleport');

-- Twilight (Mystic Enchant 84471): "Your Vampiric Embrace now also heals from your bleeds" -- the priest's own bleed
-- damage (periodic ticks and direct bleed hits) feeds Vampiric Embrace at Twilight's s1%
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_twilight';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(84471, 'spell_pri_twilight');

-- Vampiric Embrace's heal: the party share (effect 0) is for "other party members", not the priest a second time
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_pri_vampiric_embrace_target';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(15290, 'spell_pri_vampiric_embrace_target'),
(1115290, 'spell_pri_vampiric_embrace_target');

-- Seed of Corruption ranks 1-5 (27243 27251 27252 27253 47835) carry no proc flags in Ascension's data (rank 6, 47836,
-- and the Reborn copies carry 0xA22A8), so the seed never counted damage taken and never detonated from it. The rank
-- chain row takes rank 6's flags: damage taken from melee, ranged, spells and periodic effects.
DELETE FROM `spell_proc` WHERE `SpellId` = -27243;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-27243, 0, 0, 0x0, 0x0, 0x0, 0xA22A8, 0x1, 0x0, 0x0, 0x0, 0, 0, 0, 0, 0);

-- Twilight: the priest's damage done by a bleed (periodic ticks, melee-class bleed hits); triggered bleeds count
DELETE FROM `spell_proc` WHERE `SpellId` = 84471;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(84471, 0, 0, 0x0, 0x0, 0x0, 0x40010, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0);
