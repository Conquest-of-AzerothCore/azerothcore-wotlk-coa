-- Strength of the Black Empire scale wiring: the void-monstrosity transform shares
-- Herald's display (28844) and needs the same Herald-parity scale-down.
-- AscensionCultistAuras registers ScaleBlackEmpire for 680556, but the class
-- lifecycle script only attaches to spells named in spell_script_names.
-- Without this row the scale hook never runs and the transformed cultist keeps
-- object scale 1.0 on the huge base model. DELETE+INSERT stays idempotent.
DELETE FROM `spell_script_names` WHERE `spell_id` = 680556 AND `ScriptName` = 'aura_ascension_cultist_lifecycle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (680556, 'aura_ascension_cultist_lifecycle');
