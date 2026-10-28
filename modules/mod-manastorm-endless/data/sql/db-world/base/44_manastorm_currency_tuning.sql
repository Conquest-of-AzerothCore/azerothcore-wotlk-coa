-- Apply to acore_world. Approximate calibration to the supplied S9 video.
-- Assumes eleven completed first-clear floors and 1x group/map multipliers.
-- Target video totals: Bedlam 165, Bonzo 3828. New baseline totals: 165/3830.
-- This is custom tuning, not a recovered Ascension currency formula.
-- Preserve existing depth steps, first-clear eligibility and multiplier flags.
UPDATE `manastorm_reward_rule` SET `base_amount` = 15, `amount_per_step` = 15 WHERE `reward_key` = 'BEDLAM';

UPDATE `manastorm_reward_rule` SET `base_amount` = 336, `amount_per_step` = 134 WHERE `reward_key` = 'BONZO';
