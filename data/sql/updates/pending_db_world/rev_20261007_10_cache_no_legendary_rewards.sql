-- Caches never pay a legendary: drop Quality 5 rewards from Cache of the Fire Lord and the Prestigious Caches.
DELETE `p` FROM `coa_mc_fire_lord_cache_pool` `p`
    JOIN `item_template` `i` ON `i`.`entry` = `p`.`ItemEntry`
    WHERE `i`.`Quality` = 5;

DELETE `r` FROM `ascension_prestigious_cache_reward` `r`
    JOIN `item_template` `i` ON `i`.`entry` = `r`.`RewardItemId`
    WHERE `i`.`Quality` = 5;
