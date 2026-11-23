-- Death Knight-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/deathknight-01.md);
-- scripts in src/server/coa/AscensionDummyFixDeathKnight.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_deathknight_%';
DELETE FROM `spell_script_names` WHERE `spell_id` = 1499158 AND `ScriptName` = 'spell_dk_corpse_explosion';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Abomination's Limb: the cast makes the undead pet / ghoul cast 288831, which grips the enemies around it
(288830, 'spell_dummyfix_deathknight_abominations_limb'),
(288831, 'spell_dummyfix_deathknight_abominations_limb_grip'),
-- Death Tap: health sacrifice + 288801 converts one available rune into a Death Rune
(288800, 'spell_dummyfix_deathknight_death_tap'),
(288801, 'spell_dummyfix_deathknight_death_tap_conversion'),
-- Blood Shield: every Death Strike rank notes its target, the Death Strike heal grants the shield
(-49998, 'spell_dummyfix_deathknight_blood_shield_strike'),
(45470, 'spell_dummyfix_deathknight_blood_shield_heal'),
-- Corpse Explosion 1499158: the free-pick copy of 49158 (same effects) takes the stock script
(1499158, 'spell_dk_corpse_explosion');

-- Classless glyphs whose stock twin's behaviour lives in the stock DK scripts (same values): carry the stock glyph aura
-- Glyph of Disease 118824 -> 63334 (spell_dk_pestilence), Glyph of Icebound Fortitude 118580 -> 58625
-- (spell_dk_icebound_fortitude), Glyph of the Ghoul 118623 -> 58686 (ghoul stat scaling)
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (118824, 118580, 118623) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(118824, 63334, 2, 'Classless Glyph of Disease - stock glyph aura (Pestilence refresh)'),
(118580, 58625, 2, 'Classless Glyph of Icebound Fortitude - stock glyph aura (40% floor)'),
(118623, 58686, 2, 'Classless Glyph of the Ghoul - stock glyph aura (+40% Strength/Stamina)');

-- ---------------------------------------------------------------- deathknight-02 / deathknight-03
DELETE FROM `spell_script_names` WHERE `spell_id` = 49196 AND `ScriptName` = 'spell_dk_unholy_blight';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (985072, 985075, 985078, 985081, 985084, 985092)
    AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Unholy Blight rank 2: the stock talent script (its amount is set to rank 1's 50% in Contracts)
(49196, 'spell_dk_unholy_blight'),
-- Soul Reaper: the burst on expiry below 35% health (the triple tick is the UnitScript)
(288811, 'spell_dummyfix_deathknight_soul_reaper'),
-- Unholy Commander: Grave Coil damage commands the Gargoyle
(288945, 'spell_dummyfix_deathknight_unholy_commander'),
-- Forged Weapon enchants (rank 3, 5%): generic Mystic Enchant rules below
(985072, 'spell_ascension_mystic_enchant_proc'),
(985075, 'spell_ascension_mystic_enchant_proc'),
(985078, 'spell_ascension_mystic_enchant_proc'),
(985081, 'spell_ascension_mystic_enchant_proc'),
(985084, 'spell_ascension_mystic_enchant_proc'),
(985092, 'spell_ascension_mystic_enchant_proc');

DELETE FROM `spell_proc` WHERE `SpellId` IN (49196, 288945, 985072, 985075, 985078, 985081, 985084, 985092);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Unholy Blight rank 2: as stock rank 1 (49194): Grave Coil's damage (47632, flags[2] 0x1)
(49196, 0, 15, 0x0, 0x0, 0x1, 0x0, 0x1, 0x2, 0x0, 0x0, 0, 0, 0, 0, 0),
-- Unholy Commander: Grave Coil damage on an enemy (47632 flags[0] 0x2000; a triggered spell)
(288945, 0, 15, 0x2000, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Forged Weapon enchants: melee auto attacks that hit
(985072, 0, 0, 0x0, 0x0, 0x0, 0x4, 0x0, 0x0, 0x3, 0x0, 0, 0, 100, 0, 0),
(985075, 0, 0, 0x0, 0x0, 0x0, 0x4, 0x0, 0x0, 0x3, 0x0, 0, 0, 100, 0, 0),
(985078, 0, 0, 0x0, 0x0, 0x0, 0x4, 0x0, 0x0, 0x3, 0x0, 0, 0, 100, 0, 0),
(985081, 0, 0, 0x0, 0x0, 0x0, 0x4, 0x0, 0x0, 0x3, 0x0, 0, 0, 100, 0, 0),
(985084, 0, 0, 0x0, 0x0, 0x0, 0x4, 0x0, 0x0, 0x3, 0x0, 0, 0, 100, 0, 0),
(985092, 0, 0, 0x0, 0x0, 0x0, 0x4, 0x0, 0x0, 0x3, 0x0, 0, 0, 100, 0, 0);

-- Forged Weapon enchants (rank 3): each landed auto attack casts the school's damage spell for 5% of its damage
-- (the dummy carries 0; 5% is the rank-3 tooltip's number, rank 2 says 6%)
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (985072, 985075, 985078, 985081, 985084, 985092);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(985072, 0, 0, 'auto_attack', 0, '', 100, 0, '', '', '', '', '985071', 5, 0, 'Flameforged Weapon (rank 3): 5% of an auto attack as Fire (985071)'),
(985075, 0, 0, 'auto_attack', 0, '', 100, 0, '', '', '', '', '985074', 5, 0, 'Shadowforged Weapon (rank 3): 5% of an auto attack as Shadow (985074)'),
(985078, 0, 0, 'auto_attack', 0, '', 100, 0, '', '', '', '', '985077', 5, 0, 'Lightforged Weapon (rank 3): 5% of an auto attack as Holy (985077)'),
(985081, 0, 0, 'auto_attack', 0, '', 100, 0, '', '', '', '', '985080', 5, 0, 'Frostforged Weapon (rank 3): 5% of an auto attack as Frost (985080)'),
(985084, 0, 0, 'auto_attack', 0, '', 100, 0, '', '', '', '', '985083', 5, 0, 'Manaforged Weapon (rank 3): 5% of an auto attack as Arcane (985083)'),
(985092, 0, 0, 'auto_attack', 0, '', 100, 0, '', '', '', '', '985091', 5, 0, 'Stormforged Weapon (rank 3): 5% of an auto attack as Nature (985091)');
