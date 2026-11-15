--
DELETE FROM `command` WHERE `name` = 'coa trial objectives';
INSERT INTO `command` (`name`, `security`, `help`) VALUES ('coa trial objectives', 3, CONCAT(
    'Syntax: .coa trial objectives [player]. Lists the player''s active challenges with their Challenge ID, level ',
    'and deaths, every objective with its Objective ID marked done or pending, and the Challenge IDs the player is ',
    'locked out of. The player defaults to your target; quote a two-word name. Works for an offline character.'));

DELETE FROM `command` WHERE `name` = 'coa trial credit';
INSERT INTO `command` (`name`, `security`, `help`) VALUES ('coa trial credit', 3, CONCAT(
    'Syntax: .coa trial credit <Challenge ID> <Objective ID> [player]. Marks one objective of the player''s ',
    'active challenge as done, whatever the player''s level. Use .coa trial objectives to find the IDs. The ',
    'player defaults to your target and must be online; quote a two-word name.'));

DELETE FROM `command` WHERE `name` = 'coa trial restore';
INSERT INTO `command` (`name`, `security`, `help`) VALUES ('coa trial restore', 3, CONCAT(
    'Syntax: .coa trial restore <Challenge ID> [player]. Makes a failed challenge active again with its level, ',
    'objectives and run timer, restarts hunger, thirst and fatigue, and resurrects the character. Refused when ',
    'the character has gained too many levels or passed a pending objective''s level since the failure. The ',
    'player defaults to your target and must be online; quote a two-word name.'));

DELETE FROM `command` WHERE `name` = 'coa challenge objectives';
INSERT INTO `command` (`name`, `security`, `help`) VALUES ('coa challenge objectives', 3, CONCAT(
    'Syntax: .coa challenge objectives [player]. Same as .coa trial objectives.'));

DELETE FROM `command` WHERE `name` = 'coa challenge credit';
INSERT INTO `command` (`name`, `security`, `help`) VALUES ('coa challenge credit', 3, CONCAT(
    'Syntax: .coa challenge credit <Challenge ID> <Objective ID> [player]. Same as .coa trial credit.'));

DELETE FROM `command` WHERE `name` = 'coa challenge restore';
INSERT INTO `command` (`name`, `security`, `help`) VALUES ('coa challenge restore', 3, CONCAT(
    'Syntax: .coa challenge restore <Challenge ID> [player]. Same as .coa trial restore.'));
