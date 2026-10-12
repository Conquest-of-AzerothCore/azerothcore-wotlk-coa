-- Groot Coin command permissions: 1001 issues awards, 1002 reads the audit (history, inspect, status). Neither is
-- linked to a role; an administrator grants them to designated staff accounts per realm.
DELETE FROM `rbac_permissions` WHERE `id` IN (1001, 1002) AND `name` LIKE 'Command: groot %';
INSERT INTO `rbac_permissions` (`id`, `name`) VALUES
(1001, 'Command: groot award'),
(1002, 'Command: groot audit');
