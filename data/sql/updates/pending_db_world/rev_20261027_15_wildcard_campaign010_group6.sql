START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 270632 AND `ScriptName` IN ('spell_ascension_mystic_enchant_proc', 'aura_wildcard_dominant_shield');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (270632, 'aura_wildcard_dominant_shield');
DELETE FROM `spell_script_names` WHERE `spell_id` = 270631 AND `ScriptName` = 'aura_wildcard_atonement';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (270631, 'aura_wildcard_atonement');
DELETE FROM `spell_proc` WHERE `SpellId` IN (270631, 270632);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `Chance`) VALUES
(270631, 332116, 1, 2, 3, 2, 0, 100),
(270632, 87312, 0, 6, 0, 2, 2, 100);
DELETE FROM `spell_bonus_data` WHERE `entry` IN (270622, 270626, 270665);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(270622, 0.01, 0, 0, 0, 'Atonement - Holy Fire periodic damage heal'),
(270626, 0.2, 0, 0, 0, 'Atonement - Smite and Holy Fire direct damage heal'),
(270665, 0, 0, 0, 0, 'Growing Light - forwarded twenty percent heal, no extra coefficient');
COMMIT;
