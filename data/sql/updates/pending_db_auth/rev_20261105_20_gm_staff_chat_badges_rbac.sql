-- .gm mod chat / .gm cm chat: permissions 1009/1010, linked to the Moderator command role (198), which GM and Admin inherit.
-- .gm admin chat: permission 1011, linked to the Administrator command role (196).
-- Non-destructive on replay: a DELETE would cascade to rbac_account_permissions and drop explicit grants.
INSERT IGNORE INTO `rbac_permissions` (`id`, `name`) VALUES
(1009, 'Command: gm mod chat'),
(1010, 'Command: gm cm chat'),
(1011, 'Command: gm admin chat');
INSERT IGNORE INTO `rbac_linked_permissions` (`id`, `linkedId`) VALUES
(198, 1009),
(198, 1010),
(196, 1011);
