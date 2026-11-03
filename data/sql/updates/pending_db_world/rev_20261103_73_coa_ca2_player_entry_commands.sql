-- The Character Advancement window's "(GM) Learn" and "(GM) Unlearn" menu entries send these commands
-- (CharacterAdvancement.lua: ".ca2 player addentry <name> <entry>" and ".ca2 player removeentry <name> <entry>").
DELETE FROM `command` WHERE `name` IN ('ca2', 'ca2 player', 'ca2 player addentry', 'ca2 player removeentry');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('ca2', 2, 'Syntax: .ca2 player <addentry|removeentry>. Character Advancement commands.'),
('ca2 player', 2, 'Syntax: .ca2 player <addentry|removeentry> <name> <entryId>.'),
('ca2 player addentry', 2, 'Syntax: .ca2 player addentry <name> <entryId>. Teach an online free-pick character a Character Advancement entry at its highest rank, at no cost.'),
('ca2 player removeentry', 2, 'Syntax: .ca2 player removeentry <name> <entryId>. Remove a Character Advancement entry from an online free-pick character, at no cost.');
