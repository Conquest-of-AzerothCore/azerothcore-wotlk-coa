-- The Cleansing of Grimepit (175016): a Trogg Idol (gameobject 2300633) credited the quest on every click during
-- the one second before its SmartAI despawn, so one idol could complete the quest (#10543). The goober has no
-- auto-close, so nothing marks it in use. On use, make the idol unselectable at once, which GameObject::Use
-- rejects, then despawn it as before. The template addon flags (none) are restored when the idol despawns, so it
-- respawns usable.
DELETE FROM `gameobject_template_addon` WHERE `entry` = 2300633;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES
(2300633, 0, 0);

DELETE FROM `smart_scripts` WHERE (`entryorguid`,`source_type`) IN ((2300633,1));
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2300633, 1, 0, 1, 64, 0, 100, 0, 1, 0, 0, 0, 0, 0, 105, 16, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Trogg Idol - On use - Set unselectable'),
(2300633, 1, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1000, 120, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Trogg Idol - On use - Destroyed, back in 2 min');
