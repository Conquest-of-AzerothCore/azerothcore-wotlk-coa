-- Warrior-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/warrior-*.md);
-- scripts in src/server/coa/AscensionDummyFixWarrior.cpp.

-- ===== warrior-01 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummyfix_warrior_soul_restoration',
    'spell_dummyfix_warrior_elemental_execute', 'spell_dummyfix_warrior_execute_damage',
    'spell_dummyfix_warrior_bloodthirst_heal', 'spell_dummyfix_warrior_built_up_thirst',
    'spell_dummyfix_warrior_devastate_glyph', 'spell_dummyfix_warrior_vigilance_redirect',
    'spell_dummyfix_warrior_lightning_blast');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Soul Restoration: listed heals shorten Weakened Soul on the healed unit
(84381, 'spell_dummyfix_warrior_soul_restoration'),
(282213, 'spell_dummyfix_warrior_soul_restoration'),
(1181290, 'spell_dummyfix_warrior_soul_restoration'),
-- Built up Thirst: finishing moves grant 271777 for 20% per combo point
(271778, 'spell_dummyfix_warrior_built_up_thirst'),
-- Electrified Grasp: Stormbringer's Lightning Blast slows only with the talent
(273057, 'spell_dummyfix_warrior_lightning_blast'),
-- Arcane / Burning / Frozen / Righteous / Shadowy / Storming Execution (all ranks)
(913060, 'spell_dummyfix_warrior_elemental_execute'),
(913061, 'spell_dummyfix_warrior_elemental_execute'),
(913062, 'spell_dummyfix_warrior_elemental_execute'),
(913063, 'spell_dummyfix_warrior_elemental_execute'),
(913064, 'spell_dummyfix_warrior_elemental_execute'),
(913065, 'spell_dummyfix_warrior_elemental_execute'),
(913066, 'spell_dummyfix_warrior_elemental_execute'),
(913067, 'spell_dummyfix_warrior_elemental_execute'),
(913068, 'spell_dummyfix_warrior_elemental_execute'),
(913069, 'spell_dummyfix_warrior_elemental_execute'),
(913070, 'spell_dummyfix_warrior_elemental_execute'),
(913071, 'spell_dummyfix_warrior_elemental_execute'),
(913072, 'spell_dummyfix_warrior_elemental_execute'),
(913073, 'spell_dummyfix_warrior_elemental_execute'),
(913074, 'spell_dummyfix_warrior_elemental_execute'),
(913075, 'spell_dummyfix_warrior_elemental_execute'),
(913076, 'spell_dummyfix_warrior_elemental_execute'),
(913077, 'spell_dummyfix_warrior_elemental_execute'),
(913078, 'spell_dummyfix_warrior_elemental_execute'),
(913079, 'spell_dummyfix_warrior_elemental_execute'),
(913080, 'spell_dummyfix_warrior_elemental_execute'),
(913081, 'spell_dummyfix_warrior_elemental_execute'),
(913082, 'spell_dummyfix_warrior_elemental_execute'),
(913083, 'spell_dummyfix_warrior_elemental_execute'),
(913084, 'spell_dummyfix_warrior_elemental_execute'),
(913085, 'spell_dummyfix_warrior_elemental_execute'),
(913086, 'spell_dummyfix_warrior_elemental_execute'),
(913087, 'spell_dummyfix_warrior_elemental_execute'),
(913088, 'spell_dummyfix_warrior_elemental_execute'),
(913089, 'spell_dummyfix_warrior_elemental_execute'),
(913090, 'spell_dummyfix_warrior_elemental_execute'),
(913091, 'spell_dummyfix_warrior_elemental_execute'),
(913092, 'spell_dummyfix_warrior_elemental_execute'),
(913093, 'spell_dummyfix_warrior_elemental_execute'),
(913094, 'spell_dummyfix_warrior_elemental_execute'),
(913095, 'spell_dummyfix_warrior_elemental_execute'),
(913096, 'spell_dummyfix_warrior_elemental_execute'),
(913097, 'spell_dummyfix_warrior_elemental_execute'),
(913098, 'spell_dummyfix_warrior_elemental_execute'),
(913099, 'spell_dummyfix_warrior_elemental_execute'),
(913100, 'spell_dummyfix_warrior_elemental_execute'),
(913101, 'spell_dummyfix_warrior_elemental_execute'),
(913102, 'spell_dummyfix_warrior_elemental_execute'),
(913103, 'spell_dummyfix_warrior_elemental_execute'),
(913104, 'spell_dummyfix_warrior_elemental_execute'),
(913105, 'spell_dummyfix_warrior_elemental_execute'),
(913106, 'spell_dummyfix_warrior_elemental_execute'),
(913107, 'spell_dummyfix_warrior_elemental_execute'),
(913108, 'spell_dummyfix_warrior_elemental_execute'),
(913109, 'spell_dummyfix_warrior_elemental_execute'),
(913110, 'spell_dummyfix_warrior_elemental_execute'),
(913111, 'spell_dummyfix_warrior_elemental_execute'),
(913112, 'spell_dummyfix_warrior_elemental_execute'),
(913113, 'spell_dummyfix_warrior_elemental_execute'),
(913114, 'spell_dummyfix_warrior_elemental_execute'),
(913115, 'spell_dummyfix_warrior_elemental_execute'),
(913116, 'spell_dummyfix_warrior_elemental_execute'),
(913117, 'spell_dummyfix_warrior_elemental_execute'),
(913118, 'spell_dummyfix_warrior_elemental_execute'),
(913119, 'spell_dummyfix_warrior_elemental_execute');

