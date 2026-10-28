-- Talents whose stock script hooks no longer bind because Ascension reshaped the spell in Spell.dbc. The reshaped
-- data carries the behaviour itself; the server only has to stop blocking it and supply what a data row cannot.
--
-- The data alone does the work, so the stock bindings go:
--   Charge          energize + Charge Root trigger; Juggernaut procs from its own data
--   Sweeping Strikes PROC_TRIGGER_SPELL 997604 (40% weapon damage, 5 targets)
--   Nightfall       PROC_TRIGGER_SPELL 17941 Shadow Trance
--   Empowered Fire  PROC_TRIGGER_SPELL 67545 (SPELL_EFFECT_ASCENSION_RESTORE_BASE_MANA_PCT)
--   Swift Retribution  raid-area haste auras
--   Beacon of Light SPELL_AURA_LINKED 53651
--   Quick Recovery  SPELLMOD_SPELL_COST_REFUND_ON_FAIL modifier
-- Stock scripts are replaced with Ascension-shaped ones (AscensionTalentDataProcs.cpp) when the data names a trigger whose
-- value needs the server: Magic Absorption, Eclipse, Revitalize, Cut to the Chase.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN (
    (-100, 'spell_warr_charge'),
    (12328, 'spell_warr_sweeping_strikes'),
    (-18094, 'spell_warl_nightfall'),
    (-31656, 'spell_mage_empowered_fire'),
    (-53379, 'spell_pal_swift_retribution'),
    (53563, 'spell_pal_beacon_of_light'),
    (-31244, 'spell_rog_quick_recovery'),
    (-29441, 'spell_mage_magic_absorption'),
    (-48516, 'spell_dru_eclipse'),
    (-48539, 'spell_dru_revitalize'),
    (-51664, 'spell_rog_cut_to_the_chase'));

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_ascension_magic_absorption', 'aura_ascension_eclipse',
    'aura_ascension_revitalize', 'aura_ascension_cut_to_the_chase', 'spell_ascension_cut_to_the_chase_refresh');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-29441, 'aura_ascension_magic_absorption'),
(-48516, 'aura_ascension_eclipse'),
(-48539, 'aura_ascension_revitalize'),
(-51664, 'aura_ascension_cut_to_the_chase'),
(9931095, 'spell_ascension_cut_to_the_chase_refresh');

-- Sweeping Strikes and Cut to the Chase carry ProcFlags 0 in Spell.dbc, so the stock rows (ProcFlags 0 = "use the DBC")
-- never proc. "Casting a melee ability that deals damage" / a finishing move = DONE_SPELL_MELEE_DMG_CLASS, from any
-- class family. Sweeping Strikes loses PROC_ATTR_TRIGGERED_CAN_PROC so its own Sweeping Strike cannot re-trigger it.
UPDATE `spell_proc` SET `SpellFamilyName` = 0, `ProcFlags` = 0x10, `SpellTypeMask` = 1, `SpellPhaseMask` = 2,
    `AttributesMask` = 0
WHERE `SpellId` = 12328;
UPDATE `spell_proc` SET `SpellFamilyName` = 0, `SpellFamilyMask0` = 0, `SpellFamilyMask1` = 0, `ProcFlags` = 0x10,
    `SpellTypeMask` = 1, `SpellPhaseMask` = 2
WHERE `SpellId` = -51664;

-- Nightfall: "your shadow damage over time effects", once every 5 sec (stock: Corruption and Drain Life, 6 sec).
UPDATE `spell_proc` SET `SchoolMask` = 0x20, `SpellFamilyName` = 0, `SpellFamilyMask0` = 0, `Cooldown` = 5000
WHERE `SpellId` = -18094;

-- Magic Absorption: "all spells that damage you", 6 second cooldown (stock: full resists only, 1 sec).
UPDATE `spell_proc` SET `SpellTypeMask` = 1, `HitMask` = 0, `Cooldown` = 6000 WHERE `SpellId` = -29441;

-- Eclipse: direct Arcane or Nature damage from any spell, crit or not (stock: Wrath and Starfire crits); the script
-- picks the side by school.
UPDATE `spell_proc` SET `SpellFamilyName` = 0, `SpellFamilyMask0` = 0, `SpellTypeMask` = 1, `SpellPhaseMask` = 2,
    `HitMask` = 0
WHERE `SpellId` = -48516;

-- Revitalize: Spell.dbc has ProcFlags 0. Direct (Healing Touch, Regrowth) and periodic (Rejuvenation, Wild Growth,
-- Efflorescence) heals; the script rolls the per-spell chance, so Chance is 100.
UPDATE `spell_proc` SET `SpellFamilyName` = 0, `SpellFamilyMask0` = 0, `SpellFamilyMask1` = 0, `ProcFlags` = 0x44000,
    `SpellTypeMask` = 2, `SpellPhaseMask` = 2, `Chance` = 100
WHERE `SpellId` = -48539;

-- Quick Recovery is a spell modifier in Ascension's data, not a proc.
DELETE FROM `spell_proc` WHERE `SpellId` = -31244;
