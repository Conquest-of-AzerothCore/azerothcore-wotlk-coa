-- #9370: Animated Blood (909064), the Bloody Dagger's on-use spell, summons creature 3333313, which has
-- no creature_template row, so the cast succeeds but nothing appears ("does nothing"). The same gap existed
-- for the rank spells' creatures 315301/325301/335301 (#51); register this one the same way, reusing the
-- display (93307) and DisplayScale (0.25, cancelling the client's own 4x scale on bloodelemental.mdx) that
-- #51 and #4290 already established for that display.
INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`) VALUES
(3333313, 'Animated Blood', 1, 1, 14, 1, 8)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`),
    `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`),
    `type` = VALUES(`type`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 3333313;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(3333313, 0, 93307, 0.25, 1);
