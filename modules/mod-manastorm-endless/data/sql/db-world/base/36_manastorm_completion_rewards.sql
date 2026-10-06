-- Apply to acore_world. User-selected tuning, not recovered Ascension quantities.
-- 200 Marks each completed floor; one random Ability/Talent Case on endgame floors.
-- Fixed amounts: group/map multipliers and depth scaling are disabled for these rows.
-- Bedlam, Bonzo and Treasure Keeper bonus rewards retain their existing policies.
DELETE FROM `manastorm_reward_rule` WHERE `reward_key` IN ('MARKS', 'CASE');
INSERT INTO `manastorm_reward_rule`
(`reward_key`, `item_entry`, `base_amount`, `depth_step`, `amount_per_step`,
 `first_clear_only`, `apply_group_multiplier`, `apply_segment_multiplier`, `enabled`)
VALUES
('MARKS', 111381, 200, 1, 0, 0, 0, 0, 1),
('CASE', 1278049, 1, 1, 0, 0, 0, 0, 1);
