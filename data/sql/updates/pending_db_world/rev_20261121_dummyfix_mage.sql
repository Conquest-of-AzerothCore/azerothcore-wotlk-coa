-- Mage-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/mage-01.md);
-- scripts in src/server/coa/AscensionDummyFixMage.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_mage_%';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Frost Bomb: explodes into its explosion spell on expiry or dispel
(271936, 'spell_dummyfix_mage_frost_bomb'),
(954263, 'spell_dummyfix_mage_frost_bomb'),
(1569556, 'spell_dummyfix_mage_frost_bomb'),
-- Fire Walk With Me: Flamestrike's ally speed area only with the talent / enchant
(283021, 'spell_dummyfix_mage_fire_walk_with_me'),
-- Time Bomb / Touch of the Magi: store 50% of the caster's Arcane damage, explode at the end
(284591, 'spell_dummyfix_mage_stored_bomb'),
(1587677, 'spell_dummyfix_mage_stored_bomb'),
-- Ice Barrage: Icicles from the listed Frost spells, launched by Ice Lance
(272427, 'spell_dummyfix_mage_ice_barrage'),
-- Timed Charge: the Alter Time return explodes (954637 damage formula)
(86401, 'spell_dummyfix_mage_timed_charge'),
(1436401, 'spell_dummyfix_mage_timed_charge'),
(954637, 'spell_dummyfix_mage_timed_charge_damage'),
-- Doused: the mage's Lightning Bolt / Chain Lightning electrocutes
(954376, 'spell_dummyfix_mage_doused');

