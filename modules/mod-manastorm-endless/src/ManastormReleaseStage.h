#ifndef MANASTORM_RELEASE_STAGE_H
#define MANASTORM_RELEASE_STAGE_H

#include "AscensionRaidReleasePolicy.h"
#include "Define.h"

#include <array>

namespace ManastormReleaseStage
{
    constexpr uint32 AllReleased = RaidRelease::AllReleased;

    struct CacheStage
    {
        uint32 CacheItemEntry;
        uint32 Stage;
    };

    constexpr std::array<CacheStage, 21> RaidCacheStages = {{
        { 1278052, RaidRelease::StageZulGurub }, { 1278053, RaidRelease::StageZulGurub },
        { 1278055, RaidRelease::StageZulGurub },
        { 1278056, RaidRelease::StageMoltenCore }, { 1278058, RaidRelease::StageMoltenCore },
        { 1278060, RaidRelease::StageMoltenCore },
        { 1278066, RaidRelease::StageBlackwingLair }, { 1278068, RaidRelease::StageBlackwingLair },
        { 1278069, RaidRelease::StageBlackwingLair },
        { 1278070, RaidRelease::StageAhnQiraj }, { 1278072, RaidRelease::StageAhnQiraj },
        { 1278074, RaidRelease::StageAhnQiraj }, { 1278075, RaidRelease::StageAhnQiraj },
        { 1278077, RaidRelease::StageAhnQiraj }, { 1278078, RaidRelease::StageAhnQiraj },
        { 1278061, RaidRelease::StageOnyxiasLair }, { 1278063, RaidRelease::StageOnyxiasLair },
        { 1278065, RaidRelease::StageOnyxiasLair },
        { 1278079, RaidRelease::StageNaxxramas }, { 1278081, RaidRelease::StageNaxxramas },
        { 1278083, RaidRelease::StageNaxxramas }
    }};

    constexpr uint32 RequiredStage(uint32 cacheItemEntry)
    {
        if (cacheItemEntry == 1278051)
            return RaidRelease::StageHeroicDungeons;
        if (cacheItemEntry == 1278054 || cacheItemEntry == 1278059 || cacheItemEntry == 1278064 ||
            cacheItemEntry == 1278073 || cacheItemEntry == 1278082)
            return RaidRelease::StageMythicDungeons;
        for (CacheStage const& cache : RaidCacheStages)
            if (cache.CacheItemEntry == cacheItemEntry)
                return cache.Stage;
        return 0;
    }
}

#endif
