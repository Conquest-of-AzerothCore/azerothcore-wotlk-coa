-- Complete 26-reward RAF catalog; all items exist locally, but rewards remain disabled pending live tests.
-- Item 375250 is named Rune of Descension locally; confirm the intended Freepick reward before enabling.
-- Replays preserve existing settings; conflicting permanent reward identities fail before insertion.
SELECT IF(EXISTS (
  SELECT 1 FROM `recruit_rewards` AS `r`
  JOIN (
    SELECT 960101 AS `reward_id`, 1 AS `required_recruits`, 15 AS `realm_mode_mask`, 37719 AS `item_id`, 1 AS `quantity`
    UNION ALL
    SELECT 960102, 2, 15, 54860, 1
    UNION ALL
    SELECT 960103, 3, 1, 34493, 1
    UNION ALL
    SELECT 960104, 3, 2, 34492, 1
    UNION ALL
    SELECT 960105, 3, 4, 23713, 1
    UNION ALL
    SELECT 960106, 3, 8, 49287, 1
    UNION ALL
    SELECT 960107, 5, 15, 43599, 1
    UNION ALL
    SELECT 960108, 10, 1, 54069, 1
    UNION ALL
    SELECT 960109, 10, 2, 49282, 1
    UNION ALL
    SELECT 960110, 10, 4, 54068, 1
    UNION ALL
    SELECT 960111, 10, 8, 46778, 1
    UNION ALL
    SELECT 960112, 15, 15, 54811, 1
    UNION ALL
    SELECT 960113, 4, 15, 975001, 500
    UNION ALL
    SELECT 960114, 6, 15, 64998, 1
    UNION ALL
    SELECT 960115, 7, 8, 97913, 25
    UNION ALL
    SELECT 960116, 7, 8, 97933, 25
    UNION ALL
    SELECT 960117, 8, 2, 375250, 2000
    UNION ALL
    SELECT 960118, 8, 1, 98463, 5
    UNION ALL
    SELECT 960119, 9, 2, 97885, 25
    UNION ALL
    SELECT 960120, 9, 2, 97886, 25
    UNION ALL
    SELECT 960121, 12, 15, 8950009, 1
    UNION ALL
    SELECT 960122, 12, 15, 8950008, 1
    UNION ALL
    SELECT 960123, 18, 15, 8950005, 1
    UNION ALL
    SELECT 960124, 20, 15, 8950003, 1
    UNION ALL
    SELECT 960125, 25, 15, 8950001, 1
    UNION ALL
    SELECT 960126, 25, 15, 8950002, 1
  ) AS `candidate` ON `candidate`.`reward_id` = `r`.`reward_id`
  WHERE `r`.`required_recruits` <> `candidate`.`required_recruits` OR `r`.`realm_mode_mask` <> `candidate`.`realm_mode_mask` OR `r`.`item_id` <> `candidate`.`item_id` OR `r`.`quantity` <> `candidate`.`quantity`
), (SELECT 1 UNION SELECT 2), 1) INTO @raf_reward_catalog_ids_match;

INSERT IGNORE INTO `recruit_rewards`
  (`reward_id`, `required_recruits`, `realm_mode_mask`, `item_id`, `quantity`, `enabled`)
VALUES
(960101, 1, 15, 37719, 1, 0),
(960102, 2, 15, 54860, 1, 0),
(960103, 3, 1, 34493, 1, 0),
(960104, 3, 2, 34492, 1, 0),
(960105, 3, 4, 23713, 1, 0),
(960106, 3, 8, 49287, 1, 0),
(960107, 5, 15, 43599, 1, 0),
(960108, 10, 1, 54069, 1, 0),
(960109, 10, 2, 49282, 1, 0),
(960110, 10, 4, 54068, 1, 0),
(960111, 10, 8, 46778, 1, 0),
(960112, 15, 15, 54811, 1, 0),
(960113, 4, 15, 975001, 500, 0),
(960114, 6, 15, 64998, 1, 0),
(960115, 7, 8, 97913, 25, 0),
(960116, 7, 8, 97933, 25, 0),
(960117, 8, 2, 375250, 2000, 0),
(960118, 8, 1, 98463, 5, 0),
(960119, 9, 2, 97885, 25, 0),
(960120, 9, 2, 97886, 25, 0),
(960121, 12, 15, 8950009, 1, 0),
(960122, 12, 15, 8950008, 1, 0),
(960123, 18, 15, 8950005, 1, 0),
(960124, 20, 15, 8950003, 1, 0),
(960125, 25, 15, 8950001, 1, 0),
(960126, 25, 15, 8950002, 1, 0);
