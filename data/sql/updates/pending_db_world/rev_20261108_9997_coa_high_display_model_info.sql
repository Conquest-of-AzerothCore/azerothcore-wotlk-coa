-- The troglodyte character display 142832 (Grimepit Troggs, Grime-King Augustus) had no model data row. It gets the
-- troll body's bounding radius and reach (display 1478).
DELETE FROM `creature_model_info` WHERE `DisplayID` = 142832;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES
(142832, 0.306, 1.5, 0, 0, 0);

-- Goldshire Farmer (162824) wears a captured female look on the stock farmer display 6773, which is paired with the
-- male farmer 6772. With model data keyed by the full display id that pair applies again, and half the farmers would
-- draw the female look on the male body. The plain human female display 50 has the same model and no pair.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 50 WHERE `CreatureID` = 162824 AND `CreatureDisplayID` = 6773;
UPDATE `creature_display_preset` SET `display_id` = 50 WHERE `entry` = 162824 AND `display_id` = 6773;
