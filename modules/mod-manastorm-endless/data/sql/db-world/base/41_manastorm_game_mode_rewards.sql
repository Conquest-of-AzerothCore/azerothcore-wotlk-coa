-- Apply to acore_world after SQL 40.
-- BONUS_CACHE is Wildcard-only; BONUS_CACHE_OTHER is non-Wildcard-only.
-- Existing separate mode/track first-clear history is preserved.
-- The owner will define item 1478051's loot separately; do not alter its profile.
-- CASE completion rewards and Treasure Keeper Fortune Cases are Wildcard-only
-- in the accompanying source. Currency and normal cache rules are unchanged.
DELETE FROM `manastorm_reward_rule` WHERE `reward_key` = 'BONUS_CACHE_OTHER';
INSERT INTO `manastorm_reward_rule` (`reward_key`, `item_entry`, `base_amount`, `depth_step`, `amount_per_step`, `first_clear_only`, `apply_group_multiplier`, `apply_segment_multiplier`, `enabled`) VALUES
('BONUS_CACHE_OTHER', 1478051, 1, 1, 0, 1, 0, 0, 1);
