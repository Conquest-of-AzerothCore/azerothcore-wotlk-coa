DELETE FROM `spell_script_names` WHERE `spell_id` IN (
    -1752, 760050, 760187, 760193, 760412, 760413, 760414, 760415,
    760416, 760425, 760426, 760427, 760428, 760429, 2110050, 2110187,
    2110193) AND `ScriptName` = 'wildcard_corrupted_blade';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-1752, 'wildcard_corrupted_blade'),
(760050, 'wildcard_corrupted_blade'),
(760187, 'wildcard_corrupted_blade'),
(760193, 'wildcard_corrupted_blade'),
(760412, 'wildcard_corrupted_blade'),
(760413, 'wildcard_corrupted_blade'),
(760414, 'wildcard_corrupted_blade'),
(760415, 'wildcard_corrupted_blade'),
(760416, 'wildcard_corrupted_blade'),
(760425, 'wildcard_corrupted_blade'),
(760426, 'wildcard_corrupted_blade'),
(760427, 'wildcard_corrupted_blade'),
(760428, 'wildcard_corrupted_blade'),
(760429, 'wildcard_corrupted_blade'),
(2110050, 'wildcard_corrupted_blade'),
(2110187, 'wildcard_corrupted_blade'),
(2110193, 'wildcard_corrupted_blade');
