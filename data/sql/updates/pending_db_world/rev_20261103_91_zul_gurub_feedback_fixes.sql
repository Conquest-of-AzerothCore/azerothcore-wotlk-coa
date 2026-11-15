-- Zul'Gurub tester feedback of 2026-11-03 (with Pigeon's spell review).

-- The passive proc auras never procced: Poisonous Fangs (Venoxis, his cobras and serpents), Furious Strikes (Mar'li),
-- Shredding Claws (Thekal) and Razor Claws (Arlokk) now trigger on melee hits.
DELETE FROM `spell_proc` WHERE `SpellId` IN (2118025, 2118075, 2118125, 2118225, 2118325);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
`ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(2118025, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0),
(2118075, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0),
(2118125, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0),
(2118225, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0),
(2118325, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0);

-- The snakes' Fangs stack Venoxis's own Virulent Poison, as on live.
DELETE FROM `spell_script_names` WHERE `spell_id` = 2118075;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (2118075, 'spell_venoxis_coa_snake_fangs');

-- Gri'lek's Trauma had no difficulty row, so Heroic, Mythic and Ascended used the Normal spell.
DELETE FROM `spelldifficulty_dbc` WHERE `ID` = 72451;
INSERT INTO `spelldifficulty_dbc` (`ID`, `DifficultySpellID_1`, `DifficultySpellID_2`, `DifficultySpellID_3`,
`DifficultySpellID_4`) VALUES (72451, 2118802, 2118803, 2118804, 2118805);

-- Gurubashi Bat Riders can be stunned (a stun landed on one in the live log).
DELETE FROM `creature_immunities` WHERE `ID` = 14750;
INSERT INTO `creature_immunities` (`ID`, `SchoolMask`, `DispelTypeMask`, `MechanicsMask`, `Effects`, `Auras`,
`ImmuneAoE`, `ImmuneChain`, `Comment`)
SELECT 14750, `SchoolMask`, `DispelTypeMask`, `MechanicsMask` & ~4096, `Effects`, `Auras`, `ImmuneAoE`, `ImmuneChain`,
'Gurubashi Bat Rider - Existing template immunities minus Stun'
FROM `creature_immunities` WHERE `ID` = -406;
UPDATE `creature_template` SET `CreatureImmunitiesId` = 14750 WHERE `entry` IN (14750, 114750, 214750, 314750);

-- Spawn of Mar'li and Zulian Prowlers are elite; Parasitic Serpents are level 60.
UPDATE `creature_template` SET `rank` = 1 WHERE `entry` IN (15041, 115041, 215041, 315041, 15101, 115101, 215101, 315101);
UPDATE `creature_template` SET `minlevel` = 60, `maxlevel` = 60 WHERE `entry` IN (14884, 114884, 214884, 314884);

-- Jin'do's Banish dropped players from 12 yards above the pit floor.
UPDATE `spell_target_position` SET `PositionZ` = 77.7 WHERE `ID` = 24466 AND `EffectIndex` = 0;
