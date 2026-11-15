INSERT IGNORE INTO `rbac_permissions` (`id`, `name`) VALUES
(1009, 'Command: gm mod chat'),
(1010, 'Command: gm cm chat'),
(1011, 'Command: gm admin chat');
INSERT IGNORE INTO `rbac_linked_permissions` (`id`, `linkedId`) VALUES
(198, 1009),
(196, 1010),
(196, 1011);
