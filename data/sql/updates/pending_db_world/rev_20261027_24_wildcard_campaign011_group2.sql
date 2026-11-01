START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (280225, 280365, 281050);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `Chance`, `Charges`) VALUES
(280225, 1048576, 0, 0, 0, 2, 0, 100, 5),
(280365, 332116, 1, 2, 3, 2, 2, 100, 0),
(281050, 40, 1, 2, 3, 2, 0, 100, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 281050 AND `ScriptName` = 'aura_wildcard_infused_aegis';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (281050, 'aura_wildcard_infused_aegis');
DELETE FROM `spell_bonus_data` WHERE `entry` IN (280226, 280366, 281051);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(280226, 0, 0, 0, 0, 'Astral Reconstitution - percentage of incoming damage'),
(280366, 0, 0, 0, 0, 'Apotheosis - percentage of outgoing damage'),
(281051, 0, 0, 0, 0, 'Infused Aegis - native percentage-event retaliation');
COMMIT;
