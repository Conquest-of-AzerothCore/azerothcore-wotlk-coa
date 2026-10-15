-- Storage for the Personal Bank, Celestial Personal Bank and Realm Bank.
--
-- The vault frame the three items open is the client's own guild-vault window, so the
-- module answers it with guild-bank packets; the contents are kept here instead, keyed by
-- the owner of the bank rather than by a guild:
--
--   owner_kind 0  the character's own bank (owner_id = character guid)
--   owner_kind 1  the realm bank (owner_id = account id), shared by the characters of the
--                 account that owns it and by nobody else. Keying it by anything wider - zero,
--                 say - makes one drawer for the whole realm and hands one account's
--                 belongings to everyone who walks up to a summoned vault.
--
-- Items live in `item_instance` exactly as guild-bank items do (owner and container left
-- empty, saved standalone), so enchantments, gems, durability and charges all survive.
--
-- The event log keeps the same tab convention the core uses for guild banks: item events
-- are filed under their tab, money events under the money tab, which the client asks for as
-- tab index GUILD_BANK_MAX_TABS (7) and the core stores as 100.

CREATE TABLE IF NOT EXISTS `mod_ascension_bank_tab` (
  `owner_kind` TINYINT UNSIGNED NOT NULL,
  `owner_id`   BIGINT UNSIGNED  NOT NULL DEFAULT 0,
  `tab_index`  TINYINT UNSIGNED NOT NULL,
  `name`       VARCHAR(16)      NOT NULL DEFAULT '',
  `icon`       VARCHAR(100)     NOT NULL DEFAULT '',
  `text`       VARCHAR(500)     NOT NULL DEFAULT '',
  PRIMARY KEY (`owner_kind`, `owner_id`, `tab_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_ascension_bank_item` (
  `owner_kind` TINYINT UNSIGNED NOT NULL,
  `owner_id`   BIGINT UNSIGNED  NOT NULL DEFAULT 0,
  `tab_index`  TINYINT UNSIGNED NOT NULL,
  `slot`       TINYINT UNSIGNED NOT NULL,
  `item_guid`  BIGINT UNSIGNED  NOT NULL,
  PRIMARY KEY (`owner_kind`, `owner_id`, `tab_index`, `slot`),
  KEY `idx_item_guid` (`item_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_ascension_bank_money` (
  `owner_kind` TINYINT UNSIGNED NOT NULL,
  `owner_id`   BIGINT UNSIGNED  NOT NULL DEFAULT 0,
  `money`      BIGINT UNSIGNED  NOT NULL DEFAULT 0,
  PRIMARY KEY (`owner_kind`, `owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `mod_ascension_bank_log` (
  `log_id`        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `owner_kind`    TINYINT UNSIGNED NOT NULL,
  `owner_id`      BIGINT UNSIGNED  NOT NULL DEFAULT 0,
  `tab_index`     TINYINT UNSIGNED NOT NULL,
  `event_type`    TINYINT UNSIGNED NOT NULL,
  `player_guid`   BIGINT UNSIGNED  NOT NULL,
  `item_or_money` INT UNSIGNED     NOT NULL DEFAULT 0,
  `stack_count`   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `dest_tab`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `timestamp`     INT UNSIGNED     NOT NULL DEFAULT 0,
  PRIMARY KEY (`log_id`),
  KEY `idx_owner_tab` (`owner_kind`, `owner_id`, `tab_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
