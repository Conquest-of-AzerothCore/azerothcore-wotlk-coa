#include "ManastormProgression.h"

#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Field.h"
#include "Log.h"
#include <algorithm>
#include <limits>
#include "ManastormDataStore.h"
#include "ManastormRun.h"
#include "ManastormRewards.h"
#include "ManastormExperience.h"
#include "ObjectAccessor.h"

namespace
{
constexpr char const* LOG_FILTER =
    "module.manastorm.endless";

bool EnsureCharacterProgressionTables(
    std::string& error)
{
    QueryResult progress =
        CharacterDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `character_manastorm_progress` "
            "WHERE `guid` = 0");

    if (!progress)
    {
        error =
            "character_manastorm_progress is missing "
            "or inaccessible.";

        return false;
    }

    QueryResult unlock =
        CharacterDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `character_manastorm_unlock` "
            "WHERE `guid` = 0");

    if (!unlock)
    {
        error =
            "character_manastorm_unlock is missing "
            "or inaccessible.";

        return false;
    }

    QueryResult pending =
        CharacterDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `character_manastorm_pending_unlock` "
            "WHERE `guid` = 0");

    if (!pending)
    {
        error =
            "character_manastorm_pending_unlock is "
            "missing or inaccessible.";

        return false;
    }

    QueryResult completedDepths =
        CharacterDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `character_manastorm_completed_depth` "
            "WHERE `guid` = 0");

    if (!completedDepths)
    {
        error =
            "character_manastorm_completed_depth is "
            "missing or inaccessible.";

        return false;
    }

    return true;
}

bool IsUnlockCompleted(
    ObjectGuid::LowType characterGuid,
    uint32 unlockId,
    bool& completed,
    std::string& error)
{
    completed = false;

    QueryResult result =
        CharacterDatabase.Query(
            "SELECT COUNT(*) "
            "FROM `character_manastorm_unlock` "
            "WHERE `guid` = {} "
            "AND `unlock_id` = {}",
            characterGuid,
            unlockId);

    if (!result)
    {
        error =
            "Unable to query character Manastorm "
            "unlock state.";

        return false;
    }

    completed =
        result->Fetch()[0].Get<uint64>() != 0;

    return true;
}
}

bool ManastormProgression::LoadCompletedDepthLists(
    ObjectGuid::LowType characterGuid,
    ManastormCompletedDepthLists& depths,
    std::string& error)
{
    depths =
        ManastormCompletedDepthLists{};

    error.clear();

    if (!characterGuid)
    {
        error =
            "A valid character GUID is required for "
            "Manastorm progression.";

        return false;
    }

    if (!EnsureCharacterProgressionTables(
        error))
    {
        return false;
    }

    QueryResult result =
        CharacterDatabase.Query(
            "SELECT `mode`, `track`, `depth` "
            "FROM `character_manastorm_completed_depth` "
            "WHERE `guid` = {} "
            "ORDER BY `track`, `mode`, `depth`",
            characterGuid);

    if (!result)
        return true;

    do
    {
        Field* fields =
            result->Fetch();

        uint8 const mode =
            fields[0].Get<uint8>();

        uint8 const track =
            fields[1].Get<uint8>();

        uint32 const depth =
            fields[2].Get<uint32>();

        if (mode < 1 ||
            mode > 4 ||
            (track !=
                ManastormTrackBits::Normal &&
             track !=
                ManastormTrackBits::Endgame) ||
            !depth)
        {
            LOG_WARN(
                LOG_FILTER,
                "Ignoring invalid persisted Manastorm completed depth: "
                "guid={} mode={} track={} depth={}.",
                characterGuid,
                uint32(mode),
                uint32(track),
                depth);

            continue;
        }

        std::size_t const index =
            std::size_t(mode - 1) +
            (track ==
                ManastormTrackBits::Endgame
                ? 4u
                : 0u);

        depths[index].push_back(
            depth);
    } while (result->NextRow());

    return true;
}

