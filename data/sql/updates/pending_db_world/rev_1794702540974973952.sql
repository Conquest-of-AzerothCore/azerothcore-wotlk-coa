--
DELETE FROM `command` WHERE `name` IN ('coa trial objectives', 'coa trial credit', 'coa trial restore', 'coa challenge objectives', 'coa challenge credit', 'coa challenge restore');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('coa trial objectives', 3, 'Syntax: .coa trial objectives [player]. Lists the player''s active challenges with their Challenge ID, level and deaths, every objective with its Objective ID marked done or pending, and the Challenge IDs the player is locked out of. The player defaults to your target; quote a two-word name. Works for an offline character.'),
('coa trial credit', 3, 'Syntax: .coa trial credit <Challenge ID> <Objective ID> [player]. Marks one objective of the player''s active challenge as done, whatever the player''s level. Use .coa trial objectives to find the IDs. The player defaults to your target and must be online; quote a two-word name.'),
('coa trial restore', 3, 'Syntax: .coa trial restore <Challenge ID> [player]. Makes a failed challenge active again with its level, objectives and run timer, restarts hunger, thirst and fatigue, and resurrects the character. Refused when the character has gained too many levels or passed a pending objective''s level since the failure. The player defaults to your target and must be online; quote a two-word name.'),
('coa challenge objectives', 3, 'Syntax: .coa challenge objectives [player]. Same as .coa trial objectives.'),
('coa challenge credit', 3, 'Syntax: .coa challenge credit <Challenge ID> <Objective ID> [player]. Same as .coa trial credit.'),
('coa challenge restore', 3, 'Syntax: .coa challenge restore <Challenge ID> [player]. Same as .coa trial restore.');
