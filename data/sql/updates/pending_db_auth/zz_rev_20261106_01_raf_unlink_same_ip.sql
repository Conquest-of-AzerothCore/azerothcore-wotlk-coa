CREATE TEMPORARY TABLE `raf_same_ip_recruits` (
    `account_id` INT UNSIGNED NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

START TRANSACTION;

INSERT IGNORE INTO `raf_link_lock` (`id`) VALUES (1);
UPDATE `raf_link_lock` SET `generation` = `generation` + 1 WHERE `id` = 1;

INSERT IGNORE INTO `raf_same_ip_recruits` (`account_id`)
SELECT `recruit`.`id`
FROM `account` `recruit`
JOIN `account` `recruiter` ON `recruiter`.`id` = `recruit`.`recruiter`
WHERE `recruit`.`last_login` IS NOT NULL AND `recruiter`.`last_login` IS NOT NULL
  AND COALESCE(INET6_ATON(CONCAT('::ffff:', `recruit`.`last_ip`)), INET6_ATON(`recruit`.`last_ip`))
    = COALESCE(INET6_ATON(CONCAT('::ffff:', `recruiter`.`last_ip`)), INET6_ATON(`recruiter`.`last_ip`))
  AND COALESCE(INET6_ATON(CONCAT('::ffff:', `recruit`.`last_ip`)), INET6_ATON(`recruit`.`last_ip`))
    NOT IN (INET6_ATON('::'), INET6_ATON('::ffff:0.0.0.0'));

DELETE `progress` FROM `raf_progress` `progress`
JOIN `raf_same_ip_recruits` `blocked` ON `blocked`.`account_id` = `progress`.`account_id`;

DELETE `registration` FROM `raf_accounts` `registration`
JOIN `raf_same_ip_recruits` `blocked` ON `blocked`.`account_id` = `registration`.`account_id`;

UPDATE `account` `recruit`
JOIN `raf_same_ip_recruits` `blocked` ON `blocked`.`account_id` = `recruit`.`id`
SET `recruit`.`recruiter` = 0;

COMMIT;

DROP TEMPORARY TABLE `raf_same_ip_recruits`;
