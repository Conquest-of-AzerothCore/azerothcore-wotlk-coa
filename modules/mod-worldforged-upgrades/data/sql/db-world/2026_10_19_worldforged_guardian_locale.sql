-- mod-worldforged-upgrades: the Guardian of Time's database texts, localized.
-- The enUS originals stay where they were written: `creature_template` holds
-- his name and subname, `npc_text` 9780012 holds the greeting shown above his
-- menu (both in base/02_worldforged_guardian.sql). These two locale tables
-- carry every other client locale, the same split the core uses everywhere.

DELETE FROM `creature_template_locale` WHERE `entry` = 9780012;
INSERT INTO `creature_template_locale` (`entry`, `locale`, `Name`, `Title`) VALUES
(9780012, 'koKR', '시간의 수호자',       '승천의 룬'),
(9780012, 'frFR', 'Gardien du Temps',   'Runes d''Ascension'),
(9780012, 'deDE', 'Wächter der Zeit',   'Runen des Aufstiegs'),
(9780012, 'zhCN', '时光守护者',          '升腾符文'),
(9780012, 'zhTW', '時光守護者',          '升騰符文'),
(9780012, 'esES', 'Guardián del Tiempo','Runas de Ascensión'),
(9780012, 'esMX', 'Guardián del Tiempo','Runas de Ascensión'),
(9780012, 'ruRU', 'Хранитель Времени',  'Руны Вознесения');

-- The gossip greeting. Text0_0 is group 0, variant 0 - the only one the
-- Guardian has; the other Text* columns stay NULL.
DELETE FROM `npc_text_locale` WHERE `ID` = 9780012;
INSERT INTO `npc_text_locale` (`ID`, `Locale`, `Text0_0`) VALUES
(9780012, 'koKR', '시간은 모든 것을 갉아먹습니다. 세계가 벼려낸 것과 충분한 룬을 가져오면, 다시 완전하게 만들어 드리겠습니다.'),
(9780012, 'frFR', 'Le temps use toute chose. Apportez-moi ce que le monde a forgé, et des runes en suffisance, et je le referai entier.'),
(9780012, 'deDE', 'Die Zeit zerfrißt alles. Bringt mir, was die Welt schmiedete, und Runen genug, und ich werde es wieder ganz machen.'),
(9780012, 'zhCN', '时间磨蚀万物。把世界铸就之物和足够的符文带给我，我会让它重归完整。'),
(9780012, 'zhTW', '時間磨蝕萬物。將世界鑄就之物與足夠的符文帶給我，我將使它重歸完整。'),
(9780012, 'esES', 'El tiempo lo desgasta todo. Tráeme lo que forjó el mundo y runas suficientes, y lo restauraré por completo.'),
(9780012, 'esMX', 'El tiempo lo desgasta todo. Tráeme lo que forjó el mundo y runas suficientes, y lo restauraré por completo.'),
(9780012, 'ruRU', 'Время стирает всё. Принесите то, что выковал мир, и рун достаточно — и я снова сделаю его целым.');
