-- The codexes a character has spent.
--
-- One row per character, written the moment a codex is used. `slots` is how many primary
-- profession slots that character has unlocked on top of MaxPrimaryTradeSkill.
--
-- Why it has to be stored anywhere: the extra allowance is carried in the player field the core
-- already keeps for free profession slots (PLAYER_CHARACTER_POINTS2, "slots still free"), and
-- Player::InitPrimaryProfessions resets that field to MaxPrimaryTradeSkill at every login, so
-- the unlock is remembered here and handed back to the counter before the client is told
-- anything. A character's first codex is what creates their row.
--
-- Apply to acore_characters. The worldserver's own updater does it at startup when
-- `Updates.EnableDatabases` covers the characters database; on a repack that runs with the
-- updater off, apply the file by hand.
CREATE TABLE IF NOT EXISTS `mod_craftsmans_codex` (
  `guid`          int unsigned NOT NULL COMMENT 'character guid',
  `slots`         int unsigned NOT NULL DEFAULT 0 COMMENT 'primary profession slots unlocked by codexes',
  `first_used_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'first codex spent',
  `last_used_at`  timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'most recent codex spent',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Craftsman''s Codex uses, per character';
