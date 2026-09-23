#ifndef MANASTORM_DATA_STORE_H
#define MANASTORM_DATA_STORE_H

#include "ManastormDefines.h"

#include <map>
#include <vector>

class ManastormDataStore
{
public:
    static ManastormDataStore& Instance();

    bool Load();

    bool IsLoaded() const { return _loaded; }

    ManastormSegment const* GetSegmentById(
        uint32 segmentId) const;

    ManastormUnlockDefinition const* GetUnlockById(
        uint32 unlockId) const;

    ManastormCreaturePoolDefinition const* GetCreaturePoolById(
        uint32 poolId) const;

    ManastormUnlockDefinition const* GetUnlockForTrigger(
        uint32 completedDepth,
        ManastormMode mode,
        bool endgame) const;

    std::vector<ManastormUnlockDefinition const*>
    GetDirectUnlocksForTrigger(
        uint32 completedDepth,
        ManastormMode mode,
        bool endgame) const;

    std::size_t GetUnlockCount() const
    {
        return _unlocks.size();
    }

    std::vector<ManastormSegment> const& GetSegments() const { return _segments; }

    // Generic depth-only curve.
    ManastormScalingPoint GetScalingForDepth(uint32 depth) const;

    // Effective runtime scaling = generic depth curve x matching
    // member-count range. Missing group ranges are neutral 1.0x.
    ManastormScalingPoint GetScalingForDepth(
        uint32 depth,
        uint32 memberCount) const;

    std::size_t GetSegmentCount() const { return _segments.size(); }
    std::size_t GetScalingPointCount() const { return _scalingCurve.size(); }
    std::size_t GetGroupScalingRangeCount() const { return _groupScalingRanges.size(); }



private:
    ManastormDataStore() = default;

    bool LoadSegments();
    bool LoadSegmentSpawns();
    bool LoadCreaturePools();
    bool LoadScalingCurve();
    bool LoadGroupScaling();
    bool LoadUnlocks();
    bool LoadUnlockTriggers();
    bool LoadUnlockGrants();

    bool _loaded = false;
    std::vector<ManastormSegment> _segments;
    std::map<uint32, ManastormScalingPoint> _scalingCurve;
    std::vector<ManastormGroupScalingRange> _groupScalingRanges;
    std::map<uint32, ManastormCreaturePoolDefinition> _creaturePools;
    std::map<uint32, ManastormUnlockDefinition> _unlocks;

};

#endif
