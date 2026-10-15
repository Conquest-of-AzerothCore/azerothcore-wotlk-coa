-- Tinker: bind War Crimes (707239) to the Tinker event proc script.
-- Its DBC proc flags (0x15510) cover every direct Tinker spell hit and its effect carries an empty class
-- mask, so the generated proc entry fired unrestricted while the two augmentation sources the tooltip names
-- could never reach it: Explosive Augmentation's damage is a triggered cast and Tracer Augmentation's is
-- periodic. The script supplies both gates and rolls the DBC's own 50% chance.
DELETE FROM `spell_proc` WHERE `SpellId` = 707239;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`, `Charges`) VALUES
(707239, 1048575, 7, 2, 32767, 2, 100, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 707239 AND `ScriptName` = 'aura_ascension_tinker_event';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (707239, 'aura_ascension_tinker_event');
