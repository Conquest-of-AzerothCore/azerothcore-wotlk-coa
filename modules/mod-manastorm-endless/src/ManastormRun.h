#ifndef MANASTORM_RUN_H
#define MANASTORM_RUN_H

#include "ManastormDefines.h"
#include "Position.h"

#include <unordered_set>
#include <vector>
#include <unordered_map>

class ManastormRun
{
public:
    ManastormRun(
        uint64 runId,
        uint64 seed,
        ObjectGuid::LowType ownerGuid,
        std::vector<ObjectGuid::LowType> members,
        ManastormMode mode,
        uint8 creatureLevel,
        uint32 depth,
        ManastormSegment const& segment,
        ManastormScalingPoint const& scaling);

    uint64 GetRunId() const { return _runId; }
    uint64 GetSeed() const { return _seed; }

    ObjectGuid::LowType GetOwnerGuid() const { return _ownerGuid; }
    std::vector<ObjectGuid::LowType> const& GetMembers() const { return _members; }

    ManastormMode GetMode() const { return _mode; }
    bool IsEndgame() const { return _endgame; }
    void SetEndgame(bool value) { _endgame = value; }
    void SaveReturnLocation(ObjectGuid::LowType guid, WorldLocation const& location)
    {
        _returnLocations.emplace(guid, location);
    }
    WorldLocation const* GetReturnLocation(ObjectGuid::LowType guid) const
    {
        auto itr = _returnLocations.find(guid);
        return itr == _returnLocations.end() ? nullptr : &itr->second;
    }

    ManastormRunState GetState() const { return _state; }
    void SetState(ManastormRunState state) { _state = state; }

    uint8 GetCreatureLevel() const { return _creatureLevel; }

    void SetCreatureLevel(uint8 creatureLevel)
    {
        _creatureLevel = creatureLevel;
    }

    uint32 GetDepth() const { return _depth; }
    ObjectGuid GetPortalGuid() const { return _portalGuid; }
    void SetPortalGuid(ObjectGuid guid) { _portalGuid = guid; }
    bool EntranceInitialized() const { return _entranceInitialized; }
    void SetEntranceInitialized() { _entranceInitialized = true; }
    bool StartRequested() const { return _startRequested; }
    void RequestStart() { _startRequested = true; }

    uint8 GetResurrectionCharges() const
    {
        return _resurrectionCharges;
    }

    bool HasResurrectionCharges() const
    {
        return _resurrectionCharges > 0;
    }

    bool ConsumeResurrectionCharge()
    {
        if (!_resurrectionCharges)
            return false;

        --_resurrectionCharges;
        return true;
    }

    void ResetResurrectionCharges()
    {
        _resurrectionCharges =
            ManastormResurrection::MaxCharges;
    }

    uint8 GetChaoticLinkStacks() const
    {
        return _chaoticLinkStacks;
    }

    void SetChaoticLinkStacks(uint8 stacks)
    {
        _chaoticLinkStacks = stacks;
    }

    uint32 GetChaoticLinkBaseMaxHealth() const
    {
        return _chaoticLinkBaseMaxHealth;
    }

    void SetChaoticLinkBaseMaxHealth(
        uint32 maxHealth)
    {
        _chaoticLinkBaseMaxHealth =
            maxHealth;
    }

    bool IsRouteSpawn(
        ObjectGuid::LowType spawnId) const
    {
        if (!spawnId)
            return false;

        return _routeConfiguredSpawnIds.find(
            spawnId) !=
            _routeConfiguredSpawnIds.end();
    }

    bool IsChaoticLinkSpawn(
        ObjectGuid::LowType spawnId) const
    {
        if (!spawnId)
            return false;

        return _chaoticLinkConfiguredSpawnIds.find(
            spawnId) !=
            _chaoticLinkConfiguredSpawnIds.end();
    }

    bool IsRandomizationSpawn(
        ObjectGuid::LowType spawnId) const
    {
        if (!spawnId)
            return false;

        return _randomizationConfiguredSpawnIds.find(
            spawnId) !=
            _randomizationConfiguredSpawnIds.end();
    }

    bool IsCreaturePoolSourceSpawn(
        ObjectGuid::LowType spawnId) const
    {
        if (!spawnId)
            return false;

        return _creaturePoolSourceSpawnIds.find(
            spawnId) !=
            _creaturePoolSourceSpawnIds.end();
    }