bool ManastormProgression::LoadBestCompletedDepths(
    ObjectGuid::LowType characterGuid,
    ManastormBestCompletedDepths& depths,
    std::string& error)
{
    depths =
        ManastormBestCompletedDepths{};

    error.clear();

    if (!characterGuid)
    {
        error =
            "A valid character GUID is required for "
            "Manastorm progression.";

        return false;
    }

    if (!EnsureCharacterProgressionTables(
        error))
    {
        return false;
    }

    //
    // One query returns all four Ascension-style
    // personal best records.
    //
    // Missing modes naturally resolve to zero.
    //
    QueryResult result =
        CharacterDatabase.Query(
            "SELECT "
            "COALESCE(MAX(CASE WHEN `mode` = 1 "
            "THEN `best_completed_depth` END), 0), "
            "COALESCE(MAX(CASE WHEN `mode` = 2 "
            "THEN `best_completed_depth` END), 0), "
            "COALESCE(MAX(CASE WHEN `mode` = 3 "
            "THEN `best_completed_depth` END), 0), "
            "COALESCE(MAX(CASE WHEN `mode` = 4 "
            "THEN `best_completed_depth` END), 0) "
            "FROM `character_manastorm_progress` "
            "WHERE `guid` = {}",
            characterGuid);

    if (!result)
    {
        error =
            "Unable to query Manastorm best "
            "completed depths.";

        return false;
    }

    Field* fields =
        result->Fetch();

    depths.Solo =
        fields[0].Get<uint32>();

    depths.Duo =
        fields[1].Get<uint32>();

    depths.Trio =
        fields[2].Get<uint32>();

    depths.Group =
        fields[3].Get<uint32>();

    return true;
}

bool ManastormProgression::LoadSnapshot(
    ObjectGuid::LowType characterGuid,
    ManastormMode mode,
    bool endgame,
    ManastormProgressionSnapshot& snapshot,
    std::string& error)
{
    snapshot =
        ManastormProgressionSnapshot{};

    error.clear();

    if (!characterGuid)
    {
        error =
            "A valid character GUID is required for "
            "Manastorm progression.";

        return false;
    }

    if (!EnsureCharacterProgressionTables(
        error))
    {
        return false;
    }

    uint8 const trackBit =
        ManastormGetTrackBit(
            endgame);

    QueryResult progress =
        CharacterDatabase.Query(
            "SELECT `best_completed_depth` "
            "FROM `character_manastorm_progress` "
            "WHERE `guid` = {} "
            "AND `mode` = {} "
            "AND `track` = {} "
            "LIMIT 1",
            characterGuid,
            uint32(uint8(mode)),
            uint32(trackBit));

    if (progress)
    {
        snapshot.BestCompletedDepth =
            progress->Fetch()[0].Get<uint32>();
    }

    QueryResult ownedUnlocks =
        CharacterDatabase.Query(
            "SELECT `unlock_id` "
            "FROM `character_manastorm_unlock` "
            "WHERE `guid` = {} "
            "ORDER BY `unlock_id`",
            characterGuid);

    if (ownedUnlocks)
    {
        do
        {
            uint32 const unlockId =
                ownedUnlocks->Fetch()[0]
                    .Get<uint32>();

            ManastormUnlockDefinition const* unlock =
                ManastormDataStore::Instance()
                    .GetUnlockById(unlockId);

            if (!unlock)
            {
                LOG_WARN(
                    LOG_FILTER,
                    "Character {} owns Manastorm "
                    "unlock {}, but the world datastore "
                    "does not currently contain it.",
                    characterGuid,
                    unlockId);

                continue;
            }

            for (ManastormUnlockGrant const& grant :
                unlock->Grants)
            {
                switch (grant.Type)
                {
                case ManastormUnlockGrantType::Segment:
                    snapshot.UnlockedSegmentIds.insert(
                        grant.ContentId);
                    break;

                case ManastormUnlockGrantType::Affix:
                    snapshot.UnlockedAffixIds.insert(
                        grant.ContentId);
                    break;

                case ManastormUnlockGrantType::CreaturePool:
                    snapshot.UnlockedCreaturePoolIds.insert(
                        grant.ContentId);
                    break;

                case ManastormUnlockGrantType::BossPool:
                    // Reserved legacy/reconstruction grant type.
                    // Recovered objective progression uses Segment grants.
                    break;
                }
            }
        }
        while (ownedUnlocks->NextRow());
    }

    QueryResult pending =
        CharacterDatabase.Query(
            "SELECT `unlock_id` "
            "FROM `character_manastorm_pending_unlock` "
            "WHERE `guid` = {} "
            "AND `mode` = {} "
            "AND `track` = {} "
            "LIMIT 1",
            characterGuid,
            uint32(uint8(mode)),
            uint32(trackBit));

    if (pending)
    {
        uint32 const unlockId =
            pending->Fetch()[0].Get<uint32>();

        ManastormUnlockDefinition const* unlock =
            ManastormDataStore::Instance()
                .GetUnlockById(unlockId);

        if (!unlock)
        {
            error =
                "Character has a pending Manastorm "
                "unlock that no longer exists in the "
                "world datastore.";

            return false;
        }

        uint8 const modeBit =
            ManastormGetModeBit(mode);

        if (!(unlock->ModeMask &
            modeBit))
        {
            error =
                "Pending Manastorm unlock is invalid "
                "for the current run mode.";

            return false;
        }

        snapshot.PendingUnlockId =
            unlockId;

        snapshot.PendingIntroSegmentId =
            unlock->IntroSegmentId;

        snapshot.PendingEndgameIntroSegmentId =
            unlock->EndgameIntroSegmentId;

        uint32 const triggerDepth =
            unlock->GetTriggerDepthForTrack(
                trackBit);

        if (!triggerDepth ||
            triggerDepth ==
                std::numeric_limits<uint32>::max())
        {
            error =
                "Pending Manastorm unlock has no valid "
                "trigger for the current native track.";

            return false;
        }

        snapshot.PendingIntroDepth =
            triggerDepth + 1;
    }

    return true;
}

