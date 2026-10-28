-- Authoritative shared-Manastorm reward persistence.
--
-- Reward state belongs to CHARACTER + progression MODE + TRACK.
-- mode: 1 Solo, 2 Duo, 3 Trio, 4 Group
-- track: 1 Normal, 2 Endgame
--
-- cache_chance_pct is the bad-luck-protection percentage displayed for the
-- NEXT eligible objective completion. The current reconstructed policy adds
-- 13 percentage points after a failed roll, caps at 100%, and resets to 0%
-- after a successful normal cache roll.
--
-- Currency remainders preserve exact fractional multipliers over time.
-- Example: 1 Bedlam at 150% awards 1 and carries 5000 basis points; the next
-- identical first-clear payout receives that carried half.
--
-- The *_earned columns are durable telemetry, NOT reward-rate limits.

CREATE TABLE IF NOT EXISTS character_manastorm_reward_state
(
    guid                 INT UNSIGNED NOT NULL,
    mode                 TINYINT UNSIGNED NOT NULL,
    track                TINYINT UNSIGNED NOT NULL,
    cache_chance_pct     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    bedlam_remainder_bp  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    bonzo_remainder_bp   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    caches_earned        INT UNSIGNED NOT NULL DEFAULT 0,
    bedlam_earned        BIGINT UNSIGNED NOT NULL DEFAULT 0,
    bonzo_earned         BIGINT UNSIGNED NOT NULL DEFAULT 0,
    updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (guid, mode, track),
    KEY idx_character_manastorm_reward_guid (guid),

    CONSTRAINT chk_character_manastorm_reward_mode
        CHECK (mode BETWEEN 1 AND 4),

    CONSTRAINT chk_character_manastorm_reward_track
        CHECK (track IN (1, 2)),

    CONSTRAINT chk_character_manastorm_reward_cache_pct
        CHECK (cache_chance_pct <= 100),

    CONSTRAINT chk_character_manastorm_reward_bedlam_remainder
        CHECK (bedlam_remainder_bp < 10000),

    CONSTRAINT chk_character_manastorm_reward_bonzo_remainder
        CHECK (bonzo_remainder_bp < 10000)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

SELECT
    guid,
    mode,
    track,
    cache_chance_pct,
    bedlam_remainder_bp,
    bonzo_remainder_bp,
    caches_earned,
    bedlam_earned,
    bonzo_earned
FROM character_manastorm_reward_state
ORDER BY guid, track, mode;
