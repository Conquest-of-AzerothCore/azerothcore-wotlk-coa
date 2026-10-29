-- Tornado ambience: keep the stock TornadoLoop sound (10045) but make the
-- client treat it as a one-shot by pointing its SoundEntries row at the
-- one-shot advanced row (114). Nytharos.cpp replays it every 5.92 s for as
-- long as a spout lives, so the ambience is continuous while a spout is up and
-- stops when the spout despawns; the looping advanced row (48443) is what made
-- the sound survive after the tornadoes were gone.
CREATE TABLE IF NOT EXISTS `soundentries_dbc` (
  `f0` int NOT NULL DEFAULT 0,
  `f1` int NOT NULL DEFAULT 0,
  `f2` int NOT NULL DEFAULT 0,
  `f3` int NOT NULL DEFAULT 0,
  `f4` int NOT NULL DEFAULT 0,
  `f5` int NOT NULL DEFAULT 0,
  `f6` int NOT NULL DEFAULT 0,
  `f7` int NOT NULL DEFAULT 0,
  `f8` int NOT NULL DEFAULT 0,
  `f9` int NOT NULL DEFAULT 0,
  `f10` int NOT NULL DEFAULT 0,
  `f11` int NOT NULL DEFAULT 0,
  `f12` int NOT NULL DEFAULT 0,
  `f13` int NOT NULL DEFAULT 0,
  `f14` int NOT NULL DEFAULT 0,
  `f15` int NOT NULL DEFAULT 0,
  `f16` int NOT NULL DEFAULT 0,
  `f17` int NOT NULL DEFAULT 0,
  `f18` int NOT NULL DEFAULT 0,
  `f19` int NOT NULL DEFAULT 0,
  `f20` int NOT NULL DEFAULT 0,
  `f21` int NOT NULL DEFAULT 0,
  `f22` int NOT NULL DEFAULT 0,
  `f23` int NOT NULL DEFAULT 0,
  `f24` int NOT NULL DEFAULT 0,
  `f25` int NOT NULL DEFAULT 0,
  `f26` int NOT NULL DEFAULT 0,
  `f27` int NOT NULL DEFAULT 0,
  `f28` int NOT NULL DEFAULT 0,
  `f29` int NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `soundentries_dbc` WHERE `f0` = 10045;
INSERT INTO `soundentries_dbc`
(`f0`,`f1`,`f2`,`f3`,`f4`,`f5`,`f6`,`f7`,`f8`,`f9`,`f10`,`f11`,`f12`,`f13`,`f14`,`f15`,`f16`,`f17`,`f18`,`f19`,`f20`,`f21`,`f22`,`f23`,`f24`,`f25`,`f26`,`f27`,`f28`,`f29`)
VALUES
(10045,1,375130,265381,53,53,53,53,53,53,53,53,53,1,1,1,1,1,1,1,1,1,1,114,1060152279,512,1092616192,1112014848,0,0);
