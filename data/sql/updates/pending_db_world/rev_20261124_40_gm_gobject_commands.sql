UPDATE `command` SET `security` = 2
WHERE `security` > 2
  AND `name` IN ('gobject', 'gobject activate', 'gobject info', 'gobject move', 'gobject near', 'gobject respawn', 'gobject set', 'gobject set phase', 'gobject set scale', 'gobject set state');
