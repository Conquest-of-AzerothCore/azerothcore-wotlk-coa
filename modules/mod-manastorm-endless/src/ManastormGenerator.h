#ifndef MANASTORM_GENERATOR_H
#define MANASTORM_GENERATOR_H

#include "ManastormDefines.h"

#include <unordered_set>
#include <vector>

class ManastormGenerator
{
public:
    ManastormSegment const* SelectSegment(
        uint32 depth,
        uint64 runSeed,
        std::unordered_set<uint32> const&
        unlockedSegmentIds,
        bool endgame,
        uint32 excludedSegmentId = 0,
        uint32 forcedSegmentId = 0,
        std::vector<uint64> const& recentObjectiveKeys = {}) const;
};

#endif