    bool ConsumeChaoticLinkSpawn(
        ObjectGuid::LowType spawnId)
    {
        if (!spawnId)
            return false;

        return _chaoticLinkUnusedSpawnIds.erase(
            spawnId) != 0;
    }

    std::size_t GetUnusedChaoticLinkSpawnCount() const
    {
        return _chaoticLinkUnusedSpawnIds.size();
    }

    ManastormSegment const& GetSegment() const { return _segment; }
    ManastormScalingPoint const& GetScaling() const { return _scaling; }

    void PrepareNextStage(
        uint8 creatureLevel,
        uint32 depth,
        ManastormSegment const& segment,
        ManastormScalingPoint const& scaling);

    uint32 GetInstanceId() const { return _instanceId; }
    void SetInstanceId(uint32 instanceId) { _instanceId = instanceId; }

    ObjectGuid GetObjectiveCreatureGuid() const
    {
        return _objectiveCreatureGuid;
    }

    void SetObjectiveCreatureGuid(ObjectGuid guid)
    {
        _objectiveCreatureGuid = guid;
    }

    void ClearObjectiveCreatureGuid()
    {
        _objectiveCreatureGuid.Clear();
    }

    bool RegisterStageCreature(ObjectGuid guid)
    {
        return _stageCreatureGuids.insert(guid).second;
    }

    void UnregisterStageCreature(ObjectGuid guid)
    {
        _stageCreatureGuids.erase(guid);
    }

    bool TryMarkTrashHeartRoll(ObjectGuid guid)
    {
        return _trashHeartRolls.insert(guid).second;
    }

    bool IsStageCreature(ObjectGuid guid) const
    {
        return _stageCreatureGuids.find(guid) !=
            _stageCreatureGuids.end();
    }

    std::size_t GetStageCreatureCount() const
    {
        return _stageCreatureGuids.size();
    }

    std::unordered_set<ObjectGuid> const& GetStageCreatureGuids() const
    {
        return _stageCreatureGuids;
    }

    bool RegisterActiveHeart(
        ObjectGuid guid,
        uint32 pickupArmDelayMs)
    {
        return _activeHeartGuids.emplace(
            guid,
            pickupArmDelayMs).second;
    }

    void UnregisterActiveHeart(ObjectGuid guid)
    {
        _activeHeartGuids.erase(guid);
    }

    std::unordered_map<ObjectGuid, uint32>& GetActiveHeartGuids()
    {
        return _activeHeartGuids;
    }

    std::unordered_map<ObjectGuid, uint32> const& GetActiveHeartGuids() const
    {
        return _activeHeartGuids;
    }

    bool HasBossHeartThreshold(uint8 thresholdPct) const
    {
        if (thresholdPct < 10 ||
            thresholdPct > 90 ||
            (thresholdPct % 10) != 0)
        {
            return false;
        }

        uint16 const bit =
            uint16(1u << ((thresholdPct / 10) - 1));

        return (_bossHeartThresholdMask & bit) != 0;
    }

    void MarkBossHeartThreshold(uint8 thresholdPct)
    {
        if (thresholdPct < 10 ||
            thresholdPct > 90 ||
            (thresholdPct % 10) != 0)
        {
            return;
        }

        uint16 const bit =
            uint16(1u << ((thresholdPct / 10) - 1));

        _bossHeartThresholdMask |= bit;
    }

    void ClearStageAffixState()
    {
        _activeStageAffixIds.clear();
        _creatureAffixIds.clear();
    }

    bool AddStageAffix(uint32 affixId)
    {
        if (!affixId)
            return false;

        return _activeStageAffixIds.insert(
            affixId).second;
    }

    bool HasStageAffix(uint32 affixId) const
    {
        return _activeStageAffixIds.find(
            affixId) !=
            _activeStageAffixIds.end();
    }

    std::unordered_set<uint32> const&
        GetActiveStageAffixIds() const
    {
        return _activeStageAffixIds;
    }

    bool AssignCreatureAffix(
        ObjectGuid guid,
        uint32 affixId)
    {
        if (guid.IsEmpty() || !affixId)
            return false;

        return _creatureAffixIds[guid]
            .insert(affixId)
            .second;
    }

