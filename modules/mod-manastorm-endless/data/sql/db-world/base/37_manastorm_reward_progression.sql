-- Custom server tuning requested by the owner; not recovered Ascension amounts.
-- Apply after SQL 36. Retain repeatable 200 Marks; add 100 on first completion.
-- First-clear ownership remains separate for Solo/Duo/Trio/Group and each track.
-- Endgame Cases: 1 at depths 1-49, 2 at 50-99, 3 at 100-149, and so on.
-- These are fixed counts; group/map multipliers do not change Marks or Cases.
-- Bedlam, Bonzo, cache brackets and Treasure Keeper bonus rules are untouched.
DELETE FROM `manastorm_reward_rule` WHERE `reward_key` IN ('MARKS', 'MARKS_FIRST', 'CASE');
INSERT INTO `manastorm_reward_rule`
(`reward_key`, `item_entry`, `base_amount`, `depth_step`, `amount_per_step`,
 `first_clear_only`, `apply_group_multiplier`, `apply_segment_multiplier`, `enabled`)
VALUES
('MARKS', 111381, 200, 1, 0, 0, 0, 0, 1),
('MARKS_FIRST', 111381, 100, 1, 0, 1, 0, 0, 1),
('CASE', 1278049, 1, 50, 1, 0, 0, 0, 1);
