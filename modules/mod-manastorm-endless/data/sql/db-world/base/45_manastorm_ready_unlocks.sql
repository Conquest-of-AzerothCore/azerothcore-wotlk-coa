-- Restore validated progression in the 2026-10-07 world export.
-- Apply after SQL 06/07/21. Restart worldserver after applying.
-- Enable one existing definition per boss: the duplicate staged definitions
-- remain disabled. Preserve message IDs for Mode 1 and native transport for Mode 2.
-- No segment, teleport, affix availability policy or character history is changed.
-- Paired introductions with an unavailable track remain staged, including Manaclaw.
-- Only already enabled intro segments are accepted; enabled is not teleport validation.

START TRANSACTION;

-- Fourteen recovered progression-owned affixes; enable definitions, triggers
-- and grants together. SQL 03 alone does not enable native-track trigger rows.
UPDATE `manastorm_unlock` AS `u`
INNER JOIN `manastorm_unlock_grant` AS `g`
    ON `g`.`unlock_id` = `u`.`unlock_id` AND `g`.`grant_type` = 4
INNER JOIN `manastorm_affix_catalog` AS `a`
    ON `a`.`affix_id` = `g`.`content_id`
SET `u`.`enabled` = 1
WHERE `u`.`unlock_id` IN (
    900011, 900013, 900016, 900019, 900021, 900023,
    900026, 900028, 900031, 900033, 900039, 900041,
    900061, 900101
)
  AND `u`.`unlock_kind` = 1
  AND `a`.`enabled` = 1 AND `a`.`availability_kind` = 1;

-- Ready endgame introductions: nine Molten Core bosses and Onyxia.
UPDATE `manastorm_unlock` AS `u`
INNER JOIN `manastorm_segment` AS `s`
    ON `s`.`segment_id` = `u`.`endgame_intro_segment_id`
SET `u`.`enabled` = 1
WHERE `u`.`unlock_id` IN (
    1000220, 1000235, 1000250, 1000265, 1000280, 1000295,
    1000310, 1000335, 1000350, 1000365
)
  AND `u`.`unlock_kind` = 0 AND `u`.`track_mask` = 2
  AND `s`.`enabled` = 1 AND `s`.`difficulty` = 2
  AND `s`.`start_game_tele_id` <> 0;

UPDATE `manastorm_unlock_trigger` AS `t`
INNER JOIN `manastorm_unlock` AS `u`
    ON `u`.`unlock_id` = `t`.`unlock_id`
SET `t`.`enabled` = 1
WHERE `u`.`unlock_id` IN (
    900011, 900013, 900016, 900019, 900021, 900023,
    900026, 900028, 900031, 900033, 900039, 900041,
    900061, 900101, 1000220, 1000235, 1000250, 1000265,
    1000280, 1000295, 1000310, 1000335, 1000350, 1000365
)
  AND `u`.`enabled` = 1 AND (`u`.`track_mask` & `t`.`track`) <> 0;

UPDATE `manastorm_unlock_grant` AS `g`
INNER JOIN `manastorm_unlock` AS `u`
    ON `u`.`unlock_id` = `g`.`unlock_id`
SET `g`.`enabled` = 1
WHERE `u`.`unlock_id` IN (
    900011, 900013, 900016, 900019, 900021, 900023,
    900026, 900028, 900031, 900033, 900039, 900041,
    900061, 900101, 1000220, 1000235, 1000250, 1000265,
    1000280, 1000295, 1000310, 1000335, 1000350, 1000365
)
  AND `u`.`enabled` = 1;

COMMIT;
