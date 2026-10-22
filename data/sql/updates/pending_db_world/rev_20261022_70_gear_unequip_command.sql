DELETE FROM `command` WHERE `name` = 'gear unequip';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('gear unequip', 2, 'Syntax: .gear unequip all|#itemlink|#itemid [mail] [$player]\nUnequips every equipped item (all), or the one equipped item given as a link or id, of $player, or of the selected player or yourself, and moves it into their bags. Items that do not fit are sent to their mailbox, in mails of up to 12 items. With mail, the items always go to the mailbox. $player must be online.');
