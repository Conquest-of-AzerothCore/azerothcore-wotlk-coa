-- Molten Core boss scripts: Shazzrah's threat-wipe Blink, Garr's own kit, and Ragnaros's
-- like-for-like spell swap for Hand/Wrath of Ragnaros and Magma Blast.

-- Shazzrah (12264): Blink (2105611) already teleports through its own effects; only the
-- threat wipe stock Gate of Shazzrah does is missing (spell_shazzrah_blink_coa).
DELETE FROM `spell_script_names` WHERE `spell_id` = 2105611 AND `ScriptName` = 'spell_shazzrah_blink_coa';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2105611, 'spell_shazzrah_blink_coa');

-- Garr (12057): give him his own script (boss_garr_coa) instead of the generic coa_boss_ai,
-- the same way Magmadar keeps his stock script for a boss that manages adds.
UPDATE `creature_template` SET `ScriptName` = 'boss_garr_coa'
 WHERE `entry` IN (12057, 112057, 212057, 312057);

-- Land Slide's D0 payload (2105509) needs its Heroic/Mythic/Ascended siblings
-- (2105510-12, exiles-kit, clean per-difficulty damage family) grouped so the core
-- resolves them by itself, the same way every other Molten Core cast does.
DELETE FROM `spelldifficulty_dbc` WHERE `ID` = 72450;
INSERT INTO `spelldifficulty_dbc` (`ID`, `DifficultySpellID_1`, `DifficultySpellID_2`, `DifficultySpellID_3`, `DifficultySpellID_4`) VALUES
(72450, 2105509, 2105510, 2105511, 2105512);

-- Ragnaros (11502): Magma Blast's dummy (2108607) needs the same dummy-then-effect chain
-- as Shazzrah's Blink above (spell_ragnaros_magma_blast_coa_dummy, in boss_ragnaros.cpp).
-- Hand of Ragnaros and Wrath of Ragnaros need no row here: their CoA ids (2108612 and
-- 2108623) already have Heroic/Mythic/Ascended siblings grouped in the client's own
-- SpellDifficulty.dbc (groups 2213 and 2215).
DELETE FROM `spell_script_names` WHERE `spell_id` = 2108607 AND `ScriptName` = 'spell_ragnaros_magma_blast_coa_dummy';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(2108607, 'spell_ragnaros_magma_blast_coa_dummy');
