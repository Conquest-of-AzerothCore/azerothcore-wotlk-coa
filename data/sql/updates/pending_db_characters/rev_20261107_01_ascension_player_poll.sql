CREATE TABLE IF NOT EXISTS `coa_player_poll` (
    `id` INT UNSIGNED NOT NULL,
    `question_type` INT UNSIGNED NOT NULL,
    `allow_change` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `min_level` TINYINT UNSIGNED NOT NULL DEFAULT 10,
    `state` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `expires_at` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `published_at` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `closed_at` BIGINT UNSIGNED NOT NULL DEFAULT 0,
    `title` VARCHAR(256) NOT NULL,
    `question_text` TEXT NOT NULL,
    `feedback_prompt` VARCHAR(512) NOT NULL DEFAULT '',
    `context_text` TEXT NOT NULL,
    `wire_04` INT UNSIGNED NULL,
    `wire_50` INT UNSIGNED NULL,
    `wire_54` INT UNSIGNED NULL,
    `wire_a8` INT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    KEY `idx_poll_publication` (`state`, `expires_at`),
    CONSTRAINT `chk_poll_type` CHECK (`question_type` BETWEEN 1 AND 4),
    CONSTRAINT `chk_poll_state` CHECK (`state` BETWEEN 0 AND 2),
    CONSTRAINT `chk_poll_change` CHECK (`allow_change` <= 1),
    CONSTRAINT `chk_poll_level` CHECK (`min_level` >= 10),
    CONSTRAINT `chk_poll_title_bytes` CHECK (OCTET_LENGTH(`title`) BETWEEN 1 AND 256),
    CONSTRAINT `chk_poll_text_bytes` CHECK (OCTET_LENGTH(`question_text`) BETWEEN 1 AND 2048),
    CONSTRAINT `chk_poll_prompt_bytes` CHECK (OCTET_LENGTH(`feedback_prompt`) <= 512),
    CONSTRAINT `chk_poll_context_bytes` CHECK (OCTET_LENGTH(`context_text`) <= 1024)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `coa_player_poll_choice` (
    `question_id` INT UNSIGNED NOT NULL,
    `id` INT UNSIGNED NOT NULL,
    `choice_text` VARCHAR(256) NOT NULL,
    PRIMARY KEY (`question_id`, `id`),
    CONSTRAINT `fk_poll_choice_question` FOREIGN KEY (`question_id`) REFERENCES `coa_player_poll` (`id`),
    CONSTRAINT `chk_poll_choice_id` CHECK (`id` > 0),
    CONSTRAINT `chk_poll_choice_bytes` CHECK (OCTET_LENGTH(`choice_text`) BETWEEN 1 AND 256)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE IF NOT EXISTS `coa_player_poll_vote` (
    `question_id` INT UNSIGNED NOT NULL,
    `account_id` INT UNSIGNED NOT NULL,
    `character_guid` INT UNSIGNED NOT NULL,
    `choice_id` INT UNSIGNED NULL,
    `feedback` TEXT NOT NULL,
    `can_change` TINYINT UNSIGNED NOT NULL,
    `request_token` BIGINT UNSIGNED NOT NULL,
    `submitted_at` BIGINT UNSIGNED NOT NULL,
    `updated_at` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`question_id`, `account_id`),
    KEY `idx_poll_account` (`account_id`),
    CONSTRAINT `fk_poll_vote_question` FOREIGN KEY (`question_id`) REFERENCES `coa_player_poll` (`id`),
    CONSTRAINT `fk_poll_vote_choice` FOREIGN KEY (`question_id`, `choice_id`)
        REFERENCES `coa_player_poll_choice` (`question_id`, `id`),
    CONSTRAINT `chk_poll_feedback_bytes` CHECK (OCTET_LENGTH(`feedback`) <= 2048),
    CONSTRAINT `chk_poll_vote_change` CHECK (`can_change` <= 1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
