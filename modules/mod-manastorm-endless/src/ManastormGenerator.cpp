#include "ManastormGenerator.h"

#include "Log.h"
#include "ManastormDataStore.h"

#include <limits>
#include <random>
#include <vector>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless";

    constexpr uint64 DEPTH_SEED_MIX =
        0x9E3779B97F4A7C15ULL;
}

ManastormSegment const*
ManastormGenerator::SelectSegment(
    uint32 depth,
    uint64 runSeed,
    std::unordered_set<uint32> const&
    unlockedSegmentIds,
    bool endgame,
    uint32 excludedSegmentId,
    uint32 forcedSegmentId,
    std::vector<uint64> const& recentObjectiveKeys) const
{
    if (!depth)
        return nullptr;

    //
    // NEXT-RUN progression introduction.
    //
    // This deliberately bypasses permanent-unlock
    // filtering and immediate-repeat filtering.
    //
    if (forcedSegmentId)
    {
        ManastormSegment const* forced =
            ManastormDataStore::Instance()
            .GetSegmentById(
                forcedSegmentId);

        if (!forced)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm progression attempted to "
                "force unknown segment {} at depth {}.",
                forcedSegmentId,
                depth);

            return nullptr;
        }

        uint8 const expectedDifficulty =
            endgame ? uint8(2) : uint8(0);

        if (forced->Difficulty != expectedDifficulty)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm progression attempted to force segment {} "
                "with difficulty {} into a {} run (expected difficulty {}).",
                forcedSegmentId,
                uint32(forced->Difficulty),
                endgame ? "end-game" : "normal",
                uint32(expectedDifficulty));

            return nullptr;
        }

        if (depth < forced->MinDepth ||
            (forced->MaxDepth &&
                depth > forced->MaxDepth))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Manastorm forced segment {} is not "
                "depth-eligible at depth {} "
                "(configured {}..{}).",
                forcedSegmentId,
                depth,
                forced->MinDepth,
                forced->MaxDepth);

            return nullptr;
        }

        LOG_INFO(
            LOG_FILTER,
            "Manastorm progression forcing NEXT-RUN "
            "segment {} at depth {}.",
            forcedSegmentId,
            depth);

        return forced;
    }

    std::vector<ManastormSegment const*>
        candidates;

    uint64 totalWeight = 0;

    uint8 const expectedDifficulty =
        endgame ? uint8(2) : uint8(0);

    //
    // Recent-objective protection is intentionally softer than eligibility.
    //
    // History is stored oldest -> newest. First try excluding the full
    // window, then relax the oldest objective one at a time. This keeps
    // alternate routes to the same boss from appearing as repetitive stages
    // without ever dead-ending an Endless run when the accessible pool is
    // small.
    //
    std::size_t protectedObjectiveCount =
        recentObjectiveKeys.size();

    bool allowExactSegmentRepeat =
        false;

    while (true)
    {
        candidates.clear();
        totalWeight = 0;

        std::size_t const protectedStart =
            recentObjectiveKeys.size() -
            protectedObjectiveCount;

        for (ManastormSegment const& segment :
            ManastormDataStore::Instance()
            .GetSegments())
        {
            if (!allowExactSegmentRepeat &&
                excludedSegmentId &&
                segment.SegmentId ==
                excludedSegmentId)
            {
                continue;
            }

            //
            // Patch-M/native Manastorm has two distinct stage tracks:
            //
            //   difficulty 0 = normal
            //   difficulty 2 = end-game
            //
            // Never allow the generator to cross-select between them.
            //
            if (segment.Difficulty !=
                expectedDifficulty)
            {
                continue;
            }

            if (depth < segment.MinDepth)
                continue;

            if (segment.MaxDepth &&
                depth > segment.MaxDepth)
            {
                continue;
            }

            if (!segment.Weight)
                continue;

            bool const startingUnlocked =
                (segment.Flags &
                    ManastormSegmentFlags::StartingUnlocked) != 0;

            bool const progressionUnlocked =
                unlockedSegmentIds.find(
                    segment.SegmentId) !=
                unlockedSegmentIds.end();

            if (!startingUnlocked &&
                !progressionUnlocked)
            {
                continue;
            }

            uint64 const objectiveKey =
                MakeManastormObjectiveKey(
                    segment);

            bool recentObjective =
                false;

            for (std::size_t index =
                    protectedStart;
                index <
                    recentObjectiveKeys.size();
                ++index)
            {
                if (recentObjectiveKeys[index] ==
                    objectiveKey)
                {
                    recentObjective = true;
                    break;
                }
            }

            if (recentObjective)
                continue;

            if (std::numeric_limits<uint64>::max() -
                totalWeight <
                segment.Weight)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Manastorm candidate weight overflow "
                    "while selecting depth {}.",
                    depth);

                return nullptr;
            }

            candidates.push_back(
                &segment);

            totalWeight +=
                segment.Weight;
        }

        if (!candidates.empty() &&
            totalWeight)
        {
            break;
        }

        if (protectedObjectiveCount)
        {
            --protectedObjectiveCount;
            continue;
        }

        //
        // Preserve the previous exact-segment fallback as the final safety
        // net. If the exact previous segment is literally the only accessible
        // segment, repeat it rather than terminating the run.
        //
        if (!allowExactSegmentRepeat &&
            excludedSegmentId)
        {
            allowExactSegmentRepeat =
                true;
            continue;
        }

        return nullptr;
    }

    uint64 const mixedSeed =
        runSeed ^
        (DEPTH_SEED_MIX *
            (uint64(depth) + 1ULL));

    std::mt19937_64 rng(
        mixedSeed);

    std::uniform_int_distribution<uint64>
        distribution(
            1,
            totalWeight);

    uint64 roll =
        distribution(rng);

    for (ManastormSegment const* segment :
        candidates)
    {
        if (roll <= segment->Weight)
            return segment;

        roll -=
            segment->Weight;
    }

    return candidates.back();
}
