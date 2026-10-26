#ifndef MANASTORM_REWARDS_H
#define MANASTORM_REWARDS_H

#include "DatabaseEnv.h"
#include "ManastormDefines.h"
#include "ManastormReleaseStage.h"

#include <array>
#include <memory>
#include <string>
#include <vector>
#include <utility>

class Creature;
class ManastormRun;

struct ManastormRewardPublication;

struct ManastormRewardStateSnapshot
{
    uint32 CacheChancePct = 0;
    uint32 BedlamRemainderBp = 0;
    uint32 BonzoRemainderBp = 0;
    uint32 CachesEarned = 0;
    uint64 BedlamEarned = 0;
    uint64 BonzoEarned = 0;
};

struct ManastormWeeklyCacheAllowance
{
    bool Enabled = false;
    uint32 SavedResetTime = 0;
    uint32 SavedEarned = 0;
    uint32 Earned = 0;
    uint32 Limit = 0;
    uint32 ResetTime = 0;

    bool CanEarn() const { return !Enabled || Earned < Limit; }
};

struct ManastormRewardVisibilityRecord
{
    uint32 ItemEntry = 0;
    uint8 Action = 0;
    uint32 LockEndTimestamp = 0;
    uint32 SecondsRemaining = 0;
    uint32 EarnedQuantity = 0;
    uint32 MaxQuantity = 0;
    uint32 RemainingQuantity = 0;
    uint32 WindowStart = 0;
    uint32 WindowEnd = 0;
};

class ManastormRewards
{
public:
    static ManastormRewards& Instance();

    bool Load();
    bool IsLoaded() const { return _loaded; }

    bool LoadState(
        ObjectGuid::LowType characterGuid,
        ManastormMode mode,
        bool endgame,
        ManastormRewardStateSnapshot& snapshot,
        std::string& error) const;

    bool PrepareStageCompletion(
        ManastormRun const& run,
        CharacterDatabaseTransaction const& transaction,
        std::vector<std::shared_ptr<ManastormRewardPublication>>& publications,
        std::string& error) const;

    bool LoadWeeklyCacheAllowance(ObjectGuid::LowType characterGuid,
        ManastormWeeklyCacheAllowance& allowance) const;

    bool SettlePendingCurrency(ObjectGuid::LowType characterGuid) const;

    void PublishCommitted(
        std::vector<std::shared_ptr<ManastormRewardPublication>>& publications) const;

    std::vector<ManastormRewardVisibilityRecord>
        BuildVisibilityRecords(ObjectGuid::LowType characterGuid, bool endgame, uint32 bonusCaches = 0) const;

    bool ResolveCacheItemEntry(
        bool endgame,
        uint32 depth,
        uint32 playerLevel,
        uint32& itemEntry,
        ObjectGuid::LowType characterGuid = 0,
        uint8 mode = 0,
        uint32 completingDepth = 0) const;

    bool IsCacheItemEntry(
        uint32 itemEntry) const;

    uint32 GetReleasedItemLevelCap() const;

    double GetGroupRewardMultiplier(
        uint32 memberCount) const;

    bool IsTreasureKeeperEntry(
        uint32 entry) const;

    bool IsActiveTreasureKeeper(
        Creature const* creature,
        ManastormRun const& run) const;

    bool TrySpawnTreasureKeeper(
        Creature* killedTrash,
        ManastormRun& run) const;

    void OnTreasureKeeperKilled(
        ManastormRun& run) const;

private:
    ManastormRewards() = default;

    enum class CacheSelector : uint8
    {
        CharacterLevel = 1,
        Depth = 2,
    };

    struct CacheBracket
    {
        uint32 BracketId = 0;
        uint8 Track = 0;
        CacheSelector Selector =
            CacheSelector::CharacterLevel;
        uint32 MinValue = 0;
        uint32 MaxValue = 0;
        uint32 CacheItemEntry = 0;
    };

    struct CacheUnlockRequirement
    {
        uint32 ItemEntry = 0;
        uint8 Track = 0;
        uint32 CompletedDepth = 0;
    };

    struct RewardRule
    {
        std::string Key;
        bool EndgameOnly = false;
        bool WildcardOnly = false;
        bool NonWildcardOnly = false;
        uint32 ItemEntry = 0;
        uint32 BaseAmount = 0;
        uint32 DepthStep = 1;
        uint32 AmountPerStep = 0;
        bool FirstClearOnly = false;
        bool ApplyGroupMultiplier = false;
        bool ApplySegmentMultiplier = false;
    };

    struct GroupRewardRange
    {
        uint8 MinMembers = 1;
        uint8 MaxMembers = 1;
        double Multiplier = 1.0;
    };

    struct PotentialReward
    {
        uint8 DisplayOrder = 0;
        uint32 ItemEntry = 0;
        bool Enabled = true;
    };

    struct TreasureKeeperRule
    {
        bool Enabled = false;
        uint32 CreatureEntry = 0;
        uint32 BaseChanceBp = 0;
        uint32 ChancePerDepthBp = 0;
        uint32 ChancePerKillBp = 0;
        uint32 MaxChanceBp = 0;
        uint32 BonusCacheCount = 0;
        uint32 AbilityCaseItem = 0;
        uint32 TalentCaseItem = 0;
        uint32 CaseCount = 0;
    };

    bool PrepareNormalCacheReward(ObjectGuid::LowType characterGuid, bool endgame,
        ManastormRewardStateSnapshot const& state, CharacterDatabaseTransaction const& transaction,
        bool& wonNormalCache, uint32& nextCacheChance, ManastormWeeklyCacheAllowance& allowance,
        std::string& error) const;

    bool PrepareItemDelivery(
        ObjectGuid::LowType characterGuid,
        std::vector<std::pair<uint32, uint32>> const& stacks,
        CharacterDatabaseTransaction const& transaction,
        std::vector<std::shared_ptr<ManastormRewardPublication>>& publications,
        std::string& error,
        std::string const& subject) const;

    uint32 GetActiveGameModeMask(ObjectGuid::LowType characterGuid) const;

    bool LoadCacheBrackets();
    bool LoadCacheUnlockRequirements();
    void LoadReleasedItemLevelCaps();
    bool LoadRewardRules();
    bool LoadGroupRewardMultipliers();
    bool LoadPotentialRewards();
    bool LoadTreasureKeeperRule();
    bool ValidateCharacterSchema() const;

    uint32 CalculateBaseAmount(
        RewardRule const& rule,
        uint32 depth) const;

    uint32 ScaleCurrencyAmount(
        uint32 baseAmount,
        RewardRule const& rule,
        double groupMultiplier,
        double segmentMultiplier,
        uint32 previousRemainderBp,
        uint32& nextRemainderBp) const;

    std::vector<CacheBracket> _cacheBrackets;
    std::vector<CacheUnlockRequirement> _cacheUnlockRequirements;
    std::array<uint32, ManastormReleaseStage::AllReleased + 1> _releasedItemLevelCaps{};
    RewardRule _bedlam;
    RewardRule _bonzo;
    std::vector<RewardRule> _completionRewards;
    std::vector<GroupRewardRange> _groupRewardRanges;
    std::vector<PotentialReward> _potentialRewards;
    TreasureKeeperRule _treasureKeeper;
    bool _loaded = false;
};

#endif
