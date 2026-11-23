-- Warlock-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/warlock-*.md);
-- scripts in src/server/coa/AscensionDummyFixWarlock.cpp.

-- ===== warlock-01 =====
DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_warlock_%';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Gul'dan's Chosen (277151: Backdraft + Molten Core; 1578704: Backdraft): the buffs keep their charges meanwhile
(54274, 'spell_dummyfix_warlock_guldans_chosen'),
(54276, 'spell_dummyfix_warlock_guldans_chosen'),
(54277, 'spell_dummyfix_warlock_guldans_chosen'),
(1154274, 'spell_dummyfix_warlock_guldans_chosen'),
(1154276, 'spell_dummyfix_warlock_guldans_chosen'),
(1154277, 'spell_dummyfix_warlock_guldans_chosen'),
(47383, 'spell_dummyfix_warlock_guldans_chosen'),
(71162, 'spell_dummyfix_warlock_guldans_chosen'),
(71165, 'spell_dummyfix_warlock_guldans_chosen'),
-- Absolute Hellfire talent: only Flamestrike / Meteor damage marks the target (284790)
(284789, 'spell_dummyfix_warlock_absolute_hellfire'),
-- Drunken Brawler: 81308 each second only while drunk and unarmed
(81223, 'spell_dummyfix_warlock_drunken_brawler');

