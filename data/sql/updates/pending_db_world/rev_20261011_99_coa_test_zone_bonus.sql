-- Zones whose characters earn more experience, Runes of Descension and Bazaar Tokens,
-- to draw bug testers into the zones that need testing. Percentages of the normal award;
-- expires_at is the unix time the zone stops being a test zone, 0 for no end.
CREATE TABLE IF NOT EXISTS `coa_test_zone_bonus` (
    `zone_id` INT UNSIGNED NOT NULL,
    `experience_percent` INT UNSIGNED NOT NULL DEFAULT 200,
    `rune_percent` INT UNSIGNED NOT NULL DEFAULT 200,
    `bazaar_token_percent` INT UNSIGNED NOT NULL DEFAULT 200,
    `expires_at` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`zone_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELETE FROM `command`
WHERE `name` IN ('testzone', 'testzone list', 'testzone add', 'testzone xp', 'testzone runes',
    'testzone tokens', 'testzone duration', 'testzone remove', 'testzone reload');
INSERT INTO `command` (`name`, `security`, `help`) VALUES
('testzone', 2, 'Syntax: .testzone <list|add|xp|runes|tokens|duration|remove|reload>. Zones with more rewards.'),
('testzone list', 2, 'Syntax: .testzone list. Show every test zone and its percentages.'),
('testzone add', 2, 'Syntax: .testzone add [zoneId] [xp%] [runes%] [tokens%]. Zone 0 or none: your zone. Default 200.'),
('testzone xp', 2, 'Syntax: .testzone xp <percent> [zoneId]. Set the experience percentage. No zone id: your zone.'),
('testzone runes', 2, 'Syntax: .testzone runes <percent> [zoneId]. Set the Runes of Descension percentage.'),
('testzone tokens', 2, 'Syntax: .testzone tokens <percent> [zoneId]. Set the Bazaar Token percentage.'),
('testzone duration', 2, 'Syntax: .testzone duration <12|90m|1d12h|0> [zoneId]. Hours, or a time; 0 never ends.'),
('testzone remove', 2, 'Syntax: .testzone remove [zoneId]. Normal rewards again. No zone id: your current zone.'),
('testzone reload', 2, 'Syntax: .testzone reload. Reload the test zones after editing the table by hand.');
