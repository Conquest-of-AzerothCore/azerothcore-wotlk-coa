-- Evidence-backed segment gates; apply AFTER SQL 45 with the accompanying loader change.
-- Retain existing canonical ownership IDs. Disable duplicate staged definitions only.
-- Enable the mapping independently of segment readiness: the loader defers disabled
-- segments/tracks. Adding a valid teleport AND enabling its segment activates its gate.
-- No teleport, creature pool, affix policy, reward rule or character history is authored.
-- Ambiguous area/variant introductions are listed in the accompanying mapping inventory.
-- Re-running older SQL 07 or foundation seeds afterwards can reset these enable flags.

START TRANSACTION;

-- Duplicate definitions must never compete with their canonical introductions.
UPDATE `manastorm_unlock` SET `enabled` = 0
WHERE `unlock_id` IN (
    1000039, 1000066, 1000071, 1000076, 1000091, 1000103,
    1000109, 1000116, 1000124, 1000129, 1000131, 1000176,
    1000191, 1000206, 1000236, 1000251, 1000266, 1000281,
    1000296, 1000311, 1000336, 1000351, 1000366, 1000426,
    1000441, 1000456, 1000471, 1000526, 1000541, 1000556,
    1000571, 1000596, 1000626, 1000641, 1000656, 1000671,
    1000686, 1000701, 1000726, 1000756, 1000771, 1000786,
    1000801, 1000816, 1000831, 1000846, 1000861, 1000876,
    1000891, 1000906, 1000921, 1000946
);
UPDATE `manastorm_unlock_trigger` SET `enabled` = 0
WHERE `unlock_id` IN (
    1000039, 1000066, 1000071, 1000076, 1000091, 1000103,
    1000109, 1000116, 1000124, 1000129, 1000131, 1000176,
    1000191, 1000206, 1000236, 1000251, 1000266, 1000281,
    1000296, 1000311, 1000336, 1000351, 1000366, 1000426,
    1000441, 1000456, 1000471, 1000526, 1000541, 1000556,
    1000571, 1000596, 1000626, 1000641, 1000656, 1000671,
    1000686, 1000701, 1000726, 1000756, 1000771, 1000786,
    1000801, 1000816, 1000831, 1000846, 1000861, 1000876,
    1000891, 1000906, 1000921, 1000946
);
UPDATE `manastorm_unlock_grant` SET `enabled` = 0
WHERE `unlock_id` IN (
    1000039, 1000066, 1000071, 1000076, 1000091, 1000103,
    1000109, 1000116, 1000124, 1000129, 1000131, 1000176,
    1000191, 1000206, 1000236, 1000251, 1000266, 1000281,
    1000296, 1000311, 1000336, 1000351, 1000366, 1000426,
    1000441, 1000456, 1000471, 1000526, 1000541, 1000556,
    1000571, 1000596, 1000626, 1000641, 1000656, 1000671,
    1000686, 1000701, 1000726, 1000756, 1000771, 1000786,
    1000801, 1000816, 1000831, 1000846, 1000861, 1000876,
    1000891, 1000906, 1000921, 1000946
);

-- Existing mapped introductions, including both native tracks where supplied.
UPDATE `manastorm_unlock` SET `enabled` = 1
WHERE `unlock_id` IN (
    1000005, 1000010, 1000018, 1000025, 1000035, 1000038,
    1000048, 1000062, 1000065, 1000070, 1000075, 1000090,
    1000100, 1000102, 1000105, 1000108, 1000115, 1000120,
    1000123, 1000128, 1000130, 1000140, 1000170, 1000175,
    1000190, 1000205, 1000220, 1000235, 1000250, 1000265,
    1000280, 1000295, 1000310, 1000335, 1000350, 1000365,
    1000410, 1000425, 1000440, 1000455, 1000470, 1000510,
    1000525, 1000540, 1000555, 1000570, 1000595, 1000610,
    1000625, 1000640, 1000655, 1000670, 1000685, 1000700,
    1000725, 1000755, 1000770, 1000785, 1000800, 1000815,
    1000830, 1000845, 1000860, 1000875, 1000890, 1000905,
    1000920, 1000945
);
UPDATE `manastorm_unlock_trigger` SET `enabled` = 1
WHERE `unlock_id` IN (
    1000005, 1000010, 1000018, 1000025, 1000035, 1000038,
    1000048, 1000062, 1000065, 1000070, 1000075, 1000090,
    1000100, 1000102, 1000105, 1000108, 1000115, 1000120,
    1000123, 1000128, 1000130, 1000140, 1000170, 1000175,
    1000190, 1000205, 1000220, 1000235, 1000250, 1000265,
    1000280, 1000295, 1000310, 1000335, 1000350, 1000365,
    1000410, 1000425, 1000440, 1000455, 1000470, 1000510,
    1000525, 1000540, 1000555, 1000570, 1000595, 1000610,
    1000625, 1000640, 1000655, 1000670, 1000685, 1000700,
    1000725, 1000755, 1000770, 1000785, 1000800, 1000815,
    1000830, 1000845, 1000860, 1000875, 1000890, 1000905,
    1000920, 1000945
);
UPDATE `manastorm_unlock_grant` SET `enabled` = 1
WHERE `unlock_id` IN (
    1000005, 1000010, 1000018, 1000025, 1000035, 1000038,
    1000048, 1000062, 1000065, 1000070, 1000075, 1000090,
    1000100, 1000102, 1000105, 1000108, 1000115, 1000120,
    1000123, 1000128, 1000130, 1000140, 1000170, 1000175,
    1000190, 1000205, 1000220, 1000235, 1000250, 1000265,
    1000280, 1000295, 1000310, 1000335, 1000350, 1000365,
    1000410, 1000425, 1000440, 1000455, 1000470, 1000510,
    1000525, 1000540, 1000555, 1000570, 1000595, 1000610,
    1000625, 1000640, 1000655, 1000670, 1000685, 1000700,
    1000725, 1000755, 1000770, 1000785, 1000800, 1000815,
    1000830, 1000845, 1000860, 1000875, 1000890, 1000905,
    1000920, 1000945
);

