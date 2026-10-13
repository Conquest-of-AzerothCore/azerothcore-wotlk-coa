-- Groot Coin command permissions: 1001 issues awards, 1002 reads the audit (history, inspect, status). Neither is
-- linked to a role; an administrator grants them to designated staff accounts per realm.
-- Non-destructive on replay: existing rows are kept (a DELETE would cascade to rbac_account_permissions and drop
-- every grant). An unrelated permission already using 1001 or 1002 makes the guard evaluate a two-row subquery,
-- which fails this file before anything changes.
SELECT IF(EXISTS (SELECT 1 FROM `rbac_permissions` WHERE `id` IN (1001, 1002) AND `name` NOT LIKE 'Command: groot %'),
    (SELECT 1 UNION SELECT 2), 1) INTO @groot_coin_rbac_ids_free;
INSERT IGNORE INTO `rbac_permissions` (`id`, `name`) VALUES
(1001, 'Command: groot award'),
(1002, 'Command: groot audit');
