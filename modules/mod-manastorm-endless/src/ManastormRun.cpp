#include "ManastormRun.h"

#include <utility>

ManastormRun::ManastormRun(
    uint64 runId,
    uint64 seed,
    ObjectGuid::LowType ownerGuid,
    std::vector<ObjectGuid::LowType> members,
    ManastormMode mode,
    uint8 creatureLevel,
    uint32 depth,
    ManastormSegment const& segment,
    ManastormScalingPoint const& scaling)
    : _runId(runId),
    _seed(seed),
    _ownerGuid(ownerGuid),
    _members(std::move(members)),
    _mode(mode),
    _creatureLevel(creatureLevel),
    _depth(depth),
    _chaoticLinkStacks(segment.ChaoticLinkStacks),
    _segment(segment),
    _scaling(scaling)
{
    _routeConfiguredSpawnIds.insert(
        segment.RouteSpawnIds.begin(),
        segment.RouteSpawnIds.end());

    _chaoticLinkConfiguredSpawnIds.insert(
        segment.ChaoticLinkSpawnIds.begin(),
        segment.ChaoticLinkSpawnIds.end());

    _chaoticLinkUnusedSpawnIds.insert(
        segment.ChaoticLinkSpawnIds.begin(),
        segment.ChaoticLinkSpawnIds.end());

    _randomizationConfiguredSpawnIds.insert(
        segment.RandomizationSpawnIds.begin(),
        segment.RandomizationSpawnIds.end());

    _creaturePoolSourceSpawnIds.insert(
        segment.CreaturePoolSourceSpawnIds.begin(),
        segment.CreaturePoolSourceSpawnIds.end());
}

void ManastormRun::PrepareNextStage(
    uint8 creatureLevel,
    uint32 depth,
    ManastormSegment const& segment,
    ManastormScalingPoint const& scaling)
{
    _creatureLevel = creatureLevel;
    _depth = depth;
    _segment = segment;
    _scaling = scaling;

    // Resurrection resources belong to the stage,
    // not the entire Endless run.
    ResetResurrectionCharges();

    // Every newly generated stage starts from that segment's authored
    // Chaotic Link count, regardless of Endless depth.
    _chaoticLinkStacks =
        segment.ChaoticLinkStacks;

    _chaoticLinkBaseMaxHealth = 0;

    _routeConfiguredSpawnIds.clear();
    _chaoticLinkConfiguredSpawnIds.clear();
    _chaoticLinkUnusedSpawnIds.clear();
    _randomizationConfiguredSpawnIds.clear();
    _creaturePoolSourceSpawnIds.clear();

    _routeConfiguredSpawnIds.insert(
        segment.RouteSpawnIds.begin(),
        segment.RouteSpawnIds.end());

    _chaoticLinkConfiguredSpawnIds.insert(
        segment.ChaoticLinkSpawnIds.begin(),
        segment.ChaoticLinkSpawnIds.end());

    _chaoticLinkUnusedSpawnIds.insert(
        segment.ChaoticLinkSpawnIds.begin(),
        segment.ChaoticLinkSpawnIds.end());

    _randomizationConfiguredSpawnIds.insert(
        segment.RandomizationSpawnIds.begin(),
        segment.RandomizationSpawnIds.end());

    _creaturePoolSourceSpawnIds.insert(
        segment.CreaturePoolSourceSpawnIds.begin(),
        segment.CreaturePoolSourceSpawnIds.end());

    _instanceId = 0;
    _guideGuid.Clear();
    _portalGuid.Clear();
    _entranceInitialized = false;
    _startRequested = false;
    _objectiveCreatureGuid.Clear();
    _stageCreatureGuids.clear();
    _trashHeartRolls.clear();

    // Affixes belong to one disposable stage.
    // Selection/assignment is rebuilt for every new depth.
    ClearStageAffixState();

    _activeHeartGuids.clear();
    _bossHeartThresholdMask = 0;
}
