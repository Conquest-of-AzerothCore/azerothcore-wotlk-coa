-- .gear unequip: permission 1003, linked to the Game Master command role like .gear repair (897).
-- Non-destructive on replay: a DELETE would cascade to rbac_account_permissions and drop explicit grants.
INSERT IGNORE INTO `rbac_permissions` (`id`, `name`) VALUES
(1003, 'Command: gear unequip');
INSERT IGNORE INTO `rbac_linked_permissions` (`id`, `linkedId`) VALUES
(197, 1003);
