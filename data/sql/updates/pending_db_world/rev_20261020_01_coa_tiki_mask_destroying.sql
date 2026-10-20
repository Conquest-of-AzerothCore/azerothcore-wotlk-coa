-- CoA: 1660037 'Unease Makes Tongues Wag' - restore the main-branch mask behaviour: a gossip
-- click starts the Destroying cast (256719, one-handed attack animation); the completed cast
-- credits the matching objective and the mask despawns, returning after 15 seconds. A player
-- whose matching objective is already complete cannot use the mask again and sees no sparkle.
-- Replaces the summon rows from rev_20261019_29 and the caption/state attempts in
-- rev_20261019_37/39/43/45.
UPDATE `gameobject_template`
SET `Data3` = 0, `Data4` = 0, `Data10` = 0, `castBarCaption` = '', `ScriptName` = 'go_coa_tiki_mask'
WHERE `entry` IN (2300535, 2300536, 2300537);

UPDATE `creature_template` SET `faction` = 35, `unit_flags` = 33555202
WHERE `entry` IN (161854, 161855, 161856);

DELETE FROM `spell_script_names` WHERE `spell_id` = 256719;
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_coa_tiki_mask_destroying';

DELETE FROM `smart_scripts`
WHERE `entryorguid` IN (2300535, 2300536, 2300537) AND `source_type` = 1;

INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(2300535, 1, 0, 1, 8, 0, 100, 0, 256719, 0, 0, 0, 0, 0, 33, 161854, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Enchanted Tiki Mask - On Spell Hit - Quest Credit'),
(2300535, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Enchanted Tiki Mask - Linked - Despawn after the cast'),
(2300536, 1, 0, 1, 8, 0, 100, 0, 256719, 0, 0, 0, 0, 0, 33, 161855, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Chattering Tiki Mask - On Spell Hit - Quest Credit'),
(2300536, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Chattering Tiki Mask - Linked - Despawn after the cast'),
(2300537, 1, 0, 1, 8, 0, 100, 0, 256719, 0, 0, 0, 0, 0, 33, 161856, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Possessed Tiki Mask - On Spell Hit - Quest Credit'),
(2300537, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 15, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Possessed Tiki Mask - Linked - Despawn after the cast');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceEntry` IN (2300535, 2300536, 2300537);
