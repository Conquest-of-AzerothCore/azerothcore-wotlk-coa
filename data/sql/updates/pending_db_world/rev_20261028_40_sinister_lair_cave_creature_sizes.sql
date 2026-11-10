-- Sinister Lair (Durotar, Valley of Trials): the cave's bats, snakes and spiders were far from the size of a character
-- (#8190). Their displays carry their own scale: the Fel Bat display 4734 is at 0.15 (a regular bat is 0.45), the
-- Mine Spider display 1157 and the giant snake display 78248 are at 1.0, which makes the spider about 6 yards long and
-- the snake over 3 yards high. Sized from the models' bounds to at most a character: bat 0.3, spider 0.4, snake 0.4.
UPDATE `creature_template_model` SET `DisplayScale` = 2 WHERE `CreatureID` = 161793 AND `CreatureDisplayID` = 4734;
UPDATE `creature_template_model` SET `DisplayScale` = 0.4 WHERE `CreatureID` = 161794 AND `CreatureDisplayID` = 78248;
UPDATE `creature_template_model` SET `DisplayScale` = 0.4 WHERE `CreatureID` = 161795 AND `CreatureDisplayID` = 1157;
