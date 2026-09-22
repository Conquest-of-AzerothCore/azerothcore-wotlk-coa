#ifndef MANASTORM_PROGRESSION_H
#define MANASTORM_PROGRESSION_H

#include "ManastormDefines.h"

#include <array>
#include <string>
#include <unordered_set>
#include <vector>

class ManastormRun;

struct ManastormProgressionSnapshot
{
    uint32 BestCompletedDepth = 0;

    uint32 PendingUnlockId = 0;
    uint32 PendingIntroSegmentId = 0;
    uint32 PendingEndgameIntroSegmentId = 0;
    uint32 PendingIntroDepth = 0;

    std::unordered_set<uint32>
        UnlockedSegmentIds;

    // Creature-content ownership is independent of exact segment ownership.
    // The replacement algorithm is intentionally not enabled yet; this set
    // preserves recovered progression state for the future server-side
    // creature randomizer.
    std::unordered_set<uint32>
        UnlockedCreaturePoolIds;

    // Permanent affix ownership is resolved from the SAME
    // character unlock -> world unlock grant chain as segments.
    //
    // No separate character affix ownership table is needed.
    std::unordered_set<uint32>
        UnlockedAffixIds;
};

using ManastormCompletedDepthLists =
    std::array<std::vector<uint32>, 8>;

struct ManastormBestCompletedDepths
{
    uint32 Solo = 0;
    uint32 Duo = 0;
    uint32 Trio = 0;
    uint32 Group = 0;
};

struct ManastormProgressionToastEvent
{
    ObjectGuid::LowType CharacterGuid = 0;
    uint32 MessageId = 0;
};

class ManastormProgression
{
public:
    static bool LoadSnapshot(
        ObjectGuid::LowType characterGuid,
        ManastormMode mode,
        bool endgame,
        ManastormProgressionSnapshot& snapshot,
        std::string& error);

    static bool LoadCompletedDepthLists(
        ObjectGuid::LowType characterGuid,
        ManastormCompletedDepthLists& depths,
        std::string& error);

    static bool LoadBestCompletedDepths(
        ObjectGuid::LowType characterGuid,
        ManastormBestCompletedDepths& depths,
        std::string& error);

    static bool RecordStageCompletion(
        ManastormRun const& run,
        std::vector<ManastormProgressionToastEvent>& toastEvents,
        std::string& error);

    //
    // Recovered Ascension checkpoint model:
    //
    // normal checkpoint starts:
    //     1, 6, 11, 16, 21, ...
    //
    // plus an exact pending progression checkpoint,
    // which must remain retryable until completed.
    //
    static void BuildEnterableDepths(
        ManastormProgressionSnapshot const& snapshot,
        std::vector<uint32>& depths);

    static bool IsDepthEnterable(
        ManastormProgressionSnapshot const& snapshot,
        uint32 depth);
};

#endif
