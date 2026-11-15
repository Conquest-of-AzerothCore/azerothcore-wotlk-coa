DELETE FROM `command` WHERE `name` IN ('tokencap', 'tokencap set', 'tokencap reset');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('tokencap', 0, 'Syntax: .tokencap. Show how many Bazaar Tokens your account has earned this hour and when the hour ends.'),
('tokencap set', 2, 'Syntax: .tokencap set [$player] #earned [#minutesAgo]. Put the account at #earned tokens in an hour that began #minutesAgo minutes ago.'),
('tokencap reset', 2, 'Syntax: .tokencap reset [$player]. End the account''s hour: its next token opens a new one.');
