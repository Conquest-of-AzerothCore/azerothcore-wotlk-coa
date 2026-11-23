-- Paladin-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/paladin-01.md);
-- scripts in src/server/coa/AscensionDummyFixPaladin.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_paladin_%';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (417804, 417808) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Beacon of Virtue: the cast, the beacon aura (heal sharing is a UnitScript hook)
(277680, 'spell_dummyfix_paladin_beacon_of_virtue_party'),
(979232, 'spell_dummyfix_paladin_beacon_of_virtue_ally'),
(1277680, 'spell_dummyfix_paladin_beacon_of_virtue_ally'),
(277682, 'spell_dummyfix_paladin_beacon_of_virtue_aura'),
(979234, 'spell_dummyfix_paladin_beacon_of_virtue_aura'),
(1277682, 'spell_dummyfix_paladin_beacon_of_virtue_aura'),
-- Divine Steed: the dummy carries the mount/speed spell for its own duration
(291021, 'spell_dummyfix_paladin_divine_steed'),
(991021, 'spell_dummyfix_paladin_divine_steed'),
(291020, 'spell_dummyfix_paladin_divine_steed_mount'),
(991020, 'spell_dummyfix_paladin_divine_steed_mount'),
-- Crimson Defender: 3 stacks empower the next listed spell
(273521, 'spell_dummyfix_paladin_crimson_defender'),
(1572103, 'spell_dummyfix_paladin_crimson_defender'),
(273526, 'spell_dummyfix_paladin_champions_wrath'),
(1572107, 'spell_dummyfix_paladin_champions_wrath_reborn'),
(273533, 'spell_dummyfix_paladin_crimson_judgement'),
-- Branding Zeal: the listed Holy spells trigger Seal of Righteousness
(1571699, 'spell_dummyfix_paladin_branding_zeal'),
-- Crusader's Justice: enemy -> 985973, ally -> 985974
(985972, 'spell_dummyfix_paladin_crusaders_justice'),
(985974, 'spell_dummyfix_paladin_crusaders_justice_heal'),
-- Natural Zeal (Holy half) / Harmonized Zeal: generic Mystic Enchant proc rules below
(417804, 'spell_ascension_mystic_enchant_proc'),
(417808, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `spell_proc` WHERE `SpellId` IN (273521, 1572103, 1571699, 417804, 417808);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Crimson Defender: the buff's DBC flags are the talent's block flags (taken hits); it is consumed by casting the
-- listed spells instead (the script picks them): any own non-triggered spell cast
(273521, 0, 0, 0x0, 0x0, 0x0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(1572103, 0, 0, 0x0, 0x0, 0x0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Branding Zeal: damage from Holy Shock (0x200000), Exorcism (0x2), Hammer of Wrath (0x80), Holy Wrath (0x200000);
-- Holy Shock's damage is a triggered spell
(1571699, 0, 10, 0x200000, 0x200082, 0x0, 0x10110, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Natural Zeal: Holy heals landing
(417804, 0, 0, 0x0, 0x0, 0x0, 0x4400, 0x2, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Harmonized Zeal: Divine Favor cast
(417808, 0, 0, 0x0, 0x0, 0x0, 0x4400, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (417804, 417808);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(417804, 0, 0, 'heal', 2, '', 100, 0, '', '', '', '', '', 0, 0, 'Natural Zeal (enchant 417804): a Holy heal takes time off Nature''s Swiftness (417806)'),
(417804, 1, 0, 'heal', 2, '', 100, 0, '', '', '', '', '', 0, 0, 'Natural Zeal (enchant 417804): a Holy heal grants a Harmonized Zeal stack (417808)'),
(417808, 0, 0, 'cast', 0, '20216 965944 1120216 1220216', 100, 0, '', '', 'stacks:417808>=3', '', '', 0, 0, 'Harmonized Zeal: Divine Favor at 3 stacks grants 5% spell haste (417810, which removes the stacks)');

-- paladin-02: conditional passives (Counterpoise, Swashbuckler: Flurry of Blows / Matched Blows, Temple Guardian),
-- All that is Right, Shooting Stars, Dawn of the Second Day (Crack of Dawn removal)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((84524, 'spell_dummyfix_paladin_conditional_buff'), (282348, 'spell_dummyfix_paladin_conditional_buff'), (81221, 'spell_dummyfix_paladin_conditional_buff'), (281602, 'spell_dummyfix_paladin_conditional_buff'), (81219, 'spell_dummyfix_paladin_conditional_buff'), (281597, 'spell_dummyfix_paladin_conditional_buff'), (283744, 'spell_dummyfix_paladin_conditional_buff'), (25742, 'spell_dummyfix_paladin_all_that_is_right'), (81181, 'spell_dummyfix_paladin_shooting_stars'), (281485, 'spell_dummyfix_paladin_shooting_stars'), (983954, 'spell_dummyfix_paladin_crack_of_dawn_removal'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(84524, 'spell_dummyfix_paladin_conditional_buff'),
(282348, 'spell_dummyfix_paladin_conditional_buff'),
(81221, 'spell_dummyfix_paladin_conditional_buff'),
(281602, 'spell_dummyfix_paladin_conditional_buff'),
(81219, 'spell_dummyfix_paladin_conditional_buff'),
(281597, 'spell_dummyfix_paladin_conditional_buff'),
(283744, 'spell_dummyfix_paladin_conditional_buff'),
-- All that is Right: the Seal of Righteousness damage spell adds the stack (no proc on 277746)
(25742, 'spell_dummyfix_paladin_all_that_is_right'),
(81181, 'spell_dummyfix_paladin_shooting_stars'),
(281485, 'spell_dummyfix_paladin_shooting_stars'),
(983954, 'spell_dummyfix_paladin_crack_of_dawn_removal');

DELETE FROM `spell_proc` WHERE `SpellId` IN (277746, 81181, 281485);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Shooting Stars: own spell casts (the script keeps those with a cast time, not channeled, while Starfall is up);
-- the enchant counts Arcane spells only
(81181, 64, 0, 0x0, 0x0, 0x0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(281485, 0, 0, 0x0, 0x0, 0x0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

-- paladin-03: Spiritual Attunement (stock script), Seal of Fervor, In Sword We Trust, Divine Purpose, Mending Hands
-- (Hammerstorm is a contract only)
DELETE FROM `spell_script_names` WHERE `spell_id` = 965377 AND `ScriptName` = 'spell_pal_spiritual_attunement';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(965377, 'spell_pal_spiritual_attunement'),
(954425, 'spell_dummyfix_paladin_seal_of_fervor'),
(1569826, 'spell_dummyfix_paladin_seal_of_fervor'),
(954426, 'spell_dummyfix_paladin_judgement_of_fervor'),
(272096, 'spell_dummyfix_paladin_judgement_of_fervor'),
(979063, 'spell_dummyfix_paladin_in_sword_we_trust'),
(831872, 'spell_dummyfix_paladin_divine_purpose'),
(81297, 'spell_dummyfix_paladin_mending_hands'),
(281724, 'spell_dummyfix_paladin_mending_hands');

DELETE FROM `spell_proc` WHERE `SpellId` IN (954425, 1569826, 979063, 831872, 81297, 281724);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Seal of Fervor: as Seal of Righteousness 21084 / the Wildcard copy 272087 (DBC proc flags 0x14, damage hits)
(954425, 0, 0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x2, 0x0, 0x2, 0, 0, 0, 0, 0),
(1569826, 0, 0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x2, 0x0, 0x2, 0, 0, 0, 0, 0),
-- In Sword We Trust: the Crusader Strike hit (family flags 1: 0x8000) that used the buff
(979063, 0, 10, 0x0, 0x8000, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Divine Purpose: Hand of Freedom (family flags 0: 0x10) landing
(831872, 0, 10, 0x10, 0x0, 0x0, 0x4400, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Mending Hands: Lay on Hands (family flags 0: 0x8000) landing; the copies it casts are triggered and do not proc
(81297, 0, 10, 0x8000, 0x0, 0x0, 0x4400, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(281724, 0, 10, 0x8000, 0x0, 0x0, 0x4400, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- paladin-04: Seal of Arcane Wrath, Sacred Unity (Warcraft Reborn), Hour of Judgement (Blessed Hands is a unit hook)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((984284, 'spell_dummyfix_paladin_seal_of_fervor'), (984296, 'spell_dummyfix_paladin_judgement_of_arcane_wrath'), (1585291, 'spell_dummyfix_paladin_sacred_unity'), (92568, 'spell_dummyfix_paladin_hour_of_judgement'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(984284, 'spell_dummyfix_paladin_seal_of_fervor'),
(984296, 'spell_dummyfix_paladin_judgement_of_arcane_wrath'),
(1585291, 'spell_dummyfix_paladin_sacred_unity'),
(92568, 'spell_dummyfix_paladin_hour_of_judgement');

DELETE FROM `spell_proc` WHERE `SpellId` IN (984284, 92568);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Seal of Arcane Wrath: as Seal of Righteousness 21084 (DBC proc flags 0x14, damage hits)
(984284, 0, 0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x2, 0x0, 0x2, 0, 0, 0, 0, 0),
-- Hour of Judgement: own Paladin spell casts (the script keeps the damaging ones) -> Final Hour
(92568, 0, 10, 0x0, 0x0, 0x0, 0x15510, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);
