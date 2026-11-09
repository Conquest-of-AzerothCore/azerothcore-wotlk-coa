DELETE FROM `command` WHERE `name` IN ('ptr', 'ptr list', 'ptr copy');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('ptr', 0, 'Syntax: .ptr <list|copy>. Copy your own characters from the source realm to this realm. Use it on the realm that receives the copy.'),
('ptr list', 0, 'Syntax: .ptr list. List your characters on the source realm and whether each one is already copied here.'),
('ptr copy', 0, 'Syntax: .ptr copy <name>. Copy your character <name> from the source realm to this realm. Log it out on the source realm first. A taken name is renamed at login.');
