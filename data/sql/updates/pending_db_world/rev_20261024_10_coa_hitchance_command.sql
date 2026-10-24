DELETE FROM `command` WHERE `name` = 'hitchance';
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('hitchance', 0, 'Syntax: .hitchance. Show your melee, ranged and spell hit chance, split into rating and auras.');
