DELETE FROM `command` WHERE `name` IN ('raidphase', 'raidphase set', 'raidphase clear', 'hiddencache list', 'hiddencache spawn', 'hiddencache despawn', 'hr stage', 'hr stage set', 'hr stage clear');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('raidphase', 2, 'Syntax: .raidphase\nShows the raid release stage, the configured stage and the override.'),
('raidphase set', 3, 'Syntax: .raidphase set #stage\nOverrides the raid release stage (0-8) until .raidphase clear.'),
('raidphase clear', 3, 'Syntax: .raidphase clear\nRemoves the override; Ascension.CallboardCache.ReleaseStage applies again.'),
('hiddencache list', 2, 'Syntax: .hiddencache list [all]\nLists the Rare and Epic Hidden Caches in this zone (all: every zone) with their state and a .go gameobject line.'),
('hiddencache spawn', 2, 'Syntax: .hiddencache spawn [all]\nRespawns the opened Hidden Caches in this zone (all: every zone) and adds temporary debug caches on the inactive spots.'),
('hiddencache despawn', 2, 'Syntax: .hiddencache despawn\nRemoves the temporary debug Hidden Caches.'),
('hr stage', 2, 'Syntax: .hr stage\nShows the High-Risk release stage, the configured stage (HighRisk.ReleaseStage) and the override.'),
('hr stage set', 3, 'Syntax: .hr stage set #stage\nOverrides the High-Risk release stage (1-8) until .hr stage clear.'),
('hr stage clear', 3, 'Syntax: .hr stage clear\nRemoves the override; HighRisk.ReleaseStage applies again.');