    bool HasCreatureAffix(
        ObjectGuid guid,
        uint32 affixId) const
    {
        auto const itr =
            _creatureAffixIds.find(guid);

        if (itr == _creatureAffixIds.end())
            return false;

        return itr->second.find(affixId) !=
            itr->second.end();
    }

    std::unordered_set<uint32> const*
        GetCreatureAffixIds(
            ObjectGuid guid) const
    {
        auto const itr =
            _creatureAffixIds.find(guid);

        if (itr == _creatureAffixIds.end())
            return nullptr;

        return &itr->second;
    }

    void ClearCreatureAffixes(
        ObjectGuid guid)
    {
        _creatureAffixIds.erase(guid);
    }

private:
    bool _endgame = false;
    std::unordered_map<ObjectGuid::LowType, WorldLocation> _returnLocations;
    uint64 _runId = 0;
    uint64 _seed = 0;

    ObjectGuid::LowType _ownerGuid = 0;
    std::vector<ObjectGuid::LowType> _members;

    ManastormMode _mode = ManastormMode::Solo;
    ManastormRunState _state = ManastormRunState::Created;

    // Snapshot of the player-scaled creature level for the current stage.
    uint8 _creatureLevel = 1;

    uint32 _depth = 1;

    // Shared resurrection resources for the CURRENT stage.
    //
    // These reset to five whenever PrepareNextStage() builds a new depth.
    uint8 _resurrectionCharges =
        ManastormResurrection::MaxCharges;

    // Mutable runtime Chaotic Link state for the current stage.
    // Starts from ManastormSegment::ChaoticLinkStacks and decreases as
    // authored route trash is killed.
    uint8 _chaoticLinkStacks = 0;

    // Boss maximum health AFTER normal Endless depth scaling but BEFORE
    // Chaotic Link.
    //
    // Keeping this separately prevents repeated Link reductions from
    // multiplying an already Chaotic-scaled health value.
    uint32 _chaoticLinkBaseMaxHealth = 0;

    // Immutable authored persistent-spawn roles for this disposable stage.
    // Creature::GetSpawnId() resolves runtime creatures back to these IDs.
    std::unordered_set<ObjectGuid::LowType>
        _routeConfiguredSpawnIds;

    std::unordered_set<ObjectGuid::LowType>
        _chaoticLinkConfiguredSpawnIds;

    // Evidence-backed eligibility markers only. The current runtime does not
    // perform creature replacement.
    std::unordered_set<ObjectGuid::LowType>
        _randomizationConfiguredSpawnIds;

    std::unordered_set<ObjectGuid::LowType>
        _creaturePoolSourceSpawnIds;

    // Remaining authored spawns that may still consume one boss Link.
    //
    // This is deliberately separate from the configured set:
    //
    //     20 configured candidates
    //     10 starting boss Links
    //
    // means any 10 of the 20 can break the boss's Links while all
    // 20 remain identifiable as authored route creatures.
    std::unordered_set<ObjectGuid::LowType>
        _chaoticLinkUnusedSpawnIds;

    uint32 _instanceId = 0;

    ObjectGuid _portalGuid;
    bool _entranceInitialized = false;
    bool _startRequested = false;
    ObjectGuid _objectiveCreatureGuid;
    std::unordered_set<ObjectGuid> _stageCreatureGuids;
    std::unordered_set<ObjectGuid> _trashHeartRolls;

    // Affixes selected for the CURRENT disposable stage.
    std::unordered_set<uint32>
        _activeStageAffixIds;

    // Exact runtime creatures -> affixes assigned to them.
    //
    // Stage ownership and creature ownership are intentionally
    // separate because future affix density rules may assign only
    // some stage affixes to some creatures.
    std::unordered_map<
        ObjectGuid,
        std::unordered_set<uint32>>
        _creatureAffixIds;

    // Exact runtime Heart GUIDs mapped to remaining pickup arm time in ms.
    // A Heart cannot be consumed until this countdown reaches 0.
    std::unordered_map<ObjectGuid, uint32> _activeHeartGuids;

    // Bits 0..8 represent boss thresholds 10%..90%.
    uint16 _bossHeartThresholdMask = 0;

    // Snapshot the selected stage and current curve values into the run.
    // A `.manastorm reload` therefore cannot mutate an already-created stage.
    ManastormSegment _segment;
    ManastormScalingPoint _scaling;
};

#endif
