-- Goldshire Pumpkin 2300547 (#12333): quest chest for Goldshire's Generosity 1660059 had no
-- gameobject_template_addon row (flags = 0), so players without the quest could still right-click and
-- despawn it for empty loot. Set GO_FLAG_INTERACT_COND (4) so interaction requires quest activation.
DELETE FROM `gameobject_template_addon` WHERE `entry` = 2300547;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`,
    `artkit2`, `artkit3`) VALUES
(2300547, 0, 4, 0, 0, 0, 0, 0, 0);
