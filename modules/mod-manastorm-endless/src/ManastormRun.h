#ifndef MANASTORM_RUN_H
#define MANASTORM_RUN_H

#include "ManastormDefines.h"
#include "Position.h"

#include <array>
#include <limits>
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

    struct CompanionTransfer
    {
        uint32 Entry = 0;
        uint32 Spell = 0;
        uint32 Properties = 0;
        uint32 RemainingMs = 0;
        uint32 CapturedMs = 0;
        uint32 SummonType = 0;
        float HealthPct = 100.0f;
        uint32 Power = 0;
        uint8 ReactState = 0;
        bool TemporaryPet = false;
    };

    std::unordered_map<ObjectGuid::LowType, std::vector<CompanionTransfer>> CompanionTransfers;

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
    bool MarkStageCooldownsReset(ObjectGuid::LowType guid)
    {
        auto const previous = _cooldownResetDepths.find(guid);
        if (previous != _cooldownResetDepths.end() && previous->second == _depth)
            return false;

        _cooldownResetDepths[guid] = _depth;
        return true;
    }
    ObjectGuid GetPortalGuid() const { return _portalGuid; }
    void SetPortalGuid(ObjectGuid guid) { _portalGuid = guid; }
    bool EntranceInitialized() const { return _entranceInitialized; }
    void SetEntranceInitialized() { _entranceInitialized = true; }
    bool StartRequested() const { return _startRequested; }
    void RequestStart() { _startRequested = true; }

    bool CanStartWithMissingMembers() const
    {
        return _canStartWithMissingMembers;
    }

    void AllowStartWithMissingMembers()
    {
        _canStartWithMissingMembers = true;
    }

    static constexpr uint32
        PreparationProtectionMs = 120000;

    uint32 GetPreparationProtectionRemainingMs() const
    {
        return _preparationProtectionRemainingMs;
    }

    bool UpdatePreparationProtection(uint32 diff)
    {
        if (!_preparationProtectionRemainingMs)
            return true;

        if (diff >=
            _preparationProtectionRemainingMs)
        {
            _preparationProtectionRemainingMs = 0;
            _canStartWithMissingMembers = true;
            _startRequested = true;
            return true;
        }

        _preparationProtectionRemainingMs -=
            diff;

        return false;
    }

    void ResetPreparationProtection()
    {
        _preparationProtectionRemainingMs =
            PreparationProtectionMs;

        _canStartWithMissingMembers = false;
    }

    static constexpr std::size_t GadgetSlotCount = 4;
    using GadgetSlots = std::array<uint32, GadgetSlotCount>;

    void SetMemberGadgetLoadout(
        ObjectGuid::LowType guid,
        GadgetSlots const& slots)
    {
        _memberGadgetLoadouts[guid] = slots;
    }

    bool IsGadgetEquipped(
        ObjectGuid::LowType guid,
        uint32 spellId) const
    {
        auto const itr =
            _memberGadgetLoadouts.find(guid);

        if (itr == _memberGadgetLoadouts.end())
            return false;

        for (uint32 slotSpell :
            itr->second)
        {
            if (slotSpell == spellId)
                return true;
        }

        return false;
    }

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

    bool IsAffixEligibleSpawn(
        ObjectGuid::LowType spawnId) const
    {
        if (!spawnId)
            return false;

        return _affixEligibleConfiguredSpawnIds.find(
            spawnId) !=
            _affixEligibleConfiguredSpawnIds.end();
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

    static constexpr std::size_t RecentObjectiveHistoryLimit = 3;

    std::vector<uint64> const& GetRecentObjectiveKeys() const
    {
        return _recentObjectiveKeys;
    }

    void BeginPreviousStageTransition()
    {
        _previousSegment = _segment;
        _previousInstanceId = _instanceId;
        _previousPortalGuid = _portalGuid;
        _pendingStageTransferMembers.clear();

        for (ObjectGuid::LowType guid :
            _members)
        {
            _pendingStageTransferMembers.insert(guid);
        }

        _hasPreviousStage = true;
    }

    bool HasPreviousStage() const
    {
        return _hasPreviousStage;
    }

    ManastormSegment const& GetPreviousSegment() const
    {
        return _previousSegment;
    }

    uint32 GetPreviousInstanceId() const
    {
        return _previousInstanceId;
    }

    ObjectGuid GetPreviousPortalGuid() const
    {
        return _previousPortalGuid;
    }

    bool IsPendingStageTransfer(
        ObjectGuid::LowType guid) const
    {
        return _pendingStageTransferMembers.find(guid) !=
            _pendingStageTransferMembers.end();
    }

    void MarkStageTransferComplete(
        ObjectGuid::LowType guid)
    {
        _pendingStageTransferMembers.erase(guid);
    }

    std::unordered_set<ObjectGuid::LowType> const&
        GetPendingStageTransferMembers() const
    {
        return _pendingStageTransferMembers;
    }

    bool HasPendingStageTransfers() const
    {
        return !_pendingStageTransferMembers.empty();
    }

    void ClearPreviousStageTransition()
    {
        _hasPreviousStage = false;
        _previousInstanceId = 0;
        _previousPortalGuid.Clear();
        _pendingStageTransferMembers.clear();
    }

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

    uint32 IncrementTreasureTrashKills()
    {
        if (_treasureTrashKills !=
            std::numeric_limits<uint32>::max())
        {
            ++_treasureTrashKills;
        }

        return _treasureTrashKills;
    }

    uint32 GetTreasureTrashKills() const
    {
        return _treasureTrashKills;
    }

    bool TreasureKeeperSpawned() const
    {
        return _treasureKeeperSpawned;
    }

    void SetTreasureKeeperSpawned(bool value)
    {
        _treasureKeeperSpawned = value;
    }

    ObjectGuid GetTreasureKeeperGuid() const
    {
        return _treasureKeeperGuid;
    }

    void SetTreasureKeeperGuid(ObjectGuid guid)
    {
        _treasureKeeperGuid = guid;
    }

    void ClearTreasureKeeperGuid()
    {
        _treasureKeeperGuid.Clear();
    }

    bool GreedyDemonRolled() const
    {
        return _greedyDemonRolled;
    }

    void SetGreedyDemonRolled(bool value)
    {
        _greedyDemonRolled = value;
    }

    ObjectGuid GetGreedyDemonGuid() const
    {
        return _greedyDemonGuid;
    }

    void SetGreedyDemonGuid(ObjectGuid guid)
    {
        _greedyDemonGuid = guid;
    }

    void ClearGreedyDemonGuid()
    {
        _greedyDemonGuid.Clear();
    }

    uint32 GetBonusCacheCount() const
    {
        return _bonusCacheCount;
    }

    void AddBonusCaches(uint32 count)
    {
        uint64 const value =
            uint64(_bonusCacheCount) +
            uint64(count);

        _bonusCacheCount =
            value >
                std::numeric_limits<uint32>::max()
            ? std::numeric_limits<uint32>::max()
            : uint32(value);
    }

    uint32 GetBonusAbilityCaseCount() const
    {
        return _bonusAbilityCaseCount;
    }

    void AddBonusAbilityCases(uint32 count)
    {
        uint64 const value =
            uint64(_bonusAbilityCaseCount) +
            uint64(count);

        _bonusAbilityCaseCount =
            value >
                std::numeric_limits<uint32>::max()
            ? std::numeric_limits<uint32>::max()
            : uint32(value);
    }

    uint32 GetBonusTalentCaseCount() const
    {
        return _bonusTalentCaseCount;
    }

    void AddBonusTalentCases(uint32 count)
    {
        uint64 const value =
            uint64(_bonusTalentCaseCount) +
            uint64(count);

        _bonusTalentCaseCount =
            value >
                std::numeric_limits<uint32>::max()
            ? std::numeric_limits<uint32>::max()
            : uint32(value);
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
        _activeStageAffixRanks.clear();
        _creatureAffixIds.clear();
    }

    bool AddStageAffix(
        uint32 affixId,
        uint8 rank = 1)
    {
        if (!affixId)
            return false;

        bool const inserted =
            _activeStageAffixIds.insert(
                affixId).second;

        _activeStageAffixRanks[affixId] =
            rank ? rank : 1;

        return inserted;
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

    uint8 GetStageAffixRank(
        uint32 affixId) const
    {
        auto const itr =
            _activeStageAffixRanks.find(
                affixId);

        return itr == _activeStageAffixRanks.end()
            ? 1
            : itr->second;
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
    void RecordRecentObjective(
        ManastormSegment const& segment);

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

    // Oldest -> newest native Manastorm objective identities. Alternate
    // segment routes to the same boss share one identity and therefore cannot
    // immediately recycle that boss while other eligible objectives exist.
    std::vector<uint64> _recentObjectiveKeys;

    // Live Ascension observation: entry protection lasts at most ~2 minutes.
    // Movement / explicit combat may collapse it earlier.
    uint32 _preparationProtectionRemainingMs =
        PreparationProtectionMs;

    // Set only by the real protection timeout or by the five-second
    // inter-stage fallback. Ordinary movement/combat start requests still
    // wait for every connected member to finish the private-map transfer.
    bool _canStartWithMissingMembers = false;

    // Snapshot each member's active gadget loadout at run creation. Native
    // loadout changes are already forbidden while a run is active.
    std::unordered_map<
        ObjectGuid::LowType,
        GadgetSlots>
        _memberGadgetLoadouts;

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

    std::unordered_set<ObjectGuid::LowType>
        _affixEligibleConfiguredSpawnIds;

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

    std::unordered_map<ObjectGuid::LowType, uint32> _cooldownResetDepths;
    uint32 _instanceId = 0;

    // During the five-second portal window the run may own the completed
    // stage and the prepared next stage at the same time. The completed
    // stage remains only as a portal waiting room; all combat authority
    // moves to _segment/_instanceId.
    bool _hasPreviousStage = false;
    ManastormSegment _previousSegment;
    uint32 _previousInstanceId = 0;
    ObjectGuid _previousPortalGuid;
    std::unordered_set<ObjectGuid::LowType>
        _pendingStageTransferMembers;

    ObjectGuid _portalGuid;
    bool _entranceInitialized = false;
    bool _startRequested = false;
    ObjectGuid _objectiveCreatureGuid;
    std::unordered_set<ObjectGuid> _stageCreatureGuids;
    std::unordered_set<ObjectGuid> _trashHeartRolls;

    // Treasure Keeper is a separate special-encounter reward path.
    // The spawn chance grows with eligible trash kills/depth, but at most
    // one Keeper may appear in a disposable stage.
    uint32 _treasureTrashKills = 0;
    bool _treasureKeeperSpawned = false;
    ObjectGuid _treasureKeeperGuid;

    // Greedy Demon is a separate stage-level treasure encounter.
    // Roll once per disposable stage; never attach ordinary trash roles.
    bool _greedyDemonRolled = false;
    ObjectGuid _greedyDemonGuid;

    // Treasure Keeper rewards are secured during the stage and committed
    // atomically with the objective-completion reward.
    uint32 _bonusCacheCount = 0;
    uint32 _bonusAbilityCaseCount = 0;
    uint32 _bonusTalentCaseCount = 0;

    // Affixes selected for the CURRENT disposable stage.
    std::unordered_set<uint32>
        _activeStageAffixIds;

    std::unordered_map<uint32, uint8>
        _activeStageAffixRanks;

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