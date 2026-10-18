#ifndef MANASTORM_MGR_H
#define MANASTORM_MGR_H

#include "ManastormRun.h"
#include "SharedDefines.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class Creature;
class Map;
class Player;
class Unit;

enum DamageEffectType : uint8;

class ManastormMgr
{
public:
    static ManastormMgr& Instance();

    bool ReloadData();

    ManastormRun* StartRun(
        Player* player,
        uint32 depth,
        std::string& error,
        bool bypassCheckpoint = false,
        uint32 forcedSegmentId = 0);

    bool StopRun(
        Player* player,
        std::string& error);

    bool HandleReleaseAfterWipe(Player* player);

    bool UseStagePortal(
        Player* player,
        Creature* portal,
        std::string& error);

    ManastormRun* GetRunFor(Player const* player);
    ManastormRun const* GetRunFor(Player const* player) const;

    void SyncClientState(Player* player);
    void OnPlayerLogin(Player* player);

    void OpenClientUI(Player* player) const;

    bool IsPlayerInUsableEndlessStage(Player const* player) const;

    bool IsPlayerInActiveEndlessStage(
        Player const* player) const;

    bool HasManastormPotionCharge(
        Player const* player) const;

    bool ConsumeManastormPotionCharge(
        Player* player);

    void SyncManastormPotionCharges(Player const* player) const;

    bool IsValidRegenerationMatrixTarget(
        Player const* caster,
        Player const* target) const;

    bool ConsumeRegenerationMatrixCharge(
        Player* caster,
        Player* target);

    void Update(uint32 diff);
    bool OnPlayerEnterMap(Map* map, Player* player);

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel);

    void OnPlayerGiveXP(
        Player* player,
        uint32& amount,
        Unit* victim,
        uint8 xpSource);

    void OnBeforeCreatureSelectLevel(
        Creature* creature,
        uint8& level);

    void OnCreatureSelectLevel(
        Creature* creature);

    void OnCreatureAddWorld(Creature* creature);
    void OnCreatureRemoveWorld(Creature* creature);

    void OnUnitDeath(
        Unit* unit,
        Unit* killer);

    void OnUnitEnterCombat(
        Unit* unit,
        Unit* victim);

    void OnDamage(
        Unit* attacker,
        Unit* victim,
        uint32& damage);

    void OnMeleeDamage(
        Unit* attacker,
        Unit* victim,
        uint32 damage);

    uint32 ResolveAffixRankSpell(Unit const* caster, uint32 spellId);

    uint32 ScaleCreatureDamage(
        Unit* attacker,
        Unit* victim,
        uint32 damage,
        DamageEffectType damageType);

    std::size_t GetActiveRunCount() const
    {
        return _runs.size();
    }

    bool ForceStageAffix(
        Player* player,
        uint32 affixId,
        std::string& error);

private:
    ManastormMgr() = default;

    struct ManastormDifficultySettings
    {
        Difficulty Dungeon;
        Difficulty Raid;
    };

    void RestoreOriginalDifficulties(Player* player);
    std::unordered_map<ObjectGuid::LowType, ManastormDifficultySettings> _originalDifficulties;

    void SendClientState(
        Player* player,
        ManastormRun const* run) const;

    void SendClientProgression(
        Player* player) const;

    void SendUnlockToast(
        Player* player,
        uint32 messageId) const;

    void BroadcastClientState(
        ManastormRun const& run) const;

    enum class ManastormFailureExit : uint8
    {
        SavedLocation = 0,
        FactionHub = 1,
    };

    struct ManastormPotionChargeState
    {
        uint8 Charges =
            ManastormBaseline::PotionMaxCharges;

        uint32 RechargeTimerMs = 0;
    };

    void HandlePlayerDeath(
        Player* player);

    void FailRun(
        ManastormRun& run,
        std::string const& reason,
        ObjectGuid::LowType externalDepartureGuid = 0,
        ManastormFailureExit failureExit =
            ManastormFailureExit::SavedLocation);

    void GrantBaselineRunItems(
        Player* player);

    void RemoveBaselineRunItems(
        Player* player,
        bool clearPotionState);

    void UpdateManastormPotionCharges(
        uint32 diff);

    bool SpawnHeartProjectile(
        Creature* creature,
        ManastormRun& run,
        bool persistentLauncher = false);

    bool TrySpawnTrashHeart(
        Creature* creature,
        ManastormRun& run);

    void UpdateHeartPickups(uint32 diff);

    void ApplyCreatureHealthScaling(
        Creature* creature,
        ManastormRun& run,
        double healthPct);

    void ApplyChaoticLinkBossHealth(
        Creature* boss,
        ManastormRun& run,
        double healthPct);

    ManastormRun* GetRunForGuid(
        ObjectGuid::LowType guid);

    ManastormRun const* GetRunForGuid(
        ObjectGuid::LowType guid) const;

    ManastormRun* GetRunForStage(
        uint32 mapId,
        uint32 instanceId);

    uint64 BuildRunSeed(
        uint64 runId,
        ObjectGuid::LowType ownerGuid) const;

    void SpawnStagePortal(Map* map, ManastormRun& run, Position const& position);

    bool PrepareStage(
        Player* player,
        ManastormRun& run,
        std::string& error,
        ObjectGuid::LowType transferOnlyGuid = 0);

    bool TransferMemberToCurrentStage(
        Player* player,
        ManastormRun& run,
        std::string& error);

    void FinishPreviousStageTransition(
        ManastormRun& run);

    bool TransitionToNextStage(
        ManastormRun& run,
        std::string& error,
        ObjectGuid::LowType immediateMemberGuid = 0,
        bool transferAll = false);

    uint64 _nextRunId = 1;

    std::unordered_map<uint64, std::unique_ptr<ManastormRun>> _runs;
    std::unordered_map<ObjectGuid::LowType, uint64> _memberRunIds;
    std::unordered_map<uint64, uint64> _stageRunIds;
    std::unordered_map<uint64, uint32> _transitionTimers;
    std::unordered_map<ObjectGuid::LowType,ManastormPotionChargeState>_manastormPotionCharges;

    // Only item entries actually created by this process are removed again.
    // Pre-existing legitimate copies are never destroyed by Manastorm cleanup.
    std::unordered_map<
        ObjectGuid::LowType,
        std::unordered_set<uint32>>
        _grantedBaselineItems;

    uint32 _heartPickupCheckTimer = 0;
    uint32 _runValidationTimer = 0;
};

#endif
