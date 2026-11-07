DELETE FROM `command` WHERE `name` IN
('poll create', 'poll choice', 'poll wire', 'poll publish', 'poll close', 'poll list', 'poll results');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('poll create', 3, 'Syntax: .poll create <id> <type:1-4> <allowChange:0|1> <minLevel:10-255> <title>|<question>|<feedback prompt>|<context>'),
('poll choice', 3, 'Syntax: .poll choice <questionId> <stableChoiceId> <text>. Drafts only; maximum 10 choices.'),
('poll wire', 3, 'Syntax: .poll wire <questionId> <field04> <field50> <field54> <fieldA8>. Supply independently verified opaque metadata; no original values are assumed.'),
('poll publish', 3, 'Syntax: .poll publish <questionId> <expiryUnixSeconds:0=never>. Requires verified metadata. Published questions cannot be edited or reopened.'),
('poll close', 3, 'Syntax: .poll close <questionId>. Retains votes and comments.'),
('poll list', 3, 'Syntax: .poll list. Shows the newest 50 questions and account answer counts.'),
('poll results', 3, 'Syntax: .poll results <questionId>. Counts each stable choice ID (0=comment only); previews the newest 20 comments.');
