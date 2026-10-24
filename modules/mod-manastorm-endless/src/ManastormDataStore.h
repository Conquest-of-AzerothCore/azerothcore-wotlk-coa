#ifndef MANASTORM_DATA_STORE_H
#define MANASTORM_DATA_STORE_H

#include "ManastormDefines.h"
#include "CreatureData.h"

#include <map>
#include <vector>

struct ManastormHubReturn
{
    uint8 TeamId = 0;
    ObjectGuid::LowType GameObjectSpawnId = 0;
    uint32 MapId = 0;
    float PositionX = 0.0f;
    float PositionY = 0.0f;
    float PositionZ = 0.0f;
    float Orientation = 0.0f;
    float ZOffset = 1.0f;
};

class ManastormDataStore
{
public:
    static ManastormDataStore& Instance();

    bool Load();

    bool IsLoaded() const { return _loaded; }

    CreatureData const* GetPrivateCreature(ObjectGuid::LowType spawnId) const;

    ManastormSegment const* GetSegmentById(
        uint32 segmentId) const;

    ManastormUnlockDefinition const* GetUnlockById(
        uint32 unlockId) const;

    ManastormCreaturePoolDefinition const* GetCreaturePoolById(
        uint32 poolId) const;

    ManastormHubReturn const* GetHubReturn(
        uint8 teamId) const;

    ManastormAffixDefinition const* GetAffixById(
        uint32 affixId) const;

    std::map<uint32, ManastormAffixDefinition> const&
    GetAffixes() const
    {
        return _affixes;
    }

    ManastormAffixPolicy const* GetAffixPolicyForDepth(
        uint32 depth) const;

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
    ManastormScalingPoint GetScalingForDepth(uint32 depth, bool endgame = false) const;

    // Effective runtime scaling = generic depth curve x matching
    // member-count range. Missing group ranges are neutral 1.0x.
    ManastormScalingPoint GetScalingForDepth(
        uint32 depth,
        uint32 memberCount, bool endgame = false) const;

    std::size_t GetSegmentCount() const { return _segments.size(); }
    std::size_t GetScalingPointCount() const { return _scalingCurve.size(); }
    std::size_t GetGroupScalingRangeCount() const { return _groupScalingRanges.size(); }
    std::size_t GetAffixCount() const { return _affixes.size(); }
    std::size_t GetAffixPolicyCount() const { return _affixPolicies.size(); }

private:
    ManastormDataStore() = default;

    bool LoadPrivateCreatures();
    bool LoadSegments();
    bool LoadSegmentSpawns();
    bool LoadCreaturePools();
    bool LoadScalingCurve(bool endgame = false);
    bool LoadGroupScaling(bool endgame = false);
    bool LoadHubReturns();
    bool LoadAffixes();
    bool LoadAffixRankSpells();
    bool LoadAffixPolicies();
    bool LoadUnlocks();
    bool LoadUnlockTriggers();
    bool LoadUnlockGrants();

    std::map<ObjectGuid::LowType, CreatureData> _privateCreatures;
    bool _loaded = false;
    std::vector<ManastormSegment> _segments;
    std::map<uint32, ManastormScalingPoint> _scalingCurve;
    std::vector<ManastormGroupScalingRange> _groupScalingRanges;
    std::map<uint32, ManastormScalingPoint> _endgameScalingCurve;
    std::vector<ManastormGroupScalingRange> _endgameGroupScalingRanges;
    std::map<uint8, ManastormHubReturn> _hubReturns;
    std::map<uint32, ManastormCreaturePoolDefinition> _creaturePools;
    std::map<uint32, ManastormAffixDefinition> _affixes;
    std::vector<ManastormAffixPolicy> _affixPolicies;
    std::map<uint32, ManastormUnlockDefinition> _unlocks;

};

#endif