bool ManastormProgression::RecordStageCompletion(
    ManastormRun const& run,
    std::vector<ManastormProgressionToastEvent>& toastEvents,
    std::string& error)
{
    toastEvents.clear();
    error.clear();

    if (!EnsureCharacterProgressionTables(
        error))
    {
        return false;
    }

    uint8 const trackBit =
        ManastormGetTrackBit(
            run.IsEndgame());

    ManastormUnlockDefinition const*
        triggeredUnlock =
            ManastormDataStore::Instance()
                .GetUnlockForTrigger(
                    run.GetDepth(),
                    run.GetMode(),
                    run.IsEndgame());

    std::vector<ManastormUnlockDefinition const*> const
        directUnlocks =
            ManastormDataStore::Instance()
                .GetDirectUnlocksForTrigger(
                    run.GetDepth(),
                    run.GetMode(),
                    run.IsEndgame());

    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();

    // Rewards and progression are one durable stage-completion unit.
    //
    // ManastormRewards appends currency/cache/pity state and the durable
    // reward mail/items to THIS SAME character transaction. Nothing is
    // published to the online player until the whole transaction commits.
    std::vector<std::shared_ptr<ManastormRewardPublication>>
        rewardPublications;

    if (!ManastormRewards::Instance()
        .PrepareStageCompletion(
            run,
            transaction,
            rewardPublications,
            error))
    {
        return false;
    }

    if (!ManastormExperience::Instance().PrepareCompletion(run, transaction, error))
        return false;

    for (ObjectGuid::LowType characterGuid :
        run.GetMembers())
    {
        uint32 pendingUnlockId = 0;

        QueryResult pending =
            CharacterDatabase.Query(
                "SELECT `unlock_id` "
                "FROM `character_manastorm_pending_unlock` "
                "WHERE `guid` = {} "
                "AND `mode` = {} "
                "AND `track` = {} "
                "LIMIT 1",
                characterGuid,
                uint32(uint8(run.GetMode())),
                uint32(trackBit));

        if (pending)
        {
            pendingUnlockId =
                pending->Fetch()[0]
                    .Get<uint32>();
        }

        uint32 completedUnlockId = 0;
        uint32 completionMessageId = 0;

        if (pendingUnlockId)
        {
            ManastormUnlockDefinition const*
                pendingUnlock =
                    ManastormDataStore::Instance()
                        .GetUnlockById(
                            pendingUnlockId);

            if (!pendingUnlock)
            {
                error =
                    "Pending character Manastorm unlock "
                    "does not exist in the world datastore.";

                return false;
            }

            uint32 const pendingIntroSegmentId =
                run.IsEndgame()
                ? pendingUnlock->EndgameIntroSegmentId
                : pendingUnlock->IntroSegmentId;

            if (pendingIntroSegmentId &&
                pendingIntroSegmentId ==
                    run.GetSegment().SegmentId)
            {
                completedUnlockId =
                    pendingUnlockId;

                completionMessageId =
                    pendingUnlock->CompletionMessageId;
            }
        }

        std::vector<uint32> directUnlockMessageIds;
        uint32 directUnlockCount = 0;

        for (ManastormUnlockDefinition const* directUnlock :
            directUnlocks)
        {
            if (!directUnlock)
                continue;

            bool alreadyCompleted = false;

            if (!IsUnlockCompleted(
                characterGuid,
                directUnlock->UnlockId,
                alreadyCompleted,
                error))
            {
                return false;
            }

            if (alreadyCompleted)
                continue;

            transaction->Append(
                "INSERT IGNORE INTO "
                "`character_manastorm_unlock` "
                "(`guid`, `unlock_id`) "
                "VALUES ({}, {})",
                characterGuid,
                directUnlock->UnlockId);

            ++directUnlockCount;

            if (directUnlock->CompletionMessageId)
            {
                directUnlockMessageIds.push_back(
                    directUnlock->CompletionMessageId);
            }
        }

        bool queueTriggeredUnlock = false;

        if (triggeredUnlock &&
            triggeredUnlock->UnlockId !=
                completedUnlockId)
        {
            bool alreadyCompleted = false;

            if (!IsUnlockCompleted(
                characterGuid,
                triggeredUnlock->UnlockId,
                alreadyCompleted,
                error))
            {
                return false;
            }

            // Only one pending NEXT-RUN introduction
            // is allowed for each character/mode.
            //
            // If the current stage completed the old
            // pending introduction, its row will be
            // deleted in this same transaction, allowing
            // the new trigger to take its place.
            if (!alreadyCompleted &&
                (!pendingUnlockId ||
                 completedUnlockId))
            {
                queueTriggeredUnlock = true;
            }
        }

        uint32 const introMessageId =
            queueTriggeredUnlock &&
            triggeredUnlock
            ? triggeredUnlock->IntroMessageId
            : 0;

        if (completedUnlockId)
        {
            transaction->Append(
                "INSERT IGNORE INTO "
                "`character_manastorm_unlock` "
                "(`guid`, `unlock_id`) "
                "VALUES ({}, {})",
                characterGuid,
                completedUnlockId);

            transaction->Append(
                "DELETE FROM "
                "`character_manastorm_pending_unlock` "
                "WHERE `guid` = {} "
                "AND `mode` = {} "
                "AND `track` = {} "
                "AND `unlock_id` = {}",
                characterGuid,
                uint32(uint8(run.GetMode())),
                uint32(trackBit),
                completedUnlockId);
        }

        transaction->Append(
            "INSERT INTO "
            "`character_manastorm_progress` "
            "(`guid`, `mode`, `track`, `best_completed_depth`) "
            "VALUES ({}, {}, {}, {}) "
            "ON DUPLICATE KEY UPDATE "
            "`best_completed_depth` = "
            "GREATEST("
            "`best_completed_depth`, "
            "VALUES(`best_completed_depth`)), "
            "`updated_at` = CURRENT_TIMESTAMP",
            characterGuid,
            uint32(uint8(run.GetMode())),
            uint32(trackBit),
            run.GetDepth());

        transaction->Append(
            "INSERT IGNORE INTO "
            "`character_manastorm_completed_depth` "
            "(`guid`, `mode`, `track`, `depth`) "
            "VALUES ({}, {}, {}, {})",
            characterGuid,
            uint32(uint8(run.GetMode())),
            uint32(trackBit),
            run.GetDepth());

        if (queueTriggeredUnlock)
        {
            transaction->Append(
                "INSERT IGNORE INTO "
                "`character_manastorm_pending_unlock` "
                "(`guid`, `mode`, `track`, `unlock_id`) "
                "VALUES ({}, {}, {}, {})",
                characterGuid,
                uint32(uint8(run.GetMode())),
                uint32(trackBit),
                triggeredUnlock->UnlockId);
        }

        //
// Presentation events are emitted only for progression
// changes that actually happened.
//
// Completion comes FIRST.
//
// This intentionally allows one boss kill to produce:
//
//   permanent old unlock
//   +
//   NEXT new unlock
//
// as two separate stacked Manastorm toasts.
//
        if (completionMessageId)
        {
            ManastormProgressionToastEvent event;

            event.CharacterGuid =
                characterGuid;

            event.MessageId =
                completionMessageId;

            toastEvents.push_back(
                event);
        }

        for (uint32 directMessageId :
            directUnlockMessageIds)
        {
            ManastormProgressionToastEvent event;

            event.CharacterGuid =
                characterGuid;

            event.MessageId =
                directMessageId;

            toastEvents.push_back(
                event);
        }

        if (introMessageId)
        {
            ManastormProgressionToastEvent event;

            event.CharacterGuid =
                characterGuid;

            event.MessageId =
                introMessageId;

            toastEvents.push_back(
                event);
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm progression: character={} "
            "mode={} completedDepth={} segment={} "
            "completedUnlock={} directUnlocks={} queuedUnlock={}.",
            characterGuid,
            ManastormModeName(run.GetMode()),
            run.GetDepth(),
            run.GetSegment().SegmentId,
            completedUnlockId,
            directUnlockCount,
            queueTriggeredUnlock
                ? triggeredUnlock->UnlockId
                : 0);
    }

    if (!CharacterDatabase.AsyncCommitTransaction(transaction).m_future.get())
    {
        toastEvents.clear();
        rewardPublications.clear();
        error =
            "Unable to commit shared Manastorm progression and rewards.";
        return false;
    }

    ManastormRewards::Instance()
        .PublishCommitted(
            rewardPublications);

    for (ObjectGuid::LowType guid : run.GetMembers())
        ManastormExperience::Instance().Settle(
            ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)));

    return true;
}

