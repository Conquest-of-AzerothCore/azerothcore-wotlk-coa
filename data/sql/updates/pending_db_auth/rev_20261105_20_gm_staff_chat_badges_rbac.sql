-- .gm mod chat / .gm cm chat: permissions 1009/1010, linked to the Moderator command role (198), which GM and Admin inherit.
-- Non-destructive on replay: a DELETE would cascade to rbac_account_permissions and drop explicit grants.
INSERT IGNORE INTO `rbac_permissions` (`id`, `name`) VALUES
(1009, 'Command: gm mod chat'),
(1010, 'Command: gm cm chat');
INSERT IGNORE INTO `rbac_linked_permissions` (`id`, `linkedId`) VALUES
(198, 1009),
(198, 1010);
