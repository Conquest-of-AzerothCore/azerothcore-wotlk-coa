// mod-coa-challenges (review split): CoA.Challenges.Config.cpp
// Mechanical split of review-CoAChallenges.cpp; no logic changes.
#include "CoA.Challenges.Review.h"

namespace CoAChallenges
{

    void EnsureTables()
    {
        // Dev fallback only: the authoritative schema ships as versioned SQL
        // (data/sql/db-characters/...). Set CoAChallenges.AutoCreateSchema=1 to
        // (re)create the character tables at runtime on a dev box.
        if (!sConfigMgr->GetOption<bool>("CoAChallenges.AutoCreateSchema", false))
            return;

        // One row per active challenge (multiple groups can be active).
        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS coa_character_challenge ("
            "guid INT UNSIGNED NOT NULL, "
            "challengeId INT UNSIGNED NOT NULL, "
            "level INT UNSIGNED NOT NULL DEFAULT 1, "
            "deaths INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, challengeId)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // No IF NOT EXISTS (unsupported by this MySQL version): probe
        // INFORMATION_SCHEMA first, ALTER only when the column is missing.
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'coa_character_challenge' AND COLUMN_NAME = 'deaths'"))
        {
            CharacterDatabase.Execute(
                "ALTER TABLE coa_character_challenge ADD COLUMN "
                "deaths INT UNSIGNED NOT NULL DEFAULT 0");
        }
        // Failure history (server bookkeeping; SMSG failure records deferred).
        // PK (guid, challengeId): one failure row per challenge; the INSERT is
        // INSERT IGNORE so a repeated fail path cannot duplicate the record.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_challenge_failure ("
            "guid INT UNSIGNED NOT NULL, "
            "challengeId INT UNSIGNED NOT NULL, "
            "level INT UNSIGNED NOT NULL DEFAULT 1, "
            "deaths INT UNSIGNED NOT NULL DEFAULT 0, "
            "failTime INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, challengeId)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Migration for dev tables created before the PK existed.
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'coa_challenge_failure' AND INDEX_NAME = 'PRIMARY'"))
        {
            CharacterDatabase.Execute(
                "ALTER TABLE coa_challenge_failure ADD PRIMARY KEY (guid, challengeId)");
        }
        // Persistent per-character activation-condition flags (once broken, stays).
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_condition ("
            "guid INT UNSIGNED NOT NULL, "
            "flag VARCHAR(64) NOT NULL, "
            "PRIMARY KEY (guid, flag)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Per-character objective progress (level-restricted objectives).
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_objective ("
            "guid INT UNSIGNED NOT NULL, "
            "challengeId INT UNSIGNED NOT NULL, "
            "objective VARCHAR(96) NOT NULL, "
            "PRIMARY KEY (guid, challengeId, objective)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Completed challenges/trials (leaderboard source).
        CharacterDatabase.DirectExecute(
            "CREATE TABLE IF NOT EXISTS coa_challenge_completion ("
            "guid INT UNSIGNED NOT NULL, "
            "challengeId INT UNSIGNED NOT NULL, "
            "level INT UNSIGNED NOT NULL DEFAULT 1, "
            "completeTime INT UNSIGNED NOT NULL DEFAULT 0, "
            "startTime INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, challengeId, level)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // NOTE: no second CREATE for coa_character_challenge here (it would be
        // dead: the first CREATE above wins the IF NOT EXISTS). hunger/thirst/
        // startTime are backfilled by the ALTERs below.
        for (char const* col : { "hunger", "thirst" })
        {
            char q[256];
            snprintf(q, sizeof(q),
                "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'coa_character_challenge' AND COLUMN_NAME = '%s'", col);
            if (!CharacterDatabase.Query(q))
            {
                char alter[256];
                snprintf(alter, sizeof(alter),
                    "ALTER TABLE coa_character_challenge ADD COLUMN %s INT NOT NULL DEFAULT 100", col);
                CharacterDatabase.Execute(alter);
            }
        }
        // startTime (leaderboard duration) on both the active and completion rows.
        struct { char const* table; } startTimeTables[] = {
            { "coa_character_challenge" }, { "coa_challenge_completion" },
        };
        for (auto const& t : startTimeTables)
        {
            char q[256];
            snprintf(q, sizeof(q),
                "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = '%s' AND COLUMN_NAME = 'startTime'", t.table);
            if (!CharacterDatabase.Query(q))
            {
                char alter[256];
                snprintf(alter, sizeof(alter),
                    "ALTER TABLE %s ADD COLUMN startTime INT UNSIGNED NOT NULL DEFAULT 0", t.table);
                CharacterDatabase.DirectExecute(alter);
            }
        }
        CharacterDatabase.DirectExecute(
            "INSERT IGNORE INTO coa_account_challenge_completion "
            "(account, challengeId, level, completeTime, startTime) "
            "SELECT c.account, completion.challengeId, completion.level, completion.completeTime, completion.startTime "
            "FROM coa_challenge_completion AS completion "
            "INNER JOIN characters AS c ON c.guid = completion.guid "
            "ORDER BY completion.completeTime, completion.guid");
        // The completion PK must include `level` (multi-level challenges
        // 211/425 store one completion per level; leaderboards filter by level).
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'coa_challenge_completion' AND INDEX_NAME = 'PRIMARY' "
                "AND COLUMN_NAME = 'level'"))
        {
            CharacterDatabase.Execute(
                "ALTER TABLE coa_challenge_completion DROP PRIMARY KEY, "
                "ADD PRIMARY KEY (guid, challengeId, level)");
        }
        // Custom trials (trial creator). A trial bundles existing challenges,
        // each at a level, with an optional per-entry description.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_custom_trial ("
            "guid INT UNSIGNED NOT NULL, "
            "trialId VARCHAR(64) NOT NULL, "
            "title VARCHAR(128) NOT NULL, "
            "about VARCHAR(1024) NOT NULL, "
            "icon VARCHAR(256) NOT NULL, "
            "author VARCHAR(64) NOT NULL DEFAULT '', "
            "PRIMARY KEY (guid, trialId)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // author (creator name; trials are browsable by other characters now,
        // so the DB row must carry it) — idempotent migration for older tables.
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'coa_custom_trial' AND COLUMN_NAME = 'author'"))
        {
            CharacterDatabase.Execute(
                "ALTER TABLE coa_custom_trial ADD COLUMN author VARCHAR(64) NOT NULL DEFAULT ''");
        }
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_custom_trial_entry ("
            "guid INT UNSIGNED NOT NULL, "
            "trialId VARCHAR(64) NOT NULL, "
            "challengeId INT UNSIGNED NOT NULL, "
            "level INT UNSIGNED NOT NULL DEFAULT 1, "
            "description VARCHAR(512) NOT NULL, "
            "PRIMARY KEY (guid, trialId, challengeId, level)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Per-voter rating of a custom trial (client CMSG 0x5BF RateTrial:
        // str trialID + u8 up + u8 down). A trial's Score shown by the client
        // is (upvotes - downvotes), computed from the two vote lists the
        // 0x5AC feed carries.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_custom_trial_vote ("
            "guid INT UNSIGNED NOT NULL, "
            "trialId VARCHAR(64) NOT NULL, "
            "upvote TINYINT UNSIGNED NOT NULL DEFAULT 0, "
            "downvote TINYINT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, trialId)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // The custom trial currently active for a character. DeactivateTrial
        // (CMSG 0x5AF) has NO payload, so the server must remember which trial
        // to tear down (and push it back as SMSG 0x5B1 on login).
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_custom_trial_active ("
            "guid INT UNSIGNED NOT NULL, "
            "trialId VARCHAR(64) NOT NULL, "
            "startTime INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // startTime (leaderboard duration) on the active-trial row: idempotent
        // migration for tables created before the column existed.
        if (!CharacterDatabase.Query(
                "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'coa_custom_trial_active' AND COLUMN_NAME = 'startTime'"))
        {
            CharacterDatabase.Execute(
                "ALTER TABLE coa_custom_trial_active ADD COLUMN "
                "startTime INT UNSIGNED NOT NULL DEFAULT 0");
        }
        // Custom-trial completions (leaderboard source for CMSG 0x5C9): one row
        // per (trial, character). Re-completing a trial overwrites the row.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_custom_trial_completion ("
            "guid INT UNSIGNED NOT NULL, "
            "trialId VARCHAR(64) NOT NULL, "
            "startTime INT UNSIGNED NOT NULL DEFAULT 0, "
            "completeTime INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (trialId, guid), "
            "KEY ix_trial (trialId)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Custom game modes (Ironman/Survivalist/Draft/...): a single
        // bitmask per character, mirroring the client's [0x10BE4138] state
        // (pushed via SMSG 0x90B, Enum.GameMode bits).
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_gamemode ("
            "guid INT UNSIGNED NOT NULL, "
            "gameMode INT UNSIGNED NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Survivalist gamemode hunger/thirst (the sentinel id is never in
        // coa_character_challenge, so it needs its own row).
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_survival ("
            "guid INT UNSIGNED NOT NULL, "
            "hunger INT NOT NULL DEFAULT 0, "
            "thirst INT NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // FATIGUED_UNLESS_RESTED (Narcolepsy): per-character fatigue counter
        // (0..FatigueMax) driven by the native fatigue (mirror-timer) bar.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_fatigue ("
            "guid INT UNSIGNED NOT NULL, "
            "challengeId INT UNSIGNED NOT NULL, "
            "fatigue INT NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, challengeId)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Lives used by a game mode running WITHOUT its base challenge (the
        // counter aura stack = lives left). Separate table keeps
        // coa_character_challenge untouched.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_gamemode_lives ("
            "guid INT UNSIGNED NOT NULL, "
            "gameMode INT UNSIGNED NOT NULL, "
            "deaths INT NOT NULL DEFAULT 0, "
            "PRIMARY KEY (guid, gameMode)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // NO_NON_LOOTED_ITEMS (Scavenger): item instances the character looted
        // itself. Used to gate equip/use; the in-memory set is rebuilt at login
        // while the rule is active.
        CharacterDatabase.Execute(
            "CREATE TABLE IF NOT EXISTS coa_character_looted_item ("
            "guid INT UNSIGNED NOT NULL, "
            "itemGuid INT UNSIGNED NOT NULL, "
            "PRIMARY KEY (guid, itemGuid), "
            "KEY ix_guid (guid)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // Custom achievement ids exceed the core's SMALLINT columns
        // (max 65535), so granting one fails on save with MySQL errno 1264
        // ("Out of range value for column 'achievement'"). Widen the core
        // tracking columns once (guarded: only when still smallint).
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
                "AND TABLE_NAME = 'character_achievement' AND COLUMN_NAME = 'achievement'"))
        {
            if (r->Fetch()[0].Get<std::string>().find("smallint") != std::string::npos)
            {
                CharacterDatabase.Execute(
                    "ALTER TABLE character_achievement MODIFY achievement INT UNSIGNED NOT NULL");
                CharacterDatabase.Execute(
                    "ALTER TABLE character_achievement_progress MODIFY criteria INT UNSIGNED NOT NULL");
                LOG_INFO("module.coa_challenges",
                    "Widened character_achievement.achievement / criteria to INT UNSIGNED for custom ids");
            }
        }
    }

    void AppendClientConfig(AscensionClientConfig& config)
    {
        if (!ChallengesEnabled())
            return;

        config.Booleans.emplace_back("CONFIG_CHALLENGE_ENABLED",
            sConfigMgr->GetOption<bool>("CoAChallenges.ChallengeEnabled", true));
        config.Booleans.emplace_back("CONFIG_CHALLENGE_CREATOR_ENABLED",
            sConfigMgr->GetOption<bool>("CoAChallenges.ChallengeCreatorEnabled", true));
        // Gamemodes are server-driven (a trial turns its mode on/off, see
        // RecomputeRequiredGameModes). Lock the rows by default so players
        // cannot toggle them; `GameModes.PlayerToggle` re-enables the UI.
        if (GameModesEnabled())
        {
            bool playerToggle = sConfigMgr->GetOption<bool>(
                "CoAChallenges.GameModes.PlayerToggle", false);
            for (GameModeDef const& m : GameModes)
            {
                config.Booleans.emplace_back(m.configKey, playerToggle);
                // Presentation-only: hide modes with no server support yet
                // (CoAChallenges.GameModes.Hidden). An ACTIVE mode still shows
                // on the client regardless of this flag.
                config.Booleans.emplace_back(m.hiddenKey, GameModeHidden(m.name));
            }
        }
    }

    // Response packet shared by START (0x593) and STOP (0x595).
    // Enum.ChallengeResponse string for a start-response code. The client maps
    // the STRING (not the number) via Enum.ChallengeResponse[...], so the
    // reason must match the code.
} // namespace CoAChallenges