DELETE FROM `spell_proc` WHERE `SpellId` IN (284789, 1154274, 1154276, 1154277);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Absolute Hellfire: own spell damage, direct or periodic (the script keeps Flamestrike and Meteor)
(284789, 0, 0, 0x0, 0x0, 0x0, 0x50000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Reborn Backdraft buffs: charges taken by the proc system as stock 54274-54277 (their own spell masks), so that
-- Gul'dan's Chosen 1578704 can keep them (a charge dropped by Player::RemoveSpellMods cannot be prevented)
(1154274, 0, 5, 0x125, 0x310C0, 0x0, 0x0, 0x0, 0x1, 0x0, 0x8, 0, 0, 0, 0, 0),
(1154276, 0, 5, 0x165, 0x310C0, 0x0, 0x0, 0x0, 0x1, 0x0, 0x8, 0, 0, 0, 0, 0),
(1154277, 0, 5, 0x165, 0x310C0, 0x0, 0x0, 0x0, 0x1, 0x0, 0x8, 0, 0, 0, 0, 0);

-- Soul Link (Reborn 1469028): as stock 19028, the dummy effect hands the pet the split aura 1125228
DELETE FROM `spell_pet_auras` WHERE `spell` = 1469028;
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(1469028, 0, 0, 1125228);

-- Dark Harvest (enchant 1180950): a kill grants 3 stacks (dummyfix_warlock_player_hooks), not the generic rule's one
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 1180950 AND `effect` = 0 AND `rule` = 1;

-- ===== warlock-02 =====
DELETE FROM `spell_script_names` WHERE `spell_id` IN (81473, 282035) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Improved Healthstone (Reborn crossover enchant): carries the talent's rank 2 (1118693) while no rank is known
(1318693, 'spell_dummyfix_warlock_crossover'),
-- Soulbound: the demon's share scales with its health
(901303, 'spell_dummyfix_warlock_soulbound_split'),
-- Chilling Blows: Frostbrand Attack lengthens Deep Freeze or cuts its cooldown; talent: Deep Freeze damage -> 281538
(81213, 'spell_dummyfix_warlock_chilling_blows'),
(281535, 'spell_dummyfix_warlock_chilling_blows'),
-- Elemental Equilibrium: Fire / Frost / Nature essences -> buff
(285174, 'spell_dummyfix_warlock_elemental_equilibrium'),
(983228, 'spell_dummyfix_warlock_elemental_equilibrium'),
-- Chaos Manifesting: Chaos Bolt grants Fire (81474) or Shadow (81476) Empowerment (generic rule below)
(81473, 'spell_ascension_mystic_enchant_proc'),
(282035, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `spell_proc` WHERE `SpellId` IN (81213, 281535, 285174, 983228, 81473, 282035);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Chilling Blows: Frostbrand Attack / Deep Freeze damage, both triggered (the script picks them)
(81213, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(281535, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Elemental Equilibrium: own direct Fire / Frost / Nature spell damage
(285174, 28, 0, 0x0, 0x0, 0x0, 0x14110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(983228, 28, 0, 0x0, 0x0, 0x0, 0x14110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Chaos Manifesting: own spell casts (the rule keeps Chaos Bolt)
(81473, 0, 0, 0x0, 0x0, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(282035, 0, 0, 0x0, 0x0, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (81473, 282035);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(81473, 0, 0, 'cast', 0, '50796 59170 59171 59172', 100, 0, '', '', '', '', '81474 81476', 0, 0, 'Chaos Manifesting (enchant 81473): Chaos Bolt grants Fire or Shadow Empowerment (+10% for 8 sec)'),
(282035, 0, 0, 'cast', 0, '50796 59170 59171 59172', 100, 0, '', '', '', '', '81474 81476', 0, 0, 'Chaos Manifesting (talent 282035): Chaos Bolt grants Fire or Shadow Empowerment (+10% for 8 sec)');

-- Soulbound: as Soul Link, the dummy effect hands the demon the split aura 901303
DELETE FROM `spell_pet_auras` WHERE `spell` = 901302;
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(901302, 0, 0, 901303);

-- Ascension glyph copies: the core and stock scripts read the stock glyph aura (or its twin); each copy carries it
DELETE FROM `coa_mystic_enchant_aura_link` WHERE `enchant_spell` IN (118267, 118285, 118294, 118233, 118297, 118288);
INSERT INTO `coa_mystic_enchant_aura_link` (`enchant_spell`, `aura`, `grant_spell`, `comment`) VALUES
(118267, '118267', 56235, 'Glyph of Conflagrate 118267: Conflagrate keeps Immolate / Shadowflame (stock 56235, SpellEffects)'),
(118285, '118285', 56246, 'Glyph of Felguard 118285: Felguard total attack power +20% (stock 56246, StatSystem)'),
(118294, '118294', 56249, 'Glyph of Felhunter 118294: Devour Magic also heals the warlock (stock 56249, SpellEffects)'),
(118233, '118233', 56216, 'Glyph of Siphon Life 118233: Siphon Life heals 25% more (stock 56216, spell_warl_siphon_life)'),
(118297, '118297', 56250, 'Glyph of Succubus 118297: Seduction removes damage over time effects (stock 56250, spell_warl_seduction)');

-- ===== warlock-03 (the two-school enchants also cover warlock-04 / warlock-05) =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((271548, 'spell_dummyfix_warlock_immolating_backdraft'), (84589, 'spell_dummyfix_warlock_two_school'), (84655, 'spell_dummyfix_warlock_two_school'), (84623, 'spell_dummyfix_warlock_two_school'), (84593, 'spell_dummyfix_warlock_two_school'), (84579, 'spell_dummyfix_warlock_two_school'), (84635, 'spell_dummyfix_warlock_two_school'), (84629, 'spell_dummyfix_warlock_two_school'), (84659, 'spell_dummyfix_warlock_two_school'), (84617, 'spell_dummyfix_warlock_two_school'), (84581, 'spell_dummyfix_warlock_two_school'), (84631, 'spell_dummyfix_warlock_two_school'), (84583, 'spell_dummyfix_warlock_two_school'), (84585, 'spell_dummyfix_warlock_two_school'), (84653, 'spell_dummyfix_warlock_two_school'), (84641, 'spell_dummyfix_warlock_two_school'), (84619, 'spell_dummyfix_warlock_two_school'), (84611, 'spell_dummyfix_warlock_two_school'), (84649, 'spell_dummyfix_warlock_two_school'), (84625, 'spell_dummyfix_warlock_two_school'), (84587, 'spell_dummyfix_warlock_two_school'), (84621, 'spell_dummyfix_warlock_two_school'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Immolating Backdraft: Immolate grants the Backdraft buff of the talent held
(271548, 'spell_dummyfix_warlock_immolating_backdraft'),
-- two-school casting enchants: school A casts stack the school-B buff (286100-286106) and vice versa
(84589, 'spell_dummyfix_warlock_two_school'),
(84655, 'spell_dummyfix_warlock_two_school'),
(84623, 'spell_dummyfix_warlock_two_school'),
(84593, 'spell_dummyfix_warlock_two_school'),
(84579, 'spell_dummyfix_warlock_two_school'),
(84635, 'spell_dummyfix_warlock_two_school'),
(84629, 'spell_dummyfix_warlock_two_school'),
(84659, 'spell_dummyfix_warlock_two_school'),
(84617, 'spell_dummyfix_warlock_two_school'),
(84581, 'spell_dummyfix_warlock_two_school'),
(84631, 'spell_dummyfix_warlock_two_school'),
(84583, 'spell_dummyfix_warlock_two_school'),
(84585, 'spell_dummyfix_warlock_two_school'),
(84653, 'spell_dummyfix_warlock_two_school'),
(84641, 'spell_dummyfix_warlock_two_school'),
(84619, 'spell_dummyfix_warlock_two_school'),
(84611, 'spell_dummyfix_warlock_two_school'),
(84649, 'spell_dummyfix_warlock_two_school'),
(84625, 'spell_dummyfix_warlock_two_school'),
(84587, 'spell_dummyfix_warlock_two_school'),
(84621, 'spell_dummyfix_warlock_two_school');

DELETE FROM `spell_proc` WHERE `SpellId` IN (271548, 84589, 84655, 84623, 84593, 84579, 84635, 84629, 84659, 84617, 84581, 84631, 84583, 84585, 84653, 84641, 84619, 84611, 84649, 84625, 84587, 84621);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Immolating Backdraft: own Immolate cast (0x4)
(271548, 0, 5, 0x4, 0x0, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- two-school enchants: own spell / ability casts (the script keeps damaging ones of the two schools)
(84589, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84655, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84623, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84593, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84579, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84635, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84629, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84659, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84617, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84581, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84631, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84583, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84585, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84653, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84641, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84619, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84611, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84649, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84625, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84587, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(84621, 0, 0, 0x0, 0x0, 0x0, 0x14110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

-- Glyph of Voidwalker 118288: Voidwalker total Stamina +20% (stock 56247, spell_warl_voidwalker_pet_passive)
DELETE FROM `coa_mystic_enchant_aura_link` WHERE `enchant_spell` IN (118288);
INSERT INTO `coa_mystic_enchant_aura_link` (`enchant_spell`, `aura`, `grant_spell`, `comment`) VALUES
(118288, '118288', 56247, 'Glyph of Voidwalker 118288: Voidwalker total Stamina +20% (stock 56247)');

-- ===== warlock-04 .. warlock-07 =====
DELETE FROM `spell_script_names` WHERE `spell_id` IN (918213, 284732, 982593, 1588003) AND `ScriptName` IN ('spell_warl_improved_drain_soul', 'spell_warl_haunt');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Improved Drain Soul enchant 918213: as stock 18213 (7% maximum mana when the drained target dies)
(918213, 'spell_warl_improved_drain_soul'),
-- Improved Fear (Reborn crossover enchant): carries the talent's rank 2 (1153759) while no rank is known
(1353759, 'spell_dummyfix_warlock_crossover'),
-- "If you know X you learn Y": Psychic Barrage, Chaos Burn, Shadow Waste Bolt
(84410, 'spell_dummyfix_warlock_learn_with'),
(997020, 'spell_dummyfix_warlock_learn_with'),
(982330, 'spell_dummyfix_warlock_learn_with'),
-- Unstable Void: the stock Backdraft buffs cut no cast time while the enchant (and Backdraft rank 3) is held
(54274, 'spell_dummyfix_warlock_unstable_void'),
(54276, 'spell_dummyfix_warlock_unstable_void'),
(54277, 'spell_dummyfix_warlock_unstable_void'),
-- Wraith: as Haunt, the direct damage is stored in the dummy (effect 1) and heals the warlock when it ends (48210)
(284732, 'spell_warl_haunt'),
(982593, 'spell_warl_haunt'),
(1588003, 'spell_warl_haunt'),
-- Ghastly Wraith: Vanish -10 sec, Shadow Dance -2 sec on apply
(982598, 'spell_dummyfix_warlock_ghastly_wraith'),
-- Burning Rush: the health drain
(954806, 'spell_dummyfix_warlock_burning_rush'),
(2304806, 'spell_dummyfix_warlock_burning_rush'),
-- Soul Harvest: +3 sec per afflicted enemy, at most 24 sec
(86395, 'spell_dummyfix_warlock_soul_harvest'),
(1436395, 'spell_dummyfix_warlock_soul_harvest'),
-- Blind Rage: the per-second rage only while disoriented (the miss proc is Contracts + spell_proc)
(81477, 'spell_dummyfix_warlock_blind_rage'),
-- Soul Siphoner: the Haunt heal also heals the 3 lowest party / raid members
(48210, 'spell_dummyfix_warlock_soul_siphoner'),
(1148210, 'spell_dummyfix_warlock_soul_siphoner'),
-- Siphon Life (863108): Corruption damage heals 20%, at most 5% of maximum health
(863108, 'spell_dummyfix_warlock_siphon_life');

DELETE FROM `spell_proc` WHERE `SpellId` IN (918213, 81477, 863108);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Improved Drain Soul enchant: as stock -18213 (a kill while Drain Soul, 0x4000, is channelled)
(918213, 32, 5, 0x4000, 0x0, 0x0, 0x2, 0x0, 0x0, 0x0, 0x0, 0, 0, 0, 0, 0),
-- Blind Rage: own melee swings and melee abilities that miss
(81477, 0, 0, 0x0, 0x0, 0x0, 0x14, 0x0, 0x2, 0x4, 0x0, 0, 0, 100, 0, 0),
-- Siphon Life (863108): Corruption (0x2) damage, as stock 63108
(863108, 0, 5, 0x2, 0x0, 0x0, 0x50000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- Hellish Pursuit (983065): its Hellfire Pursuit pulses (effect 1 -> 983066) had no proc rule and never started;
-- casting Burning Rush (0x04000000 in mask 2) starts them
DELETE FROM `spell_proc` WHERE `SpellId` = 983065;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(983065, 0, 5, 0x0, 0x0, 0x4000000, 0x5400, 0x7, 0x1, 0x0, 0x0, 0x1, 0, 100, 0, 0);