-- Altar of Storms: official changelog identifies Lady Sevine as its encounter.
-- DBC messages 7/18 introduce it at 55; 261/272 complete it at 56.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 1000055;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (1000055, 0, 55, 15, 3, 554, 555, 7, 261, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 1000055;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (1000055, 1, 55, 1), (1000055, 2, 55, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 1000055;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (1000055, 1, 554, 1), (1000055, 1, 555, 1);

-- Unique future-content messages without a recovered next-run introduction.
-- Preserve exact client depths, including Adeline's unusual 8600.

-- Message 265, difficulty 0, depth 8600: segment 563.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000265;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000265, 1, 8600, 15, 1, 0, 0, 0, 265, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000265;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000265, 1, 8600, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000265;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000265, 1, 563, 1);

-- Message 276, difficulty 2, depth 8600: segment 562.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000276;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000276, 1, 8600, 15, 2, 0, 0, 0, 276, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000276;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000276, 2, 8600, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000276;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000276, 1, 562, 1);

-- Message 280, difficulty 2, depth 146: segment 604.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000280;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000280, 1, 146, 15, 2, 0, 0, 0, 280, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000280;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000280, 2, 146, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000280;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000280, 1, 604, 1);

-- Message 311, difficulty 2, depth 741: segment 640.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000311;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000311, 1, 741, 15, 2, 0, 0, 0, 311, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000311;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000311, 2, 741, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000311;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000311, 1, 640, 1);

-- Message 736, difficulty 0, depth 104: segment 658.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000736;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000736, 1, 104, 15, 1, 0, 0, 0, 736, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000736;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000736, 1, 104, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000736;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000736, 1, 658, 1);

-- Message 737, difficulty 2, depth 104: segment 659.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000737;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000737, 1, 104, 15, 2, 0, 0, 0, 737, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000737;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000737, 2, 104, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000737;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000737, 1, 659, 1);

-- Message 740, difficulty 0, depth 395: segment 663.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000740;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000740, 1, 395, 15, 1, 0, 0, 0, 740, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000740;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000740, 1, 395, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000740;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000740, 1, 663, 1);

-- Message 741, difficulty 2, depth 380: segment 662.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2000741;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2000741, 1, 380, 15, 2, 0, 0, 0, 741, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2000741;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2000741, 2, 380, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2000741;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2000741, 1, 662, 1);

-- Message 1205, difficulty 2, depth 119: segment 948.
DELETE FROM `manastorm_unlock` WHERE `unlock_id` = 2001205;
INSERT INTO `manastorm_unlock`
(`unlock_id`, `unlock_kind`, `trigger_depth`, `mode_mask`, `track_mask`,
 `intro_segment_id`, `endgame_intro_segment_id`, `intro_message_id`, `completion_message_id`, `enabled`)
VALUES (2001205, 1, 119, 15, 2, 0, 0, 0, 1205, 1);
DELETE FROM `manastorm_unlock_trigger` WHERE `unlock_id` = 2001205;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`, `track`, `trigger_depth`, `enabled`)
VALUES (2001205, 2, 119, 1);
DELETE FROM `manastorm_unlock_grant` WHERE `unlock_id` = 2001205;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`, `grant_type`, `content_id`, `enabled`)
VALUES (2001205, 1, 948, 1);

-- These targets are progression-owned, including targets still disabled for authoring.
UPDATE `manastorm_segment` SET `flags` = `flags` & ~1
WHERE `segment_id` IN (
    554, 555,
    526, 527, 584, 585, 577, 579,
    576, 578, 540, 541, 411, 476,
    580, 581, 822, 933, 407, 480,
    409, 478, 552, 553, 542, 543,
    556, 557, 668, 669, 600, 949,
    601, 815, 926, 950, 951, 602,
    816, 927, 818, 929, 605, 606,
    607, 610, 608, 609, 611, 612,
    613, 614, 615, 670, 707, 616,
    617, 618, 619, 620, 621, 622,
    623, 624, 626, 625, 627, 628,
    629, 632, 631, 634, 633, 635,
    641, 642, 643, 644, 645, 636,
    637, 638, 639, 646, 647, 648,
    649, 563, 562, 604, 640, 658,
    659, 663, 662, 948
);

COMMIT;
