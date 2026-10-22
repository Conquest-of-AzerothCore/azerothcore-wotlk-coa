DELETE FROM `command` WHERE `name` = 'gear unequip';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('gear unequip', 2, 'Syntax: .gear unequip [mail] [$player]\nMoves every equipped item of $player, or of the selected player or yourself, into their bags. Items that do not fit are sent to their mailbox, in mails of up to 12 items. With mail, every item is sent to the mailbox. $player must be online.');
