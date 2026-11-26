-- Druid-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/druid-01.md);
-- scripts in src/server/coa/AscensionDummyFixDruid.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_druid_%';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (84375, 81455) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 118055 AND `ScriptName` = 'spell_dru_glyph_of_starfire_dummy';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Overflow: an extra party/raid member is healed for s1% by 954283
(273415, 'spell_dummyfix_druid_overflow'),
(977710, 'spell_dummyfix_druid_overflow'),
-- Garden of Growth: at the stack threshold the druid's Living Seeds in range bloom without being used up
(84376, 'spell_dummyfix_druid_garden_of_growth'),
(282189, 'spell_dummyfix_druid_garden_of_growth'),
-- Garden of Growth enchant 84375: its Healing Touch crit trigger had no proc rule (generic rule below)
(84375, 'spell_ascension_mystic_enchant_proc'),
-- Fury of the King: physical Rake / Rip ticks deal s1% again
(278659, 'spell_dummyfix_druid_fury_of_the_king'),
-- Goldrinn's Guile: finishers, chance per combo point
(275743, 'spell_dummyfix_druid_goldrinns_guile'),
-- Glyph of Starfire 118055: the stock Glyph of Starfire (54845) proc -> 54846 (+3 sec Moonfire, up to +9 sec)
(118055, 'spell_dru_glyph_of_starfire_dummy'),
-- Pious Strikes enchant 81455: Hammer of the Righteous / Avenger's Shield cast 282013 (generic rule below)
(81455, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `spell_proc` WHERE `SpellId` IN (273415, 977710, 84375, 278659, 275743, 118055, 81455);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Overflow: own non-triggered direct Nature heals landing (the script checks cast time / Healing Touch)
(273415, 8, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(977710, 8, 7, 0x20, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Garden of Growth enchant: as talent 282188's row (the rule picks Healing Touch criticals)
(84375, 0, 0, 0x0, 0x0, 0x0, 0x55550, 0x0, 0x3, 0x0, 0x2, 0, 0, 0, 0, 0),
-- Fury of the King: Rake (0x1000) / Rip (0x800000) ticks; the script rolls the per-stack chance
(278659, 1, 7, 0x801000, 0x0, 0x0, 0x40000, 0x1, 0x3, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Goldrinn's Guile: any own non-triggered spell cast; the script keeps finishing moves and rolls per combo point
(275743, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Glyph of Starfire: as stock 54845 (Starfire damage)
(118055, 0, 7, 0x4, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 0, 0, 0),
-- Pious Strikes enchant: as talent 282014's row
(81455, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x0, 0x3, 0x0, 0x2, 0, 0, 0, 0, 0);

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (84375, 81455);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(84375, 0, 0, 'critical_heal', 0, '5185 5186 5187 5188 5189 6778 8903 9758 9888 9889 25297 26978 26979 28719 48377 48378 147256 254122 374607 995185 1105185 1105186 1105187 1105188 1105189 1106778 1108903 1109758 1109888 1109889 1125297 1126978 1126979 1128719 1148377 1148378 1405687 10005187', 100, 0, '', '', '', '', '', 0, 0, 'Garden of Growth (enchant 84375): a Healing Touch critical puts a Garden of Growth stack (84376) on the target'),
(81455, 0, 0, 'cast', 0, '31935 31947 32699 32700 48826 48827 53595', 100, 0, '', '', 'stacks:274207=0 stacks:274209=0 stacks:978209=0 stacks:978429=0', '', '282013', 0, 0, 'Pious Strikes (enchant 81455): Hammer of the Righteous / Avenger''s Shield unleash Pious Strikes (282013) on the target; not with Dark Surgeon');

-- Fury of the King (talent 278660): effect 1 applied the duplication aura 278659 on 20% of Rake / Rip ticks (with
-- stacks), a second gate in front of 278659's own per-stack roll. The tooltip ties both to the finisher: 278659 now
-- comes with the 278661 stack, on a finishing move used during Berserk (as effect 0's rule).
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 278660 AND `effect` = 1;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(278660, 1, 0, 'cast', 0, '1079 1080 1081 9492 9493 9752 9894 9896 22568 22570 22827 22828 22829 24248 27008 31018 48576 48577 49799 49800 49802 52610 62071 300905 300906 300907 1152610 1162071', 100, 0, '50334', '', '', '', '', 0, 0, 'Fury of the King (enchant 1725423): the damage duplication aura 278659 comes with each stack');

-- Goldrinn's Guile buff 275755: the empowered Mind Blast (0x2000) / Vampiric Touch (0x400 in mask 1) grants 2 combo
-- points and 40 Energy (275754), and it is the "next" one: one charge, taken once the spell lands
DELETE FROM `spell_proc` WHERE `SpellId` = 275755;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(275755, 0, 6, 0x2000, 0x400, 0x0, 0x10000, 0x7, 0x2, 0x0, 0x8, 0, 0, 100, 0, 1);

-- ===== druid-02 =====
DELETE FROM `spell_script_names` WHERE `spell_id` = 1511336 AND `ScriptName` = 'spell_dru_survival_instincts';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (983374, 982678, 1587841, 1587797) AND `ScriptName` = 'spell_dru_starfall_dummy';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Nature's Fervor: a full-stack Lacerate grants 272293
(272282, 'spell_dummyfix_druid_natures_fervor'),
-- Eclipse talents (Wrath of the Sun, Total Solar / Lunar Eclipse, Lunar Frenzy): the Eclipse auras carry their buffs
(48517, 'spell_dummyfix_druid_eclipse'),
(48518, 'spell_dummyfix_druid_eclipse'),
-- Survival Instincts 1511336: as stock 61336 (form-only, s1% of maximum health as 50322 for the duration)
(1511336, 'spell_dru_survival_instincts'),
-- Frostfall / Shadowfall stars: as stock Starfall 50286 (2 random enemies in line of sight, casts the value's spell)
(983374, 'spell_dru_starfall_dummy'),
(982678, 'spell_dru_starfall_dummy'),
(1587841, 'spell_dru_starfall_dummy'),
(1587797, 'spell_dru_starfall_dummy');

DELETE FROM `spell_proc` WHERE `SpellId` = 272282;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Nature's Fervor: Lacerate (mask 1 0x100) landing
(272282, 0, 7, 0x0, 0x100, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ===== druid-03 =====
DELETE FROM `spell_script_names` WHERE `spell_id` IN (983369, 1587885) AND `ScriptName` = 'spell_dru_starfall_dummy';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- High Winds: the druid's Cyclone ending applies 954127
(33786, 'spell_dummyfix_druid_cyclone'),
-- Ursoc's Blessing: the Bear / Dire Bear Form passive's armor and Stamina outlast the form by 3 sec
(1178, 'spell_dummyfix_druid_bear_form_passive'),
(9635, 'spell_dummyfix_druid_bear_form_passive'),
-- Firefall stars: as stock Starfall 50286
(983369, 'spell_dru_starfall_dummy'),
(1587885, 'spell_dru_starfall_dummy'),
-- Lunar Fire: Eclipse (Lunar) not during its 30 sec marker 48520 or an Eclipse
(274980, 'spell_dummyfix_druid_lunar_fire');
-- Glyph of Nourish 118849: stock spell_dru_nourish already counts it (GetAuraEffectOfRankedSpellOrTwin(62971));
-- binding spell_dummyfix_druid_nourish too doubled the bonus (measured x1.69), so it stays unbound.

DELETE FROM `spell_proc` WHERE `SpellId` IN (284006, 274980);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Covering Crown (made a trigger aura in the Contracts): own Rejuvenation (0x10) landing
(284006, 0, 7, 0x10, 0x0, 0x0, 0x4000, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Lunar Fire: direct Fire damage
(274980, 4, 0, 0x0, 0x0, 0x0, 0x11110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ===== druid-04 =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((273425, 'spell_dummyfix_druid_healing_seeds'), (287852, 'spell_dummyfix_druid_photosynthesis'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Healing Seeds: non-critical Healing Touch plants a Living Seed (Living Seed rank's chance and percent)
(273425, 'spell_dummyfix_druid_healing_seeds'),
-- Photosynthesis: Nature periodic heals on a Lifebloomed ally may bloom it without using it up
(287852, 'spell_dummyfix_druid_photosynthesis');

DELETE FROM `spell_proc` WHERE `SpellId` IN (273425, 287852);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Healing Seeds: own Healing Touch (0x20) landing without a critical (the script rolls Living Seed's chance)
(273425, 0, 7, 0x20, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x1, 0x0, 0, 0, 100, 0, 0),
-- Photosynthesis: own Nature periodic heal ticks, the talent's 20%
(287852, 8, 0, 0x0, 0x0, 0x0, 0x40000, 0x2, 0x2, 0x0, 0x0, 0, 0, 20, 0, 0);

-- ===== druid-05 =====
-- Demonic Mind 977940 / Frozen Mind 977939: made override auras in the Contracts (the enchant replacement does the rest)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((977954, 'spell_dummyfix_druid_learn_with'), (990287, 'spell_dummyfix_druid_learn_with'), (911166, 'spell_dummyfix_druid_providing_for_nature'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- "If you know X you learn Y": Light of Justice, Neltharion's Legacy
(977954, 'spell_dummyfix_druid_learn_with'),
(990287, 'spell_dummyfix_druid_learn_with'),
-- Providing for Nature: roots / grasp / Mass Entanglement / Hypnosis casts grant Nature's Grace
(911166, 'spell_dummyfix_druid_providing_for_nature');

DELETE FROM `spell_proc` WHERE `SpellId` = 911166;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Providing for Nature: own non-triggered spell casts (the script picks the four)
(911166, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ===== druid-06 =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((977807, 'spell_dummyfix_druid_learn_with'), (954550, 'spell_dummyfix_druid_learn_with'), (-339, 'spell_dummyfix_druid_entangling_roots'), (18562, 'spell_dummyfix_druid_swiftmend'), (273348, 'spell_dummyfix_druid_bloom'), (1571884, 'spell_dummyfix_druid_bloom'), (16858, 'spell_dummyfix_druid_feral_aggression'), (16859, 'spell_dummyfix_druid_feral_aggression'), (16860, 'spell_dummyfix_druid_feral_aggression'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- "If you know X you learn Y": Spirit of the Forest, Staggering Shout
(977807, 'spell_dummyfix_druid_learn_with'),
(954550, 'spell_dummyfix_druid_learn_with'),
-- Suffocating Roots: a dispelled Entangling Roots (all ranks) is cast on the dispeller
(-339, 'spell_dummyfix_druid_entangling_roots'),
-- Everliving: Swiftmend uses up the 15-stack proc
(18562, 'spell_dummyfix_druid_swiftmend'),
-- Bloom: only allies with the druid's Seed of Life
(273348, 'spell_dummyfix_druid_bloom'),
(1571884, 'spell_dummyfix_druid_bloom'),
-- Feral Aggression: feral attack power from the level
(16858, 'spell_dummyfix_druid_feral_aggression'),
(16859, 'spell_dummyfix_druid_feral_aggression'),
(16860, 'spell_dummyfix_druid_feral_aggression');

-- ===== druid-07 =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((2110051, 'spell_dummyfix_druid_chosen_of_elune'), (276203, 'spell_dummyfix_druid_carnage_incarnate'), (983668, 'spell_dummyfix_druid_oracles_blessing'), (768, 'spell_dummyfix_druid_cat_form'), (281916, 'spell_dummyfix_druid_faerie_swarm'), (81402, 'spell_dummyfix_druid_faerie_swarm'), (977972, 'spell_dummyfix_druid_temporal_shift'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Chosen of Elune: activates both Eclipses
(2110051, 'spell_dummyfix_druid_chosen_of_elune'),
-- Carnage Incarnate: double duration in Bear Form
(276203, 'spell_dummyfix_druid_carnage_incarnate'),
-- Oracle's Blessing: resets Holy Shock and Riptide
(983668, 'spell_dummyfix_druid_oracles_blessing'),
-- Cat-a-clysmic Entrance: Cat Form at 5 stacks unleashes Cat-a-clysm without a global cooldown
(768, 'spell_dummyfix_druid_cat_form'),
-- Faerie Swarm: Faerie Fire (Feral) applies Insect Swarm
(281916, 'spell_dummyfix_druid_faerie_swarm'),
(81402, 'spell_dummyfix_druid_faerie_swarm'),
-- Temporal Shift: Temporal Blast, Lunar Eclipse damage
(977972, 'spell_dummyfix_druid_temporal_shift');

DELETE FROM `spell_proc` WHERE `SpellId` IN (281916, 81402);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Faerie Swarm: Faerie Fire (Feral) (0x400) landing
(281916, 0, 7, 0x400, 0x0, 0x0, 0x15550, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(81402, 0, 7, 0x400, 0x0, 0x0, 0x15550, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);
