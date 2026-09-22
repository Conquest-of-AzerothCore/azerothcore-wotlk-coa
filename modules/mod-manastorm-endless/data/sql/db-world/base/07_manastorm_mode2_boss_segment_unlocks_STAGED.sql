-- Native Mode-2 boss/encounter progression reconstruction — STAGED DISABLED.
--
-- Each definition below is backed by:
-- 1) a Patch-M "in your next Manastorm" row at trigger depth;
-- 2) the matching permanent future-content row on the next depth;
-- 3) a UNIQUE same-track segment resolved through DungeonEncounter.dbc + Manastorm.dbc.
--
-- Nothing is enabled automatically. Ambiguous/multi-variant families are excluded.
-- Native Mode 2 renders text from ManastormMessages.dbc; no toast text is duplicated here.

-- Manaclaw | track=1 trigger=38 introMsg=701 complete=39 completionMsg=702 segment=411 encounter=5012; track=2 trigger=38 introMsg=700 complete=39 completionMsg=703 segment=476 encounter=5014
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000039,0,38,15,3,411,476,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000039,1,38,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000039,2,38,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000039,1,411,0) ON DUPLICATE KEY UPDATE `enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000039,1,476,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Muckrake | track=1 trigger=65 introMsg=723 complete=66 completionMsg=724 segment=407 encounter=4994; track=2 trigger=65 introMsg=721 complete=66 completionMsg=722 segment=480 encounter=4996
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000066,0,65,15,3,407,480,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000066,1,65,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000066,2,65,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000066,1,407,0) ON DUPLICATE KEY UPDATE `enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000066,1,480,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Grol the Destroyer | track=1 trigger=70 introMsg=800 complete=71 completionMsg=802 segment=409 encounter=5000; track=2 trigger=70 introMsg=801 complete=71 completionMsg=803 segment=478 encounter=5002
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000071,0,70,15,3,409,478,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000071,1,70,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000071,2,70,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000071,1,409,0) ON DUPLICATE KEY UPDATE `enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000071,1,478,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Archmage Allistarj | track=1 trigger=75 introMsg=9 complete=76 completionMsg=264 segment=552 encounter=5036; track=2 trigger=75 introMsg=20 complete=76 completionMsg=275 segment=553 encounter=5038
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000076,0,75,15,3,552,553,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000076,1,75,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000076,2,75,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000076,1,552,0) ON DUPLICATE KEY UPDATE `enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000076,1,553,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Razelikh the Defiler | track=1 trigger=90 introMsg=727 complete=91 completionMsg=725 segment=542 encounter=5030; track=2 trigger=90 introMsg=728 complete=91 completionMsg=726 segment=543 encounter=5032
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000091,0,90,15,3,542,543,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000091,1,90,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000091,2,90,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000091,1,542,0) ON DUPLICATE KEY UPDATE `enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000091,1,543,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Solakar Flamewreath | track=1 trigger=102 introMsg=730 complete=103 completionMsg=732 segment=669 encounter=277; track=2 trigger=102 introMsg=731 complete=103 completionMsg=733 segment=668 encounter=2277
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000103,0,102,15,3,669,668,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000103,1,102,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000103,2,102,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000103,1,668,0) ON DUPLICATE KEY UPDATE `enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000103,1,669,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Nyx and Nocturna | track=2 trigger=108 introMsg=622 complete=109 completionMsg=1201 segment=949 encounter=9009
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000109,0,108,15,2,0,949,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000109,2,108,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000109,1,949,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- High Priestess Mar'li | track=2 trigger=115 introMsg=24 complete=116 completionMsg=278 segment=601 encounter=4278
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000116,0,115,15,2,0,601,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000116,2,115,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000116,1,601,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Leafborn Sentinel | track=2 trigger=123 introMsg=1203 complete=124 completionMsg=1204 segment=950 encounter=9006
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000124,0,123,15,2,0,950,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000124,2,123,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000124,1,950,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Mechatron | track=2 trigger=128 introMsg=625 complete=129 completionMsg=1206 segment=951 encounter=9013
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000129,0,128,15,2,0,951,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000129,2,128,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000129,1,951,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- High Priest Thekal | track=2 trigger=130 introMsg=25 complete=131 completionMsg=279 segment=602 encounter=4281
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000131,0,130,15,2,0,602,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000131,2,130,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000131,1,602,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Jin'do the Hexxer | track=2 trigger=175 introMsg=28 complete=176 completionMsg=282 segment=605 encounter=4284
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000176,0,175,15,2,0,605,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000176,2,175,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000176,1,605,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- High Priestess Jeklik | track=2 trigger=190 introMsg=29 complete=191 completionMsg=283 segment=606 encounter=4277
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000191,0,190,15,2,0,606,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000191,2,190,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000191,1,606,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Hakkar | track=2 trigger=205 introMsg=30 complete=206 completionMsg=284 segment=607 encounter=4285
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000206,0,205,15,2,0,607,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000206,2,205,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000206,1,607,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Lucifron | track=2 trigger=235 introMsg=32 complete=236 completionMsg=286 segment=608 encounter=4221
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000236,0,235,15,2,0,608,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000236,2,235,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000236,1,608,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Magmadar | track=2 trigger=250 introMsg=33 complete=251 completionMsg=287 segment=609 encounter=4222
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000251,0,250,15,2,0,609,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000251,2,250,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000251,1,609,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Garr | track=2 trigger=265 introMsg=34 complete=266 completionMsg=288 segment=611 encounter=4224
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000266,0,265,15,2,0,611,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000266,2,265,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000266,1,611,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Shazzrah | track=2 trigger=280 introMsg=35 complete=281 completionMsg=289 segment=612 encounter=4225
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000281,0,280,15,2,0,612,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000281,2,280,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000281,1,612,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Baron Geddon | track=2 trigger=295 introMsg=36 complete=296 completionMsg=290 segment=613 encounter=4226
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000296,0,295,15,2,0,613,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000296,2,295,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000296,1,613,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Sulfuron Harbinger | track=2 trigger=310 introMsg=37 complete=311 completionMsg=291 segment=614 encounter=4227
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000311,0,310,15,2,0,614,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000311,2,310,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000311,1,614,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Golemagg the Incinerator | track=2 trigger=335 introMsg=38 complete=336 completionMsg=292 segment=615 encounter=4228
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000336,0,335,15,2,0,615,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000336,2,335,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000336,1,615,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Ragnaros | track=2 trigger=350 introMsg=500 complete=351 completionMsg=501 segment=670 encounter=4229
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000351,0,350,15,2,0,670,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000351,2,350,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000351,1,670,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Onyxia | track=2 trigger=365 introMsg=440 complete=366 completionMsg=441 segment=707 encounter=4244
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000366,0,365,15,2,0,707,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000366,2,365,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000366,1,707,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Vaelastrasz the Corrupt | track=2 trigger=425 introMsg=39 complete=426 completionMsg=293 segment=617 encounter=4200
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000426,0,425,15,2,0,617,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000426,2,425,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000426,1,617,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Broodlord Lashlayer | track=2 trigger=440 introMsg=40 complete=441 completionMsg=294 segment=618 encounter=4201
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000441,0,440,15,2,0,618,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000441,2,440,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000441,1,618,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Firemaw | track=2 trigger=455 introMsg=41 complete=456 completionMsg=295 segment=619 encounter=4202
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000456,0,455,15,2,0,619,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000456,2,455,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000456,1,619,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Chromaggus | track=2 trigger=470 introMsg=42 complete=471 completionMsg=296 segment=620 encounter=4203
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000471,0,470,15,2,0,620,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000471,2,470,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000471,1,620,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- General Rajaxx | track=2 trigger=525 introMsg=44 complete=526 completionMsg=298 segment=622 encounter=4255
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000526,0,525,15,2,0,622,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000526,2,525,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000526,1,622,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Buru the Gorger | track=2 trigger=540 introMsg=45 complete=541 completionMsg=299 segment=623 encounter=4257
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000541,0,540,15,2,0,623,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000541,2,540,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000541,1,623,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Ayamiss the Hunter | track=2 trigger=555 introMsg=46 complete=556 completionMsg=300 segment=624 encounter=4258
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000556,0,555,15,2,0,624,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000556,2,555,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000556,1,624,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Moam | track=2 trigger=570 introMsg=47 complete=571 completionMsg=301 segment=626 encounter=4256
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000571,0,570,15,2,0,626,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000571,2,570,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000571,1,626,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Ossirian the Unscarred | track=2 trigger=595 introMsg=48 complete=596 completionMsg=302 segment=625 encounter=4259
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000596,0,595,15,2,0,625,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000596,2,595,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000596,1,625,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Battleguard Sartura | track=2 trigger=625 introMsg=50 complete=626 completionMsg=304 segment=628 encounter=4247
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000626,0,625,15,2,0,628,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000626,2,625,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000626,1,628,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Fankriss the Unyielding | track=2 trigger=640 introMsg=51 complete=641 completionMsg=305 segment=629 encounter=4248
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000641,0,640,15,2,0,629,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000641,2,640,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000641,1,629,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Viscidus | track=2 trigger=655 introMsg=52 complete=656 completionMsg=306 segment=632 encounter=4249
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000656,0,655,15,2,0,632,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000656,2,655,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000656,1,632,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Princess Huhuran | track=2 trigger=670 introMsg=53 complete=671 completionMsg=307 segment=631 encounter=4250
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000671,0,670,15,2,0,631,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000671,2,670,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000671,1,631,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Twin Emperors | track=2 trigger=685 introMsg=54 complete=686 completionMsg=308 segment=634 encounter=4251
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000686,0,685,15,2,0,634,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000686,2,685,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000686,1,634,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Ouro | track=2 trigger=700 introMsg=55 complete=701 completionMsg=309 segment=633 encounter=4252
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000701,0,700,15,2,0,633,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000701,2,700,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000701,1,633,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- C'thun | track=2 trigger=725 introMsg=56 complete=726 completionMsg=310 segment=635 encounter=4253
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000726,0,725,15,2,0,635,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000726,2,725,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000726,1,635,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Grand Widow Faerlina | track=2 trigger=755 introMsg=58 complete=756 completionMsg=312 segment=641 encounter=4231
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000756,0,755,15,2,0,641,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000756,2,755,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000756,1,641,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Maexxna | track=2 trigger=770 introMsg=59 complete=771 completionMsg=313 segment=642 encounter=4232
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000771,0,770,15,2,0,642,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000771,2,770,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000771,1,642,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Noth the Plaguebringer | track=2 trigger=785 introMsg=60 complete=786 completionMsg=314 segment=643 encounter=4233
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000786,0,785,15,2,0,643,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000786,2,785,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000786,1,643,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Heigan the Unclean | track=2 trigger=800 introMsg=61 complete=801 completionMsg=315 segment=644 encounter=4234
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000801,0,800,15,2,0,644,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000801,2,800,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000801,1,644,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Loatheb | track=2 trigger=815 introMsg=62 complete=816 completionMsg=316 segment=645 encounter=4235
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000816,0,815,15,2,0,645,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000816,2,815,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000816,1,645,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Patchwerk | track=2 trigger=830 introMsg=63 complete=831 completionMsg=317 segment=636 encounter=4238
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000831,0,830,15,2,0,636,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000831,2,830,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000831,1,636,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Grobbulus | track=2 trigger=845 introMsg=64 complete=846 completionMsg=318 segment=637 encounter=4239
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000846,0,845,15,2,0,637,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000846,2,845,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000846,1,637,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Gluth | track=2 trigger=860 introMsg=65 complete=861 completionMsg=319 segment=638 encounter=4240
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000861,0,860,15,2,0,638,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000861,2,860,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000861,1,638,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Thaddius | track=2 trigger=875 introMsg=66 complete=876 completionMsg=320 segment=639 encounter=4241
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000876,0,875,15,2,0,639,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000876,2,875,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000876,1,639,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Instructor Razuvious | track=2 trigger=890 introMsg=67 complete=891 completionMsg=321 segment=646 encounter=4236
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000891,0,890,15,2,0,646,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000891,2,890,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000891,1,646,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Gothik the Harvester | track=2 trigger=905 introMsg=68 complete=906 completionMsg=322 segment=647 encounter=4237
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000906,0,905,15,2,0,647,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000906,2,905,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000906,1,647,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Sapphiron | track=2 trigger=920 introMsg=69 complete=921 completionMsg=323 segment=648 encounter=4242
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000921,0,920,15,2,0,648,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000921,2,920,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000921,1,648,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Kel'Thuzad | track=2 trigger=945 introMsg=70 complete=946 completionMsg=324 segment=649 encounter=4243
INSERT INTO `manastorm_unlock` (`unlock_id`,`unlock_kind`,`trigger_depth`,`mode_mask`,`track_mask`,`intro_segment_id`,`endgame_intro_segment_id`,`intro_message_id`,`completion_message_id`,`enabled`) VALUES (1000946,0,945,15,2,0,649,0,0,0) ON DUPLICATE KEY UPDATE `unlock_kind`=VALUES(`unlock_kind`),`trigger_depth`=VALUES(`trigger_depth`),`mode_mask`=VALUES(`mode_mask`),`track_mask`=VALUES(`track_mask`),`intro_segment_id`=VALUES(`intro_segment_id`),`endgame_intro_segment_id`=VALUES(`endgame_intro_segment_id`),`intro_message_id`=0,`completion_message_id`=0,`enabled`=0;
INSERT INTO `manastorm_unlock_trigger` (`unlock_id`,`track`,`trigger_depth`,`enabled`) VALUES (1000946,2,945,0) ON DUPLICATE KEY UPDATE `trigger_depth`=VALUES(`trigger_depth`),`enabled`=0;
INSERT INTO `manastorm_unlock_grant` (`unlock_id`,`grant_type`,`content_id`,`enabled`) VALUES (1000946,1,649,0) ON DUPLICATE KEY UPDATE `enabled`=0;

-- Audit: all reconstructed rows must remain disabled until exact stage content is authored/validated.
SELECT u.`unlock_id`,u.`track_mask`,u.`intro_segment_id`,u.`endgame_intro_segment_id`,
       COUNT(DISTINCT t.`track`) AS trigger_tracks,
       COUNT(DISTINCT g.`content_id`) AS segment_grants,
       u.`enabled`
FROM `manastorm_unlock` u
LEFT JOIN `manastorm_unlock_trigger` t ON t.`unlock_id`=u.`unlock_id`
LEFT JOIN `manastorm_unlock_grant` g ON g.`unlock_id`=u.`unlock_id` AND g.`grant_type`=1
WHERE u.`unlock_id` BETWEEN 1000000 AND 1009999
GROUP BY u.`unlock_id`,u.`track_mask`,u.`intro_segment_id`,u.`endgame_intro_segment_id`,u.`enabled`
ORDER BY u.`unlock_id`;
