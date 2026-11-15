DELETE FROM `command` WHERE `name` IN ('ptr', 'ptr list', 'ptr copy');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('ptr', 0, 'Syntax: .ptr <list|copy>. Copy your own characters from this realm to the test realm. Use it on the realm the character lives on.'),
('ptr list', 0, 'Syntax: .ptr list. List your characters on this realm and the state of their latest copy to the test realm.'),
('ptr copy', 0, 'Syntax: .ptr copy <name>. Copy your character <name> from this realm to the test realm. You are told here when the copy is ready. A taken name is renamed at login.');
