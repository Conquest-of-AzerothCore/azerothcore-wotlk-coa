DELETE FROM `command` WHERE `name` = 'poll wire';
UPDATE `command`
SET `help` = 'Syntax: .poll publish <questionId> <expiryUnixSeconds:0=never>. Published questions cannot be edited or reopened.'
WHERE `name` = 'poll publish';
