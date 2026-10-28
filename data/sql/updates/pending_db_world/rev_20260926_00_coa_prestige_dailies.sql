-- mod-coa-prestige: the Prestige dailies (quests 80954/80955/80956).
--
-- Source of the quest rows: the realm's public table dump (ascension-data/
-- _release, coa-public-2026-09-13-tables.tar -> tables/quest.csv.gz, quest_sort_id
-- 11211). Values: QuestType 2 (normal), QuestLevel -1 (scales), Flags 4160
-- (0x1000 DAILY | 0x40 RAID). The dump's reward_choice_items encodes a pair; the
-- quests grant both: 25000 Runes of Ascension plus Tokens of Prestige (100 for
-- Battlegrounds/Dungeons, 200 for Open World).
--
-- Delivery: the daily is granted by mod-coa-prestige (CoAPrestige.cpp, Activate)
-- when the character prestiges, and turned in at Chromie 178081
-- (creature_questender), matching QuestCompletionLog "Return to Chromie.".
-- Only one daily is offered per day via three rotating game events (191/192/193).
-- PrestigeMode.lua matches the gossip label "^Today's Prestige Quest is (.*)$".
--
-- Each daily has two objectives and completes only when both are met:
--   * "Max Level Reached" (count 1), credited at the required level;
--   * the content counter (5 battlegrounds / 5 dungeons / 25 daily quests),
--     credited by CoAPrestige.cpp hooks (BG end, dungeon last boss, daily turn-in).

-- --------------------------------------------------------------- Chromie
-- Chromie's npcflag 131 (GOSSIP | VENDOR | QUESTGIVER) comes from
-- rev_20260925_02_coa_prestige_chromie.sql; the turn-in dialog needs nothing
-- further here.

-- ---------------------------------------------------------- credit creatures
-- Dummy kill-credit creatures the objectives reference. They are never spawned.
-- RequiredNpcOrGo entries must exist in creature_template, otherwise
-- ObjectMgr::LoadQuests zeroes the objective ("creature ... does not exist") and
-- the quest auto-completes; KilledMonsterCredit() then credits by entry, and the
-- quest's ObjectiveText supplies the display string.
REPLACE INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`)
VALUES
(900001, 'Prestige Daily Credit: Max Level Reached',       '', 1, 1, 0, 0),
(900002, 'Prestige Daily Credit: Battlegrounds Completed', '', 1, 1, 0, 0),
(900003, 'Prestige Daily Credit: Dungeons Completed',      '', 1, 1, 0, 0),
(900004, 'Prestige Daily Credit: Daily Quests Completed',  '', 1, 1, 0, 0);

-- ------------------------------------------------------------------ quests
-- Two aims per daily, both credited by module hooks:
--   * aim 1 (RequiredNpcOrGo1, count 1): "Max Level Reached".
--   * aim 2 (RequiredNpcOrGo2, count 5/5/25): the content counter.
-- The core auto-sets QUEST_SPECIAL_FLAGS_KILL when RequiredNpcOrGo is present, so
-- KilledMonsterCredit() credits these.
REPLACE INTO `quest_template`
(`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`,
 `RewardXPDifficulty`, `RewardMoney`, `Flags`,
 `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`,
 `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`,
 `RewardItem1`, `RewardAmount1`, `RewardItem2`, `RewardAmount2`,
 `TimeAllowed`, `AllowableRaces`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`,
 `QuestCompletionLog`, `VerifiedBuild`)
VALUES
(80954, 2, -1, 0, 11211, 0, 0, 0, 0, 4160,
 900001, 1, 'Max Level Reached', 900002, 5, 'Battlegrounds Completed',
 375250, 25000, 90004, 100, 0, 0,
 'Prestige: Battlegrounds',
 'Prestige with an extra bonus in Battlegrounds.',
 'This quest will give you and everyone currently prestiging in your party in your party bonus experience in Battlegrounds. This quests will only grant the bonus experience while doing that content. Reach max level and complete the objectives to claim the additional Prestige rewards!',
 '',
 'Return to Chromie.', 12340),
(80955, 2, -1, 0, 11211, 0, 0, 0, 0, 4160,
 900001, 1, 'Max Level Reached', 900003, 5, 'Dungeons Completed',
 375250, 25000, 90004, 100, 0, 0,
 'Prestige: Dungeons',
 'Prestige with an extra bonus in Dungeons.',
 'This quest will give you and everyone currently prestiging in your party bonus experience in Dungeons. This quests will only grant the bonus experience while doing that content. Reach max level and complete the objectives to claim the additional Prestige rewards!',
 '',
 'Return to Chromie.', 12340),
(80956, 2, -1, 0, 11211, 0, 0, 0, 0, 4160,
 900001, 1, 'Max Level Reached', 900004, 25, 'Daily Quests Completed',
 375250, 25000, 90004, 200, 0, 0,
 'Prestige: Open World',
 'Prestige with an extra bonus in the Open World.',
 'This quest will give you and everyone currently prestiging in your party bonus experience in the Open World. This quests will only grant the bonus experience while doing that content. Reach max level and complete the objectives to claim the additional Prestige rewards!',
 '',
 'Return to Chromie.', 12340);

-- ---------------------------------------------------------- daily rotation
-- Events 191/192/193 rotate the three dailies on a 3-day cycle: each is active
-- for one day every three days. occurence/length are in minutes.
DELETE FROM `game_event` WHERE `eventEntry` IN (191, 192, 193);
INSERT INTO `game_event`
(`eventEntry`, `start_time`, `end_time`, `occurence`, `length`, `holiday`, `holidayStage`,
 `description`, `world_event`, `announce`)
VALUES
(191, '2024-01-01 03:00:00', NULL, 4320, 1440, 0, 0, 'Prestige Daily: Battlegrounds', 0, 0),
(192, '2024-01-02 03:00:00', NULL, 4320, 1440, 0, 0, 'Prestige Daily: Dungeons',     0, 0),
(193, '2024-01-03 03:00:00', NULL, 4320, 1440, 0, 0, 'Prestige Daily: Open World',   0, 0);

-- -------------------------------------------------- availability conditions
-- None: the rotation (game events 191/192/193) decides which daily the prestige
-- hands out, not whether a held one can be turned in. Gating the turn-in on the
-- event (Player::GetQuestDialogStatus checks CONDITION_SOURCE_TYPE_QUEST_AVAILABLE)
-- would strand a daily collected on a previous day, but a collected daily may still
-- be finished and delivered later. The DELETE clears any condition a previous
-- revision added.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 19 AND `SourceEntry` IN (80954, 80955, 80956);

-- --------------------------------------------------------- completion flags
-- SpecialFlags 1 = REPEATABLE (so the daily can be re-granted on the next
-- prestige). Completion is gated by the two objectives above, not by
-- EXPLORATION_OR_EVENT. The core does not create `quest_template_addon` rows, so
-- the row is inserted here: a bare UPDATE would affect nothing on a fresh database.
DELETE FROM `quest_template_addon` WHERE `ID` IN (80954, 80955, 80956);
INSERT INTO `quest_template_addon` (`ID`, `SpecialFlags`) VALUES
(80954, 1), (80955, 1), (80956, 1);

-- ------------------------------------------------------------ turn-in NPC
DELETE FROM `creature_questender` WHERE `id` = 178081;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(178081, 80954), (178081, 80955), (178081, 80956);
