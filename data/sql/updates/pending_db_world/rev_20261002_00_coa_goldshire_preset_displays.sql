-- rev_20260930_99_ASC_northshire_revamp (#5764) gives these Goldshire and Elwynn NPCs a creature_display_preset on
-- the stock human display 49 or 50. rev_20261001_20 (#6052) moved them to other displays, so the client's mirror
-- image request no longer matches the preset and the NPCs are not drawn. Put them back on their preset display.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 50 WHERE `Idx` = 0 AND `CreatureID` IN
    (162800, 162805, 162808, 162809, 162810, 162812, 162813, 162814, 162819, 162820, 162821, 162824, 900017);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 49 WHERE `Idx` = 0 AND `CreatureID` IN
    (162801, 162806, 162807, 162811, 162817, 162818, 162822, 162823, 162826, 162943);

-- Aldia Crayon and Lady Agria Spada have no preset; the revamp's displays 652414 and 652415 are not in the CoA
-- client's CreatureDisplayInfo.dbc, so they get the #5833 displays the client has.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 8632 WHERE `CreatureID` = 162802 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 1544 WHERE `CreatureID` = 162803 AND `Idx` = 0;