void ManastormProgression::BuildEnterableDepths(
    ManastormProgressionSnapshot const& snapshot,
    std::vector<uint32>& depths)
{
    depths.clear();

    //
    // Recovered classic Ascension checkpoint model:
    //
    //     1, 6, 11, 16, 21, ...
    //
    // Completing the five levels beginning at one
    // checkpoint unlocks the next checkpoint.
    //
    // Examples:
    //
    // best 0..4   -> 1
    // best 5..9   -> 6, 1
    // best 10..14 -> 11, 6, 1
    //
    uint64 const highestNormalCheckpoint =
        1ULL +
        (uint64(snapshot.BestCompletedDepth / 5) *
            5ULL);

    for (uint64 checkpoint = 1;
        checkpoint <= highestNormalCheckpoint;
        checkpoint += 5ULL)
    {
        if (checkpoint >
            std::numeric_limits<uint32>::max())
        {
            break;
        }

        depths.push_back(
            uint32(checkpoint));
    }

    //
    // Chapter-2-style fixed progression checkpoint.
    //
    // A pending introduction can be retried at its
    // exact level even when that level is asymmetric
    // and therefore not one of 1,6,11,16,...
    //
    if (snapshot.PendingIntroDepth)
    {
        depths.push_back(
            snapshot.PendingIntroDepth);
    }

    //
    // Ascension's GetEnterableLevels() presents the
    // highest/default entry first.
    //
    std::sort(
        depths.begin(),
        depths.end(),
        std::greater<uint32>());

    depths.erase(
        std::unique(
            depths.begin(),
            depths.end()),
        depths.end());
}

bool ManastormProgression::IsDepthEnterable(
    ManastormProgressionSnapshot const& snapshot,
    uint32 depth)
{
    if (!depth)
        return false;

    return depth == snapshot.PendingIntroDepth
        || ((depth - 1) % 5 == 0 && depth - 1 <= snapshot.BestCompletedDepth);
}
