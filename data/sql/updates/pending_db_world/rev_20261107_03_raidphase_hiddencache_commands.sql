DELETE FROM `command` WHERE `name` IN ('raidphase', 'raidphase set', 'raidphase clear', 'hiddencache list', 'hiddencache spawn', 'hiddencache despawn');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('raidphase', 2, 'Syntax: .raidphase\nShows the raid release stage, the configured stage and the override.'),
('raidphase set', 3, 'Syntax: .raidphase set #stage\nOverrides the raid release stage (0-8) until .raidphase clear.'),
('raidphase clear', 3, 'Syntax: .raidphase clear\nRemoves the override; Ascension.CallboardCache.ReleaseStage applies again.'),
('hiddencache list', 2, 'Syntax: .hiddencache list [all]\nLists the Rare and Epic Hidden Caches in this zone (all: every zone) with their state and a .go gameobject line.'),
('hiddencache spawn', 2, 'Syntax: .hiddencache spawn [all]\nRespawns the opened Hidden Caches in this zone (all: every zone) and adds temporary debug caches on the inactive spots.'),
('hiddencache despawn', 2, 'Syntax: .hiddencache despawn\nRemoves the temporary debug Hidden Caches.');
