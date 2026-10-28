DELETE FROM `command` WHERE `name` = 'gear unequip';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('gear unequip', 2, 'Syntax: .gear unequip all|#itemlink|#itemid 0|1 [$player]\nUnequips every equipped item (all), or the one equipped item given as a link or id, of $player, or of the selected player or yourself. With 0 the items go into their bags and the ones that do not fit are sent to their mailbox; with 1 they all go to the mailbox. Mails carry up to 12 items each. $player must be online.');