-- Classless glyphs (talents on free-pick realms): the stock glyph's aura rides along, so the stock code that reads
-- the stock glyph (or its twin) serves them: Glyph of Execution (rage; its crit clause is a script), Glyph of
-- Bloodthirst, Glyph of Devastate, Glyph of Vigilance
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (118525, 118531, 118560, 118800) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(118525, 58367, 2, 'Classless Glyph of Execution - stock glyph aura (Execute rage)'),
(118531, 58369, 2, 'Classless Glyph of Bloodthirst - stock glyph aura (Bloodthirst heal)'),
(118560, 58388, 2, 'Classless Glyph of Devastate - stock glyph aura (second Sunder stack)'),
(118800, 63326, 2, 'Classless Glyph of Vigilance - stock glyph aura (threat transfer)');

DELETE FROM `spell_proc` WHERE `SpellId` IN (84381, 282213, 1181290, 271778);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Soul Restoration: own direct heals landing (the script picks the listed heals)
(84381, 0, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(282213, 0, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(1181290, 0, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Built up Thirst: any own spell cast; the script keeps finishing moves while the combo points are still held
(271778, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ===== warrior-02 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummyfix_warrior_mastery_of_the_tide',
    'spell_dummyfix_warrior_abjurers_ward', 'spell_dummyfix_warrior_armor_of_faith_buff',
    'spell_dummyfix_warrior_adrenaline_rush');
DELETE FROM `spell_script_names` WHERE `spell_id` = 1462975 AND `ScriptName` = 'spell_warr_last_stand';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (979768, 84379, 282208) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Last Stand (Hero copy 1462975): the stock script grants s1% of max health through 12976
(1462975, 'spell_warr_last_stand'),
-- Here Comes The Big One (enchant 979768): the generic enchant proc rules below
(979768, 'spell_ascension_mystic_enchant_proc'),
-- Armor of Faith: the enchant / talent grant the buff through proc rules; the buff heals on the next damage taken
(84379, 'spell_ascension_mystic_enchant_proc'),
(282208, 'spell_ascension_mystic_enchant_proc'),
(84380, 'spell_dummyfix_warrior_armor_of_faith_buff'),
(282209, 'spell_dummyfix_warrior_armor_of_faith_buff'),
-- Mastery of the Tide: Chain Heal (all player ranks, stock and Reborn) keeps the target's Riptide
(1064, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(10622, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(10623, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(25422, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(25423, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(55458, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(55459, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1101064, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1110622, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1110623, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1125422, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1125423, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1155458, 'spell_dummyfix_warrior_mastery_of_the_tide'),
(1155459, 'spell_dummyfix_warrior_mastery_of_the_tide'),
-- Abjurer's Ward: Fire / Frost: absorbs by Fire Ward / Frost Ward (all ranks) cut Combustion / Cold Snap
(-543, 'spell_dummyfix_warrior_abjurers_ward'),
(-6143, 'spell_dummyfix_warrior_abjurers_ward'),
-- Flash of Adrenaline: Adrenaline Rush expiring resets Sprint
(13750, 'spell_dummyfix_warrior_adrenaline_rush'),
(1113750, 'spell_dummyfix_warrior_adrenaline_rush'),
(1213750, 'spell_dummyfix_warrior_adrenaline_rush');

DELETE FROM `spell_proc` WHERE `SpellId` IN (979768, 84379, 282208, 84380, 282209);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- enchant proc rules decide (as the talent 284407's row)
(979768, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x0, 0x3, 0x0, 0x2, 0, 0, 0, 0, 0),
(84379, 0, 0, 0x0, 0x0, 0x0, 0x55550, 0x0, 0x3, 0x0, 0x2, 0, 0, 100, 0, 0),
(282208, 0, 0, 0x0, 0x0, 0x0, 0x55550, 0x0, 0x3, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Armor of Faith buff: the carrier's first damage taken (as WCR 1582342), one charge
(84380, 0, 0, 0x0, 0x0, 0x0, 0x222a8, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 1),
(282209, 0, 0, 0x0, 0x0, 0x0, 0x222a8, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 1);

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (979768, 84379, 282208);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
-- Here Comes The Big One enchant: as talent 284407: Bloodthirst stacks 414000; at 3 stacks it grants 414001 and the stacks go
(979768, 0, 0, 'cast', 0, '23881', 100, 0, '', '', 'stacks:414000<3', '', '', 0, 0, 'Here Comes The Big One (enchant 979768): a stack per Bloodthirst'),
(979768, 1, 0, 'cast', 0, '23881', 100, 0, '', '', 'stacks:414000>=3', '414000', '', 0, 0, 'Here Comes The Big One (enchant 979768): the fourth Bloodthirst gets The Big One'),
-- Armor of Faith: Greater Heal / Flash Heal on a unit with Weakened Soul grants the buff storing a share of the heal
(84379, 0, 0, 'direct_heal', 0, '2050 2052 2053 2054 2055 2060 2061 6063 6064 9472 9473 9474 10915 10916 10917 10963 10964 10965 25210 25213 25233 25235 25314 48062 48063 48070 48071', 100, 0, '', '6788 1106788', '', '', '84380', 20, 0, 'Armor of Faith (enchant 84379): 20% of the heal stored'),
(282208, 0, 0, 'direct_heal', 0, '2050 2052 2053 2054 2055 2060 2061 6063 6064 9472 9473 9474 10915 10916 10917 10963 10964 10965 25210 25213 25233 25235 25314 48062 48063 48070 48071', 100, 0, '', '6788 1106788', '', '', '282209', 35, 0, 'Armor of Faith (talent 282208): 35% of the heal stored');

-- ===== warrior-03 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummyfix_warrior_two_handed_mastery',
    'spell_dummyfix_warrior_traumatic_wounds', 'spell_dummyfix_warrior_traumatic_rake');
DELETE FROM `spell_script_names` WHERE `spell_id` IN (81515, 282098) AND `ScriptName` = 'spell_ascension_mystic_thundering_blow';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Thundering Blow (enchant 15%, talent 25%): as the WCR enchant 1581997: Shockwave on an own Thunder Clap target adds
-- a Nature strike for s1% and cuts Shockwave's cooldown 1 sec per such target (10 sec at most)
(81515, 'spell_ascension_mystic_thundering_blow'),
(282098, 'spell_ascension_mystic_thundering_blow'),
-- Two-Handed Weapon Mastery: the passive only while a single two-hander is wielded
(29623, 'spell_dummyfix_warrior_two_handed_mastery'),
(829633, 'spell_dummyfix_warrior_two_handed_mastery'),
-- Traumatic Wounds: listed attacks extend the DoTs (273717); Rake ticks restore Energy (273721)
(273713, 'spell_dummyfix_warrior_traumatic_wounds'),
(-1822, 'spell_dummyfix_warrior_traumatic_rake'),
(1101822, 'spell_dummyfix_warrior_traumatic_rake'),
(1101823, 'spell_dummyfix_warrior_traumatic_rake'),
(1101824, 'spell_dummyfix_warrior_traumatic_rake'),
(1109904, 'spell_dummyfix_warrior_traumatic_rake'),
(1127003, 'spell_dummyfix_warrior_traumatic_rake'),
(1148573, 'spell_dummyfix_warrior_traumatic_rake'),
(1148574, 'spell_dummyfix_warrior_traumatic_rake');

-- Fatal Vanguard: the talent carries its passive (277991: Execute +35% crit chance and crit damage; Execute crits cut
-- Concussion Blow's cooldown through 277992)
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 277990 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(277990, 277991, 2, 'Fatal Vanguard - its Execute passive');

DELETE FROM `spell_proc` WHERE `SpellId` IN (81515, 282098, 277991, 273713);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Thundering Blow: Shockwave (flags[1] 0x8000) hits, as WCR 1581997
(81515, 0, 4, 0x0, 0x8000, 0x0, 0x110, 0x1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0),
(282098, 0, 4, 0x0, 0x8000, 0x0, 0x110, 0x1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0),
-- Fatal Vanguard passive: Execute damage (flags[0] 0x20000000, the damage spell 20647 too) critical hits
(277991, 0, 4, 0x20000000, 0x0, 0x0, 0x10, 0x1, 0x2, 0x2, 0x0, 0x3, 0, 100, 0, 0),
-- Traumatic Wounds: own melee abilities landing (the script picks the listed ones)
(273713, 0, 0, 0x0, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ===== warrior-04 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummyfix_warrior_throw_weapon',
    'spell_dummyfix_warrior_titanic_power_removal', 'spell_dummyfix_warrior_damage_shield');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Throw Weapon enchant: teaches Throw Weapon 84467 while on
(84466, 'spell_dummyfix_warrior_throw_weapon'),
-- Titanic Power Removal: its expiry ends Titanic Power 986138
(300192, 'spell_dummyfix_warrior_titanic_power_removal'),
-- Blunt Force Trauma: Damage Shield deals more to a target bleeding from it
(59653, 'spell_dummyfix_warrior_damage_shield');

-- ===== warrior-05 / warrior-06 / warrior-07 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummyfix_warrior_shockwave_damage',
    'spell_dummyfix_warrior_executing_disembowel', 'spell_dummyfix_warrior_demolishing_strike',
    'spell_dummyfix_warrior_demolish', 'spell_dummyfix_warrior_devastating_pound', 'spell_dummyfix_warrior_stormhammer',
    'spell_dummyfix_warrior_sweeping_strikes', 'spell_dummyfix_warrior_heroic_leap_damage');
DELETE FROM `spell_script_names` WHERE `spell_id` IN (910300, 910320, 910340, 910360, 910380, 910400) AND `ScriptName` = 'spell_warr_bloodthirst';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Shockwave, Seismic Shockwave and the waves: ${$m3/100*$AP} damage from the dummy effect's percentage
(846968, 'spell_dummyfix_warrior_shockwave_damage'),
(846969, 'spell_dummyfix_warrior_shockwave_damage'),
(913415, 'spell_dummyfix_warrior_shockwave_damage'),
(913416, 'spell_dummyfix_warrior_shockwave_damage'),
(913418, 'spell_dummyfix_warrior_shockwave_damage'),
(913419, 'spell_dummyfix_warrior_shockwave_damage'),
(913421, 'spell_dummyfix_warrior_shockwave_damage'),
(913422, 'spell_dummyfix_warrior_shockwave_damage'),
(913424, 'spell_dummyfix_warrior_shockwave_damage'),
(913425, 'spell_dummyfix_warrior_shockwave_damage'),
(913427, 'spell_dummyfix_warrior_shockwave_damage'),
(913428, 'spell_dummyfix_warrior_shockwave_damage'),
(913430, 'spell_dummyfix_warrior_shockwave_damage'),
(913431, 'spell_dummyfix_warrior_shockwave_damage'),
-- Dawn/Dusk/Flame/Hail/Mana/Stormthirst (Bloodthirst copies): the stock Bloodthirst script (AP x m1% damage; the
-- dummy's m2% grants the 23885 healing buff)
(910300, 'spell_warr_bloodthirst'),
(910320, 'spell_warr_bloodthirst'),
(910340, 'spell_warr_bloodthirst'),
(910360, 'spell_warr_bloodthirst'),
(910380, 'spell_warr_bloodthirst'),
(910400, 'spell_warr_bloodthirst'),
-- Executing Disembowel: +30% against monsters
(273886, 'spell_dummyfix_warrior_executing_disembowel'),
-- Demolishing Strike applies Demolish (its stacks and empower: rev_20261122_dummysystem_melee.sql)
(947486, 'spell_dummyfix_warrior_demolishing_strike'),
(947487, 'spell_dummyfix_warrior_demolishing_strike'),
(947488, 'spell_dummyfix_warrior_demolishing_strike'),
(947489, 'spell_dummyfix_warrior_demolishing_strike'),
(947490, 'spell_dummyfix_warrior_demolishing_strike'),
(947491, 'spell_dummyfix_warrior_demolishing_strike'),
(947492, 'spell_dummyfix_warrior_demolishing_strike'),
(947493, 'spell_dummyfix_warrior_demolishing_strike'),
-- Devastating Pound: +5% per own Lacerate stack on the target
(285770, 'spell_dummyfix_warrior_devastating_pound'),
(285772, 'spell_dummyfix_warrior_devastating_pound'),
(285773, 'spell_dummyfix_warrior_devastating_pound'),
(285774, 'spell_dummyfix_warrior_devastating_pound'),
(285775, 'spell_dummyfix_warrior_devastating_pound'),
(285776, 'spell_dummyfix_warrior_devastating_pound'),
(285777, 'spell_dummyfix_warrior_devastating_pound'),
(285778, 'spell_dummyfix_warrior_devastating_pound'),
(285779, 'spell_dummyfix_warrior_devastating_pound'),
(997476, 'spell_dummyfix_warrior_devastating_pound'),
(997477, 'spell_dummyfix_warrior_devastating_pound'),
(997478, 'spell_dummyfix_warrior_devastating_pound'),
(997479, 'spell_dummyfix_warrior_devastating_pound'),
(997480, 'spell_dummyfix_warrior_devastating_pound'),
(1590438, 'spell_dummyfix_warrior_devastating_pound'),
(1590441, 'spell_dummyfix_warrior_devastating_pound'),
(1590442, 'spell_dummyfix_warrior_devastating_pound'),
(1590443, 'spell_dummyfix_warrior_devastating_pound'),
(1590444, 'spell_dummyfix_warrior_devastating_pound'),
(1590445, 'spell_dummyfix_warrior_devastating_pound'),
(1590446, 'spell_dummyfix_warrior_devastating_pound'),
(1590447, 'spell_dummyfix_warrior_devastating_pound'),
(1590448, 'spell_dummyfix_warrior_devastating_pound'),
(1590450, 'spell_dummyfix_warrior_devastating_pound'),
(1590451, 'spell_dummyfix_warrior_devastating_pound'),
(1590452, 'spell_dummyfix_warrior_devastating_pound'),
(1590453, 'spell_dummyfix_warrior_devastating_pound'),
(1590454, 'spell_dummyfix_warrior_devastating_pound'),
-- Stormhammer enchant: teaches Concussion Blow (Stormhammer) to a character knowing Concussion Blow
(977928, 'spell_dummyfix_warrior_stormhammer'),
-- Sweeping Swings: Critical Swings while Sweeping Strikes is up
(12328, 'spell_dummyfix_warrior_sweeping_strikes'),
(1112328, 'spell_dummyfix_warrior_sweeping_strikes'),
(1212328, 'spell_dummyfix_warrior_sweeping_strikes'),
-- Deadly Leap: Heroic Leap damage spells
(52174, 'spell_dummyfix_warrior_heroic_leap_damage'),
(254571, 'spell_dummyfix_warrior_heroic_leap_damage'),
(652174, 'spell_dummyfix_warrior_heroic_leap_damage');

-- ===== audit round 1 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummyfix_warrior_shockwave',
    'spell_dummyfix_warrior_stock_glyph_of_execution');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Shockwave and the elemental waves trigger both the plain and the Seismic wave: only one goes out (Seismic at 3
-- stacks of Seismic Shockwave 282303)
(46968, 'spell_dummyfix_warrior_shockwave'),
(913414, 'spell_dummyfix_warrior_shockwave'),
(913417, 'spell_dummyfix_warrior_shockwave'),
(913420, 'spell_dummyfix_warrior_shockwave'),
(913423, 'spell_dummyfix_warrior_shockwave'),
(913426, 'spell_dummyfix_warrior_shockwave'),
(913429, 'spell_dummyfix_warrior_shockwave'),
-- the stock Glyph of Execution aura linked from the classless glyph carries the classless glyph's 20 rage
(58367, 'spell_dummyfix_warrior_stock_glyph_of_execution');

-- ===== audit round 2 =====
-- Here Comes The Big One enchant: its own script instead of the generic enchant rules (stack per Bloodthirst cast; the
-- cast finding 3 stacks takes them and grants The Big One before its hit)
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 979768;
DELETE FROM `spell_script_names` WHERE `spell_id` = 979768;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(979768, 'spell_dummyfix_warrior_here_comes_the_big_one');
DELETE FROM `spell_proc` WHERE `SpellId` = 979768;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Bloodthirst (flags[1] 0x400) cast phase
(979768, 0, 4, 0x0, 0x400, 0x0, 0x10, 0x7, 0x1, 0x0, 0x0, 0x2, 0, 100, 0, 0);