DELETE FROM `spell_proc` WHERE `SpellId` IN (284591, 1587677, 272427, 954376, 978432);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Time Bomb / Touch of the Magi (on the target): Arcane damage taken, direct or periodic, triggered spells included
-- (Arcane Missiles); the script keeps only the bomb caster's damage
(284591, 64, 0, 0x0, 0x0, 0x0, 0xA2220, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(1587677, 64, 0, 0x0, 0x0, 0x0, 0xA2220, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Ice Barrage: own spell damage, direct or periodic (Ray of Frost); the script picks the listed spells and Ice Lance
(272427, 0, 0, 0x0, 0x0, 0x0, 0x50000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Doused (on the target): Lightning Bolt (0x1) / Chain Lightning (0x2) damage taken; the script keeps the mage's own
(954376, 0, 11, 0x3, 0x0, 0x0, 0x20000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Touch of Death: one charge, spent by the Vampiric Touch (priest 0x400 in mask 1) it empowers
(978432, 0, 6, 0x0, 0x400, 0x0, 0x10000, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 1);

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (64353, 64357, 979765, 1575104) AND `type` = 2 AND
    `spell_effect` IN (64349, 64350, 44440, 44441, 275397);
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
-- Fiery Payback: the talent carries its disarm proc (64350 / 64349, 5% / 10%) and its below-35%-health aura
-- (44440 / 44441, CasterAuraState 13)
(64353, 64350, 2, 'Fiery Payback rank 1: disarm proc'),
(64353, 44440, 2, 'Fiery Payback rank 1: below 35% health'),
(64357, 64349, 2, 'Fiery Payback rank 2: disarm proc'),
(64357, 44441, 2, 'Fiery Payback rank 2: below 35% health'),
-- Hot Hands: Pyroblast can trigger Hot Streak (spell_mage_hot_streak reads 275397 "Hot Hands")
(979765, 275397, 2, 'Hot Hands (enchant 979765): Pyroblast triggers Hot Streak'),
(1575104, 275397, 2, 'Hot Hands (Reborn enchant 1575104): Pyroblast triggers Hot Streak');

-- ---- chunk 2 (tools/dummy_census/fix-batches/mage-02.md)
-- (the spell_script_names DELETE at the top of this file already clears every spell_dummyfix_mage_% row)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((277555, 'spell_dummyfix_mage_battle_glaive'), (81255, 'spell_dummyfix_mage_final_shield'), (281638, 'spell_dummyfix_mage_final_shield'), (81521, 'spell_dummyfix_mage_dancer_in_the_dark'), (282118, 'spell_dummyfix_mage_dancer_in_the_dark'), (61346, 'spell_dummyfix_mage_natures_grace_enchant_gate'), (284711, 'spell_dummyfix_mage_abjurers_ward_arcane'), (982567, 'spell_dummyfix_mage_abjurers_ward_arcane'), (276006, 'spell_dummyfix_mage_clad_in_frost'), (276011, 'spell_dummyfix_mage_clad_in_frost_buff'), (81520, 'spell_dummyfix_mage_growing_light'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Battle Glaive: Warrior direct damage abilities count up 277556, then cast 277557
(277555, 'spell_dummyfix_mage_battle_glaive'),
-- Final Shield: Power Word: Shield on an ally below 20% health removes crowd control
(81255, 'spell_dummyfix_mage_final_shield'),
(281638, 'spell_dummyfix_mage_final_shield'),
-- Dancer in the Dark: Shadow Dance recovers twice as fast in stealth
(81521, 'spell_dummyfix_mage_dancer_in_the_dark'),
(282118, 'spell_dummyfix_mage_dancer_in_the_dark'),
-- Natural Destruction (enchant 410400): Nature's Grace rank 3's 410401 effect only with the enchant
(61346, 'spell_dummyfix_mage_natures_grace_enchant_gate'),
-- Abjurer's Ward: Arcane: Ward absorbs take 10 sec off Presence of Mind
(284711, 'spell_dummyfix_mage_abjurers_ward_arcane'),
(982567, 'spell_dummyfix_mage_abjurers_ward_arcane'),
-- Clad in Frost: Ice Barrier / Icebound Fortitude grant 276011; Frost casts under it cast 299151
(276006, 'spell_dummyfix_mage_clad_in_frost'),
(276011, 'spell_dummyfix_mage_clad_in_frost_buff'),
-- Growing Light: Holy Light / Flash of Light on the own Beacon of Light target casts 977990
(81520, 'spell_dummyfix_mage_growing_light');

DELETE FROM `spell_proc` WHERE `SpellId` IN (277555, 81255, 281638, 284711, 982567, 276006, 276011, 81520);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Battle Glaive: Warrior melee / ranged class abilities that deal damage (the script skips "on next swing" ones)
(277555, 0, 4, 0x0, 0x0, 0x0, 0x110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Final Shield: Power Word: Shield (priest 0x1) landing; 30 sec between removals
(81255, 0, 6, 0x1, 0x0, 0x0, 0x4000, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 30000, 0),
(281638, 0, 6, 0x1, 0x0, 0x0, 0x4000, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 30000, 0),
-- Abjurer's Ward: Arcane: any damage taken that was (partly) absorbed; the script requires a Fire / Frost Ward of
-- the damage's school
(284711, 0, 0, 0x0, 0x0, 0x0, 0xA22A8, 0x1, 0x2, 0x400, 0x2, 0, 0, 100, 0, 0),
(982567, 0, 0, 0x0, 0x0, 0x0, 0xA22A8, 0x1, 0x2, 0x400, 0x2, 0, 0, 100, 0, 0),
-- Clad in Frost: own positive spell casts (the script picks Ice Barrier / Icebound Fortitude)
(276006, 0, 0, 0x0, 0x0, 0x0, 0x4400, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Clad in Frost (buff): own Frost spell and ability casts
(276011, 16, 0, 0x0, 0x0, 0x0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Growing Light: Holy Light (0x80000000) / Flash of Light (0x40000000) heals landing
(81520, 0, 10, 0xC0000000, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ---- chunk 3 (tools/dummy_census/fix-batches/mage-03.md)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((58832, 'spell_dummyfix_mage_mirror_image_glyph'), (118657, 'spell_dummyfix_mage_glyph_of_arcane_blast'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Glyph of Mirror Image (classless 118704): the 4th copy
(58832, 'spell_dummyfix_mage_mirror_image_glyph'),
-- Glyph of Arcane Blast (classless 118657): cast time cut per Arcane Blast stack
(118657, 'spell_dummyfix_mage_glyph_of_arcane_blast');

DELETE FROM `spell_proc` WHERE `SpellId` IN (118657, 274985, 274984, 272448);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Glyph of Arcane Blast: Arcane Blast (0x20000000) landing re-reads the Arcane Blast buff's stacks
(118657, 0, 3, 0x20000000, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Solar Bomber: Fireball (0x1) / Pyroblast (0x400000) damage grants Lunar Flames
(274985, 0, 3, 0x400001, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Lunar Bomber: Starfire (0x4) / Starsurge (0x80000 in mask 2) damage grants Solar Flames
(274984, 0, 7, 0x4, 0x0, 0x80000, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Frostflame Shock! (272448): one charge, spent by the Frostflame Shock (0x20000000 in mask 1) cast
(272448, 0, 11, 0x0, 0x20000000, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 1);

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (118346, 118322) AND `spell_effect` IN (56377, 56369) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
-- the classless glyphs carry the stock glyph the core reads (Unit.cpp: GetAuraEffectOfRankedSpellOrTwin 56377 / 56369);
-- the data of each pair is identical
(118346, 56377, 2, 'Glyph of Ice Lance (classless 118346): Ice Lance 5x on higher-level frozen targets'),
(118322, 56369, 2, 'Glyph of Fire Blast (classless 118322): guaranteed crit on stunned / incapacitated targets');

-- ---- chunk 4 (tools/dummy_census/fix-batches/mage-04.md)
-- (Molten Mind / Nimble Mind / Bulwark / Lei Shen's Legacy replacements are Contracts data fixes; Bulwark's energy,
-- Lei Shen's Volatile Discharge and the Missile Barrage blocker are unit hooks)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((982725, 'spell_dummyfix_mage_hydricles_enchant'), (982726, 'spell_dummyfix_mage_hydricles'), (1583493, 'spell_dummyfix_mage_carbon_buildup'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Hydricles: the enchant teaches 982726 to a Frostbolt owner; the cast consumes every Fingers of Frost stack
(982725, 'spell_dummyfix_mage_hydricles_enchant'),
(982726, 'spell_dummyfix_mage_hydricles'),
-- Carbon Buildup: the next Fireball casts a second Fireball
(1583493, 'spell_dummyfix_mage_carbon_buildup');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1583493);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Carbon Buildup: the next own Fireball (0x1) cast; one charge
(1583493, 0, 3, 0x1, 0x0, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 1);

-- ---- chunk 5 (tools/dummy_census/fix-batches/mage-05.md)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((954525, 'spell_dummyfix_mage_earthquake_tick'), (954576, 'spell_dummyfix_mage_earthquake_tick'), (954577, 'spell_dummyfix_mage_earthquake_tick'), (954578, 'spell_dummyfix_mage_earthquake_tick'), (954579, 'spell_dummyfix_mage_earthquake_tick'), (954580, 'spell_dummyfix_mage_earthquake_tick'), (954581, 'spell_dummyfix_mage_earthquake_tick'), (284614, 'spell_dummyfix_mage_earthquake_tick'), (284928, 'spell_dummyfix_mage_earthquake_tick'), (2304576, 'spell_dummyfix_mage_earthquake_tick'), (2304577, 'spell_dummyfix_mage_earthquake_tick'), (979122, 'spell_dummyfix_mage_glacial_spike'), (1504646, 'spell_dummyfix_mage_focus_magic_reborn'), (271193, 'spell_dummyfix_mage_fiery_shield'), (271203, 'spell_dummyfix_mage_cauterizing_embers'), (1100543, 'spell_dummyfix_mage_frost_warding_enchant'), (1106143, 'spell_dummyfix_mage_frost_warding_enchant'), (1108457, 'spell_dummyfix_mage_frost_warding_enchant'), (1108458, 'spell_dummyfix_mage_frost_warding_enchant'), (1108461, 'spell_dummyfix_mage_frost_warding_enchant'), (1108462, 'spell_dummyfix_mage_frost_warding_enchant'), (1110177, 'spell_dummyfix_mage_frost_warding_enchant'), (1110223, 'spell_dummyfix_mage_frost_warding_enchant'), (1110225, 'spell_dummyfix_mage_frost_warding_enchant'), (1127128, 'spell_dummyfix_mage_frost_warding_enchant'), (1128609, 'spell_dummyfix_mage_frost_warding_enchant'), (1132796, 'spell_dummyfix_mage_frost_warding_enchant'), (1143010, 'spell_dummyfix_mage_frost_warding_enchant'), (1143012, 'spell_dummyfix_mage_frost_warding_enchant'), (1556015, 'spell_dummyfix_mage_esoteric_power'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Earthquake ticks: the stun trigger only at max Trembling stacks and without a 10 sec stun ICD marker
(954525, 'spell_dummyfix_mage_earthquake_tick'),
(954576, 'spell_dummyfix_mage_earthquake_tick'),
(954577, 'spell_dummyfix_mage_earthquake_tick'),
(954578, 'spell_dummyfix_mage_earthquake_tick'),
(954579, 'spell_dummyfix_mage_earthquake_tick'),
(954580, 'spell_dummyfix_mage_earthquake_tick'),
(954581, 'spell_dummyfix_mage_earthquake_tick'),
(284614, 'spell_dummyfix_mage_earthquake_tick'),
(284928, 'spell_dummyfix_mage_earthquake_tick'),
(2304576, 'spell_dummyfix_mage_earthquake_tick'),
(2304577, 'spell_dummyfix_mage_earthquake_tick'),
-- Glacial Spike: Frostbite on enemies out of combat (with Frostbite's final rank)
(979122, 'spell_dummyfix_mage_glacial_spike'),
-- Focus Magic (Reborn copy): the target's crits give the caster 1154648
(1504646, 'spell_dummyfix_mage_focus_magic_reborn'),
-- Flamestrike's Fiery Shield only at 5 Flames of the Apostate stacks; Cauterizing Embers only with 271210
(271193, 'spell_dummyfix_mage_fiery_shield'),
(271203, 'spell_dummyfix_mage_cauterizing_embers'),
-- Frost Warding (Reborn crossover enchant): Reborn Fire / Frost Ward ranks
(1100543, 'spell_dummyfix_mage_frost_warding_enchant'),
(1106143, 'spell_dummyfix_mage_frost_warding_enchant'),
(1108457, 'spell_dummyfix_mage_frost_warding_enchant'),
(1108458, 'spell_dummyfix_mage_frost_warding_enchant'),
(1108461, 'spell_dummyfix_mage_frost_warding_enchant'),
(1108462, 'spell_dummyfix_mage_frost_warding_enchant'),
(1110177, 'spell_dummyfix_mage_frost_warding_enchant'),
(1110223, 'spell_dummyfix_mage_frost_warding_enchant'),
(1110225, 'spell_dummyfix_mage_frost_warding_enchant'),
(1127128, 'spell_dummyfix_mage_frost_warding_enchant'),
(1128609, 'spell_dummyfix_mage_frost_warding_enchant'),
(1132796, 'spell_dummyfix_mage_frost_warding_enchant'),
(1143010, 'spell_dummyfix_mage_frost_warding_enchant'),
(1143012, 'spell_dummyfix_mage_frost_warding_enchant'),
-- Esoteric Power: Arcane Blast's chance per buff stack to deal 15% again
(1556015, 'spell_dummyfix_mage_esoteric_power');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1504646, 1556015);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Focus Magic (Reborn): as stock 54646 -- the target's spell crits (DBC proc flags)
(1504646, 0, 0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x2, 0x2, 0x0, 0, 0, 0, 0, 0),
-- Esoteric Power: Arcane Blast (0x20000000) damage
(1556015, 0, 3, 0x20000000, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ---- chunk 6 (tools/dummy_census/fix-batches/mage-06.md)
-- (Doomhammer's Fury, Shattered Barrier and Spell Slinger are unit hooks; Scared stiff is a Contracts data fix)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((44461, 'spell_dummyfix_mage_living_bomb_explosion'), (44514, 'spell_dummyfix_mage_living_bomb_explosion'), (44515, 'spell_dummyfix_mage_living_bomb_explosion'), (55361, 'spell_dummyfix_mage_living_bomb_explosion'), (55362, 'spell_dummyfix_mage_living_bomb_explosion'), (1144461, 'spell_dummyfix_mage_living_bomb_explosion'), (984696, 'spell_dummyfix_mage_saber_fangs'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Critical Time: Living Bomb explosions apply Chain Reaction to every target hit
(44461, 'spell_dummyfix_mage_living_bomb_explosion'),
(44514, 'spell_dummyfix_mage_living_bomb_explosion'),
(44515, 'spell_dummyfix_mage_living_bomb_explosion'),
(55361, 'spell_dummyfix_mage_living_bomb_explosion'),
(55362, 'spell_dummyfix_mage_living_bomb_explosion'),
(1144461, 'spell_dummyfix_mage_living_bomb_explosion'),
-- Saber Fangs: Swipe (Cat) hits count up 984697, then apply 984698
(984696, 'spell_dummyfix_mage_saber_fangs');

DELETE FROM `spell_proc` WHERE `SpellId` IN (984696);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Saber Fangs: Swipe (Cat) (0x400 in mask 2) damage, per target hit
(984696, 0, 7, 0x0, 0x0, 0x400, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ---- test-round fixes
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((44440, 'spell_dummyfix_mage_fiery_payback_low_health'), (44441, 'spell_dummyfix_mage_fiery_payback_low_health'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Fiery Payback: the below-35%-health auras carry their values only below 35% health
(44440, 'spell_dummyfix_mage_fiery_payback_low_health'),
(44441, 'spell_dummyfix_mage_fiery_payback_low_health');
