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
    ManastormScalingPoint GetScalingForDepth(uint32 depth) const;

    std::size_t GetSegmentCount() const { return _segments.size(); }
    std::size_t GetScalingPointCount() const { return _scalingCurve.size(); }



private:
    ManastormDataStore() = default;

    bool LoadSegments();
    bool LoadChaoticLinkSpawns();
    bool LoadScalingCurve();
    bool LoadUnlocks();
    bool LoadUnlockGrants();

    bool _loaded = false;
    std::vector<ManastormSegment> _segments;
    std::map<uint32, ManastormScalingPoint> _scalingCurve;
    std::map<uint32, ManastormUnlockDefinition> _unlocks;

};

#endif
