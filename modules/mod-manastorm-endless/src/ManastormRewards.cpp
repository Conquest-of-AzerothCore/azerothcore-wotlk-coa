#include "ManastormRewards.h"
#include "ScriptMgr.h"
#include "ManastormExperience.h"

#include "Creature.h"
#include "Field.h"
#include "GameTime.h"
#include "Item.h"
#include "Log.h"
#include "Mail.h"
#include "MailMgr.h"
#include "Map.h"
#include "ManastormRun.h"
#include "ManastormModuleConfig.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "Random.h"
#include "WorldSession.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless.rewards";

    constexpr uint32 GAME_MODE_WILDCARD = 0x0040;
    constexpr uint32 ITEM_BEDLAM_BULLION = 1297307;
    constexpr uint32 ITEM_BONZO_BOLT = 1297308;
    constexpr uint32 REWARD_MAIL_SENDER = 80919;
    constexpr uint32 CACHE_PITY_STEP_PCT = 13;
    constexpr uint32 BASIS_POINTS = 10000;
    constexpr float TWO_PI = 6.28318530717958647692f;

    uint8 TrackBit(bool endgame)
    {
        return ManastormGetTrackBit(endgame);
    }

    uint32 SaturatingAdd(uint32 left, uint32 right)
    {
        uint64 const value =
            uint64(left) +
            uint64(right);

        return value >
            std::numeric_limits<uint32>::max()
            ? std::numeric_limits<uint32>::max()
            : uint32(value);
    }

    uint64 SaturatingAdd(uint64 left, uint32 right)
    {
        if (left >
            std::numeric_limits<uint64>::max() -
                uint64(right))
        {
            return std::numeric_limits<uint64>::max();
        }

        return left + uint64(right);
    }
}

struct ManastormRewardPublication
{
    ObjectGuid::LowType CharacterGuid = 0;
    Mail MailData{};
    std::vector<std::unique_ptr<Item>> Items;
};

ManastormRewards& ManastormRewards::Instance()
{
    static ManastormRewards instance;
    return instance;
}

bool ManastormRewards::Load()
{
    _loaded = false;
    _cacheBrackets.clear();
    _cacheUnlockRequirements.clear();
    _bedlam = {};
    _bonzo = {};
    _completionRewards.clear();
    _groupRewardRanges.clear();
    _potentialRewards.clear();
    _treasureKeeper = {};

    if (!LoadCacheBrackets() ||
        !LoadCacheUnlockRequirements() ||
        !LoadRewardRules() ||
        !LoadGroupRewardMultipliers() ||
        !LoadPotentialRewards() ||
        !LoadTreasureKeeperRule() ||
        !ValidateCharacterSchema() ||
        !ManastormExperience::Instance().Load())
    {
        return false;
    }

    _loaded = true;

    LOG_INFO(
        LOG_FILTER,
        "Loaded authoritative Manastorm reward policy: "
        "cacheBrackets={} potentialRewards={} groupRanges={} treasureKeeper={}.",
        _cacheBrackets.size(),
        _potentialRewards.size(),
        _groupRewardRanges.size(),
        _treasureKeeper.Enabled
            ? "enabled"
            : "disabled");

    return true;
}

bool ManastormRewards::LoadCacheBrackets()
{
    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "bracket_id, track, selector_kind, "
            "min_value, max_value, cache_item_entry "
            "FROM manastorm_cache_bracket "
            "WHERE enabled = 1 "
            "ORDER BY track, selector_kind, min_value, "
            "max_value, bracket_id");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to load manastorm_cache_bracket. "
            "Apply 15_manastorm_cache_brackets.sql.");

        return false;
    }

    bool foundNormal = false;
    bool foundEndgame = false;

    do
    {
        Field* fields =
            result->Fetch();

        CacheBracket bracket;
        bracket.BracketId =
            fields[0].Get<uint32>();
        bracket.Track =
            fields[1].Get<uint8>();

        uint8 const selector =
            fields[2].Get<uint8>();

        bracket.MinValue =
            fields[3].Get<uint32>();
        bracket.MaxValue =
            fields[4].Get<uint32>();
        bracket.CacheItemEntry =
            fields[5].Get<uint32>();

        if (selector ==
            uint8(
                CacheSelector::CharacterLevel))
        {
            bracket.Selector =
                CacheSelector::CharacterLevel;
        }
        else if (selector ==
            uint8(
                CacheSelector::Depth))
        {
            bracket.Selector =
                CacheSelector::Depth;
        }
        else
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm cache bracket {}: "
                "selector_kind={} is unknown.",
                bracket.BracketId,
                uint32(selector));

            return false;
        }

        bool const normalTrack =
            bracket.Track ==
                ManastormTrackBits::Normal;

        bool const endgameTrack =
            bracket.Track ==
                ManastormTrackBits::Endgame;

        CacheSelector const expectedSelector =
            normalTrack
            ? CacheSelector::CharacterLevel
            : CacheSelector::Depth;

        if (!bracket.BracketId ||
            (!normalTrack && !endgameTrack) ||
            bracket.MinValue >
                bracket.MaxValue ||
            !bracket.CacheItemEntry ||
            bracket.Selector !=
                expectedSelector ||
            !sObjectMgr->GetItemTemplate(
                bracket.CacheItemEntry))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid enabled Manastorm cache bracket {}: "
                "track={} selector={} range={}-{} item={}.",
                bracket.BracketId,
                uint32(bracket.Track),
                uint32(selector),
                bracket.MinValue,
                bracket.MaxValue,
                bracket.CacheItemEntry);

            return false;
        }

        for (CacheBracket const& existing :
            _cacheBrackets)
        {
            if (existing.Track !=
                    bracket.Track ||
                existing.Selector !=
                    bracket.Selector)
            {
                continue;
            }

            bool const overlaps =
                bracket.MinValue <=
                    existing.MaxValue &&
                bracket.MaxValue >=
                    existing.MinValue;

            if (overlaps)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Overlapping enabled Manastorm cache brackets "
                    "{} ({}-{}) and {} ({}-{}) for track={} "
                    "selector={}.",
                    existing.BracketId,
                    existing.MinValue,
                    existing.MaxValue,
                    bracket.BracketId,
                    bracket.MinValue,
                    bracket.MaxValue,
                    uint32(bracket.Track),
                    uint32(selector));

                return false;
            }
        }

        foundNormal |=
            normalTrack;

        foundEndgame |=
            endgameTrack;

        _cacheBrackets.push_back(
            bracket);
    }
    while (result->NextRow());

    if (!foundNormal ||
        !foundEndgame)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm cache brackets must contain at least "
            "one enabled Normal/level and one Endgame/depth "
            "mapping.");

        return false;
    }

    return true;
}

bool ManastormRewards::LoadCacheUnlockRequirements()
{
    QueryResult schema = WorldDatabase.Query(
        "SELECT COUNT(*) FROM manastorm_cache_unlock_requirement");
    if (!schema)
    {
        LOG_ERROR(LOG_FILTER, "Apply 47_manastorm_classic_cache_unlocks.sql before loading rewards.");
        return false;
    }

    QueryResult result = WorldDatabase.Query(
        "SELECT item_entry, track, required_completed_depth "
        "FROM manastorm_cache_unlock_requirement WHERE enabled = 1 ORDER BY item_entry, track");
    if (!result)
        return true;

    do
    {
        Field* fields = result->Fetch();
        CacheUnlockRequirement requirement;
        requirement.ItemEntry = fields[0].Get<uint32>();
        requirement.Track = fields[1].Get<uint8>();
        requirement.CompletedDepth = fields[2].Get<uint32>();
        if (!sObjectMgr->GetItemTemplate(requirement.ItemEntry) ||
            (requirement.Track != ManastormTrackBits::Normal &&
             requirement.Track != ManastormTrackBits::Endgame))
        {
            LOG_ERROR(LOG_FILTER, "Invalid Manastorm cache requirement for item {} track {}.",
                requirement.ItemEntry, uint32(requirement.Track));
            return false;
        }

        _cacheUnlockRequirements.push_back(requirement);
    } while (result->NextRow());

    return true;
}

bool ManastormRewards::ResolveCacheItemEntry(
    bool endgame,
    uint32 depth,
    uint32 playerLevel,
    uint32& itemEntry,
    ObjectGuid::LowType characterGuid,
    uint8 mode,
    uint32 completingDepth) const
{
    itemEntry = 0;

    if (!_loaded)
        return false;

    uint8 const track =
        TrackBit(
            endgame);

    CacheSelector const selector =
        endgame
        ? CacheSelector::Depth
        : CacheSelector::CharacterLevel;

    uint32 const value =
        endgame
        ? depth
        : playerLevel;

    if (!value)
        return false;

    bool historyLoaded = false;
    bool historyValid = false;
    uint32 completedDepth = 0;
    auto eligible = [&](CacheBracket const& bracket)
    {
        for (CacheUnlockRequirement const& requirement : _cacheUnlockRequirements)
        {
            if (requirement.ItemEntry != bracket.CacheItemEntry || requirement.Track != track ||
                !requirement.CompletedDepth)
                continue;

            if (!historyLoaded)
            {
                historyLoaded = true;
                if (characterGuid && mode >= 1 && mode <= 4)
                {
                    QueryResult history = CharacterDatabase.Query(
                        "SELECT COALESCE(MAX(depth), 0) FROM character_manastorm_completed_depth "
                        "WHERE guid = {} AND mode = {} AND track = {}",
                        characterGuid, uint32(mode), uint32(track));
                    if (history)
                    {
                        completedDepth = std::max(history->Fetch()[0].Get<uint32>(), completingDepth);
                        historyValid = true;
                    }
                }
            }

            if (!historyValid || completedDepth < requirement.CompletedDepth)
                return false;
        }

        return true;
    };

    CacheBracket const* matching = nullptr;
    for (CacheBracket const& bracket : _cacheBrackets)
    {
        if (bracket.Track == track && bracket.Selector == selector &&
            value >= bracket.MinValue && value <= bracket.MaxValue)
        {
            matching = &bracket;
            break;
        }
    }

    if (!matching)
        return false;

    if (eligible(*matching))
    {
        itemEntry = matching->CacheItemEntry;
        return true;
    }

    // A locked tier falls back to the highest eligible lower bracket.
    CacheBracket const* fallback = nullptr;
    for (CacheBracket const& bracket : _cacheBrackets)
    {
        if (bracket.Track == track && bracket.Selector == selector &&
            bracket.MinValue < matching->MinValue && eligible(bracket) &&
            (!fallback || bracket.MinValue > fallback->MinValue))
            fallback = &bracket;
    }

    if (!fallback)
        return false;

    itemEntry = fallback->CacheItemEntry;
    return true;
}

bool ManastormRewards::IsCacheItemEntry(
    uint32 itemEntry) const
{
    if (!_loaded ||
        !itemEntry)
    {
        return false;
    }

    for (CacheBracket const& bracket :
        _cacheBrackets)
    {
        if (bracket.CacheItemEntry ==
            itemEntry)
        {
            return true;
        }
    }

    //
    // Preserved Classic dungeon and Molten Core caches targeted by the donor cache selector.
    // Some are outside the active depth catalogue, but already-owned or
    // manually granted copies must continue to use personalized opening after
    // mod-ascension-compat is removed.
    //
    return
        itemEntry == 1278050 ||
        itemEntry == 1278051 ||
        itemEntry == 1278052 ||
        itemEntry == 1278053 ||
        itemEntry == 1278054 ||
        itemEntry == 1278055 ||
        itemEntry == 1278056 ||
        itemEntry == 1278057 ||
        itemEntry == 1278058 ||
        itemEntry == 1278059 ||
        itemEntry == 1278060 ||
        itemEntry == 1278061 ||
        itemEntry == 1278062 ||
        itemEntry == 1278063 ||
        itemEntry == 1278064 ||
        itemEntry == 1278065 ||
        itemEntry == 1278066 ||
        itemEntry == 1278067 ||
        itemEntry == 1278068 ||
        itemEntry == 1278069 ||
        itemEntry == 1278070 ||
        itemEntry == 1278071 ||
        itemEntry == 1278072 ||
        itemEntry == 1278073 ||
        itemEntry == 1278074 ||
        itemEntry == 1278075 ||
        itemEntry == 1278076 ||
        itemEntry == 1278077 ||
        itemEntry == 1278078 ||
        itemEntry == 1278079 ||
        itemEntry == 1278080 ||
        itemEntry == 1278081 ||
        itemEntry == 1278082 ||
        itemEntry == 1278083 ||
        itemEntry == 1278084;
}

bool ManastormRewards::LoadRewardRules()
{
    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "reward_key, item_entry, base_amount, "
            "depth_step, amount_per_step, "
            "first_clear_only, apply_group_multiplier, "
            "apply_segment_multiplier, enabled "
            "FROM manastorm_reward_rule "
            "ORDER BY reward_key");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to load manastorm_reward_rule. "
            "Apply 14_manastorm_rewards.sql.");

        return false;
    }

    bool foundBedlam = false;
    bool foundBonzo = false;

    do
    {
        Field* fields =
            result->Fetch();

        std::string const key =
            fields[0].Get<std::string>();

        if (!fields[8].Get<uint8>())
            continue;

        RewardRule rule;
        // Keep legacy ledger keys so the currency rename retains earned totals
        // and fractional carry. World policy accepts the current Rune names.
        rule.Key = key == "RUNES" ? "MARKS"
            : key == "RUNES_FIRST" ? "MARKS_FIRST" : key;
        rule.EndgameOnly = key == "CASE";
        rule.WildcardOnly = key == "CASE" || key == "BONUS_CACHE";
        rule.NonWildcardOnly = key == "BONUS_CACHE_OTHER";
        rule.ItemEntry =
            fields[1].Get<uint32>();
        rule.BaseAmount =
            fields[2].Get<uint32>();
        rule.DepthStep =
            fields[3].Get<uint32>();
        rule.AmountPerStep =
            fields[4].Get<uint32>();
        rule.FirstClearOnly =
            fields[5].Get<uint8>() != 0;
        rule.ApplyGroupMultiplier =
            fields[6].Get<uint8>() != 0;
        rule.ApplySegmentMultiplier =
            fields[7].Get<uint8>() != 0;

        if ((key == "CASE" && !sObjectMgr->GetItemTemplate(1278048)) ||
            !rule.ItemEntry ||
            !rule.DepthStep ||
            !sObjectMgr->GetItemTemplate(
                rule.ItemEntry))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid enabled Manastorm reward rule '{}': "
                "item={} depthStep={}.",
                key,
                rule.ItemEntry,
                rule.DepthStep);

            return false;
        }

        if (key == "BEDLAM")
        {
            _bedlam = rule;
            foundBedlam = true;
        }
        else if (key == "BONZO")
        {
            _bonzo = rule;
            foundBonzo = true;
        }
        else if (key == "MARKS" || key == "MARKS_FIRST" || key == "RUNES" ||
            key == "RUNES_FIRST" || key == "CASE" || key == "BONUS_CACHE" || key == "BONUS_CACHE_OTHER")
        {
            if (std::any_of(_completionRewards.begin(), _completionRewards.end(),
                [&rule](RewardRule const& existing) { return existing.Key == rule.Key; }))
            {
                LOG_ERROR(LOG_FILTER, "Duplicate Manastorm reward policy for '{}'.", key);
                return false;
            }

            _completionRewards.push_back(rule);
        }
    }
    while (result->NextRow());

    if (!foundBedlam ||
        !foundBonzo ||
        _bedlam.ItemEntry !=
            ITEM_BEDLAM_BULLION ||
        _bonzo.ItemEntry !=
            ITEM_BONZO_BOLT ||
        !_bedlam.FirstClearOnly ||
        _bonzo.FirstClearOnly)
    {
        LOG_ERROR(
            LOG_FILTER,
            "BEDLAM and BONZO reward rules do not match "
            "the authoritative reward roles.");

        return false;
    }

    return true;
}

bool ManastormRewards::LoadGroupRewardMultipliers()
{
    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "min_members, max_members, multiplier "
            "FROM manastorm_reward_group_multiplier "
            "WHERE enabled = 1 "
            "ORDER BY min_members, max_members");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to load manastorm_reward_group_multiplier. "
            "Apply 14_manastorm_rewards.sql.");

        return false;
    }

    do
    {
        Field* fields =
            result->Fetch();

        GroupRewardRange range;
        range.MinMembers =
            fields[0].Get<uint8>();
        range.MaxMembers =
            fields[1].Get<uint8>();
        range.Multiplier =
            fields[2].Get<double>();

        if (!range.MinMembers ||
            range.MaxMembers <
                range.MinMembers ||
            range.MaxMembers >
                ManastormLimits::MaxMembers ||
            !std::isfinite(
                range.Multiplier) ||
            range.Multiplier <= 0.0)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm reward group range "
                "{}-{} = {}.",
                uint32(range.MinMembers),
                uint32(range.MaxMembers),
                range.Multiplier);

            return false;
        }

        for (GroupRewardRange const& existing :
            _groupRewardRanges)
        {
            bool const overlaps =
                range.MinMembers <=
                    existing.MaxMembers &&
                range.MaxMembers >=
                    existing.MinMembers;

            if (overlaps)
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Overlapping Manastorm reward group ranges "
                    "{}-{} and {}-{}.",
                    uint32(existing.MinMembers),
                    uint32(existing.MaxMembers),
                    uint32(range.MinMembers),
                    uint32(range.MaxMembers));

                return false;
            }
        }

        _groupRewardRanges.push_back(
            range);
    }
    while (result->NextRow());

    return !_groupRewardRanges.empty();
}

bool ManastormRewards::LoadPotentialRewards()
{
    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "display_order, item_entry, enabled "
            "FROM manastorm_potential_reward "
            "ORDER BY display_order");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to load manastorm_potential_reward. "
            "Apply 14_manastorm_rewards.sql.");

        return false;
    }

    do
    {
        Field* fields =
            result->Fetch();

        PotentialReward reward;
        reward.DisplayOrder =
            fields[0].Get<uint8>();
        reward.ItemEntry =
            fields[1].Get<uint32>();
        reward.Enabled =
            fields[2].Get<uint8>() != 0;

        if (!reward.DisplayOrder ||
            !reward.ItemEntry ||
            !sObjectMgr->GetItemTemplate(
                reward.ItemEntry))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Manastorm potential reward "
                "order={} item={}.",
                uint32(
                    reward.DisplayOrder),
                reward.ItemEntry);

            return false;
        }

        _potentialRewards.push_back(
            reward);
    }
    while (result->NextRow());

    if (_potentialRewards.size() != 7)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Native Manastorm queue expects seven potential "
            "reward definitions; loaded {}.",
            _potentialRewards.size());

        return false;
    }

    constexpr uint32 expected[] =
    {
        97884,
        1297307,
        1297308,
        1278049,
        1278048,
        97886,
        97885
    };

    for (std::size_t index = 0;
        index <
            _potentialRewards.size();
        ++index)
    {
        if (_potentialRewards[index]
                .DisplayOrder !=
                index + 1 ||
            _potentialRewards[index]
                .ItemEntry !=
                expected[index])
        {
            LOG_ERROR(
                LOG_FILTER,
                "Potential reward slot {} must preserve "
                "native item {}, but loaded order={} item={}.",
                index + 1,
                expected[index],
                uint32(
                    _potentialRewards[index]
                        .DisplayOrder),
                _potentialRewards[index]
                    .ItemEntry);

            return false;
        }
    }

    return true;
}

bool ManastormRewards::LoadTreasureKeeperRule()
{
    QueryResult result =
        WorldDatabase.Query(
            "SELECT "
            "creature_entry, base_chance_bp, "
            "chance_per_depth_bp, chance_per_kill_bp, "
            "max_chance_bp, bonus_cache_count, "
            "ability_case_item, talent_case_item, "
            "case_count, enabled "
            "FROM manastorm_treasure_keeper_rule "
            "WHERE rule_id = 1");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to load manastorm_treasure_keeper_rule. "
            "Apply 14_manastorm_rewards.sql.");

        return false;
    }

    Field* fields =
        result->Fetch();

    _treasureKeeper.CreatureEntry =
        fields[0].Get<uint32>();
    _treasureKeeper.BaseChanceBp =
        fields[1].Get<uint32>();
    _treasureKeeper.ChancePerDepthBp =
        fields[2].Get<uint32>();
    _treasureKeeper.ChancePerKillBp =
        fields[3].Get<uint32>();
    _treasureKeeper.MaxChanceBp =
        fields[4].Get<uint32>();
    _treasureKeeper.BonusCacheCount =
        fields[5].Get<uint32>();
    _treasureKeeper.AbilityCaseItem =
        fields[6].Get<uint32>();
    _treasureKeeper.TalentCaseItem =
        fields[7].Get<uint32>();
    _treasureKeeper.CaseCount =
        fields[8].Get<uint32>();
    _treasureKeeper.Enabled =
        fields[9].Get<uint8>() != 0;

    if (!_treasureKeeper.Enabled)
        return true;

    if (!_treasureKeeper.CreatureEntry ||
        !_treasureKeeper.MaxChanceBp ||
        _treasureKeeper.MaxChanceBp >
            BASIS_POINTS ||
        !sObjectMgr->GetCreatureTemplate(
            _treasureKeeper.CreatureEntry) ||
        (_treasureKeeper.AbilityCaseItem &&
            !sObjectMgr->GetItemTemplate(
                _treasureKeeper
                    .AbilityCaseItem)) ||
        (_treasureKeeper.TalentCaseItem &&
            !sObjectMgr->GetItemTemplate(
                _treasureKeeper
                    .TalentCaseItem)))
    {
        LOG_ERROR(
            LOG_FILTER,
            "Enabled Treasure Keeper reward rule is invalid.");

        return false;
    }

    return true;
}

bool ManastormRewards::ValidateCharacterSchema() const
{
    QueryResult result =
        CharacterDatabase.Query(
            "SELECT COUNT(*) "
            "FROM character_manastorm_reward_state "
            "WHERE guid = 0");

    if (!result)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Character reward table is missing. "
            "Apply 02_manastorm_rewards.sql to acore_characters.");

        return false;
    }

    if (!_completionRewards.empty() &&
        !CharacterDatabase.Query(
            "SELECT COUNT(*) FROM character_manastorm_completion_reward_state WHERE guid = 0"))
    {
        LOG_ERROR(LOG_FILTER,
            "Optional completion reward state is missing. Apply 03_manastorm_completion_rewards.sql.");
        return false;
    }

    if (!CharacterDatabase.Query(
        "SELECT COUNT(*) FROM character_manastorm_pending_currency WHERE guid = 0"))
    {
        LOG_ERROR(LOG_FILTER, "Apply 04_manastorm_pending_currency.sql to acore_characters.");
        return false;
    }

    return true;
}

bool ManastormRewards::LoadState(
    ObjectGuid::LowType characterGuid,
    ManastormMode mode,
    bool endgame,
    ManastormRewardStateSnapshot& snapshot,
    std::string& error) const
{
    snapshot = {};
    error.clear();

    if (!_loaded)
    {
        error =
            "Manastorm reward policy is not loaded.";

        return false;
    }

    QueryResult result =
        CharacterDatabase.Query(
            "SELECT "
            "cache_chance_pct, "
            "bedlam_remainder_bp, "
            "bonzo_remainder_bp, "
            "caches_earned, "
            "bedlam_earned, "
            "bonzo_earned "
            "FROM character_manastorm_reward_state "
            "WHERE guid = {} "
            "AND mode = {} "
            "AND track = {} "
            "LIMIT 1",
            characterGuid,
            uint32(uint8(mode)),
            uint32(
                TrackBit(endgame)));

    if (!result)
        return true;

    Field* fields =
        result->Fetch();

    snapshot.CacheChancePct =
        std::min<uint32>(
            100,
            fields[0].Get<uint32>());

    snapshot.BedlamRemainderBp =
        fields[1].Get<uint32>() %
            BASIS_POINTS;

    snapshot.BonzoRemainderBp =
        fields[2].Get<uint32>() %
            BASIS_POINTS;

    snapshot.CachesEarned =
        fields[3].Get<uint32>();

    snapshot.BedlamEarned =
        fields[4].Get<uint64>();

    snapshot.BonzoEarned =
        fields[5].Get<uint64>();

    return true;
}

uint32 ManastormRewards::CalculateBaseAmount(
    RewardRule const& rule,
    uint32 depth) const
{
    if (!depth)
        return 0;

    // Case bands advance at 50, 100, ...; existing currency bands start at 1.
    uint64 const stepDepth = rule.Key == "CASE" ? uint64(depth) : uint64(depth - 1);
    uint64 const steps =
        stepDepth /
        uint64(rule.DepthStep);

    uint64 const amount =
        uint64(rule.BaseAmount) +
        steps *
            uint64(
                rule.AmountPerStep);

    return amount >
        std::numeric_limits<uint32>::max()
        ? std::numeric_limits<uint32>::max()
        : uint32(amount);
}

uint32 ManastormRewards::ScaleCurrencyAmount(
    uint32 baseAmount,
    RewardRule const& rule,
    double groupMultiplier,
    double segmentMultiplier,
    uint32 previousRemainderBp,
    uint32& nextRemainderBp) const
{
    nextRemainderBp =
        previousRemainderBp %
        BASIS_POINTS;

    if (!baseAmount)
        return 0;

    long double multiplier = 1.0L;

    if (rule.ApplyGroupMultiplier)
    {
        multiplier *=
            static_cast<long double>(
                std::max(
                    0.0,
                    groupMultiplier));
    }

    if (rule.ApplySegmentMultiplier)
    {
        multiplier *=
            static_cast<long double>(
                std::max(
                    0.0,
                    segmentMultiplier));
    }

    long double const rawBasisPoints =
        static_cast<long double>(
            baseAmount) *
        multiplier *
        static_cast<long double>(
            BASIS_POINTS) +
        static_cast<long double>(
            nextRemainderBp);

    if (!std::isfinite(
            static_cast<double>(
                rawBasisPoints)) ||
        rawBasisPoints <= 0.0L)
    {
        nextRemainderBp = 0;
        return 0;
    }

    long double const capped =
        std::min<long double>(
            rawBasisPoints,
            static_cast<long double>(
                std::numeric_limits<
                    uint64>::max()));

    uint64 const scaledBasisPoints =
        static_cast<uint64>(
            std::floor(
                capped + 0.5L));

    uint64 const award =
        scaledBasisPoints /
        BASIS_POINTS;

    nextRemainderBp =
        uint32(
            scaledBasisPoints %
            BASIS_POINTS);

    return award >
        std::numeric_limits<uint32>::max()
        ? std::numeric_limits<uint32>::max()
        : uint32(award);
}

double ManastormRewards::GetGroupRewardMultiplier(
    uint32 memberCount) const
{
    memberCount =
        std::clamp<uint32>(
            memberCount,
            1,
            ManastormLimits::MaxMembers);

    for (GroupRewardRange const& range :
        _groupRewardRanges)
    {
        if (memberCount >=
                range.MinMembers &&
            memberCount <=
                range.MaxMembers)
        {
            return range.Multiplier;
        }
    }

    return 1.0;
}

bool ManastormRewards::PrepareStageCompletion(
    ManastormRun const& run,
    CharacterDatabaseTransaction const& transaction,
    std::vector<std::shared_ptr<ManastormRewardPublication>>& publications,
    std::string& error) const
{
    publications.clear();
    error.clear();

    if (!_loaded ||
        !transaction)
    {
        error =
            "Manastorm reward backend is not ready.";

        return false;
    }

    double const groupMultiplier =
        GetGroupRewardMultiplier(
            uint32(
                run.GetMembers()
                    .size()));

    ManastormSegment const& segment =
        run.GetSegment();

    double segmentMultiplier =
        double(
            segment.RewardMultiplier);

    //
    // Native Mode 2 must pay the same stage/map reward percentage that the
    // untouched Ascension client derives from Manastorm.dbc:
    //
    //     max(endReward, encounterReward)
    //
    // SQL reward_multiplier remains the reconstructed/custom-mode authority,
    // but it must never silently override the original DBC presentation in
    // native mode.
    //
    if (ManastormModuleConfig::
        IsNativeClientMode())
    {
        double const nativeEnd =
            double(
                segment
                    .NativeRewardEndMultiplier);

        double const nativeEncounter =
            double(
                segment
                    .NativeRewardEncounterMultiplier);

        double const nativeMultiplier =
            std::max(
                nativeEnd,
                nativeEncounter);

        if (!std::isfinite(
                nativeMultiplier) ||
            nativeMultiplier <= 0.0)
        {
            error =
                "Native Manastorm reward multiplier is invalid "
                "for the active segment.";

            LOG_ERROR(
                LOG_FILTER,
                "Cannot prepare native Manastorm rewards for segment {}: "
                "DBC endMultiplier={} encounterMultiplier={}.",
                segment.SegmentId,
                nativeEnd,
                nativeEncounter);

            publications.clear();
            return false;
        }

        if (std::fabs(
                nativeMultiplier -
                segmentMultiplier) >
            0.0001)
        {
            LOG_WARN(
                LOG_FILTER,
                "Native Manastorm segment {} reward multiplier mismatch: "
                "DBC={:.4f} SQL={:.4f}. Native DBC value is authoritative "
                "for payout in ClientMode=2.",
                segment.SegmentId,
                nativeMultiplier,
                segmentMultiplier);
        }

        segmentMultiplier =
            nativeMultiplier;
    }

    uint8 const track =
        TrackBit(
            run.IsEndgame());

    for (ObjectGuid::LowType characterGuid :
        run.GetMembers())
    {
        Player* player =
            ObjectAccessor::FindConnectedPlayer(
                ObjectGuid::Create<
                    HighGuid::Player>(
                        characterGuid));

        // Reward persistence is character-owned, not connection-owned.
        // A member may disconnect after participating in the completed stage;
        // their durable reward mail must still be prepared atomically with
        // progression. Online players merely provide richer item creation
        // context and receive the post-commit inventory fast path.
        ManastormRewardStateSnapshot state;

        if (!LoadState(
            characterGuid,
            run.GetMode(),
            run.IsEndgame(),
            state,
            error))
        {
            publications.clear();
            return false;
        }

        QueryResult completed =
            CharacterDatabase.Query(
                "SELECT 1 "
                "FROM character_manastorm_completed_depth "
                "WHERE guid = {} "
                "AND mode = {} "
                "AND track = {} "
                "AND depth = {} "
                "LIMIT 1",
                characterGuid,
                uint32(
                    uint8(
                        run.GetMode())),
                uint32(track),
                run.GetDepth());

        bool const firstClear =
            !completed;
        bool const wildcard = (GetActiveGameModeMask(characterGuid) & GAME_MODE_WILDCARD) != 0;

        bool const wonNormalCache =
            state.CacheChancePct >= 100 ||
            (state.CacheChancePct > 0 &&
                urand(1, 100) <=
                    state.CacheChancePct);

        uint32 const nextCacheChance =
            wonNormalCache
            ? 0
            : std::min<uint32>(
                100,
                state.CacheChancePct +
                    CACHE_PITY_STEP_PCT);

        uint32 nextBedlamRemainder =
            state.BedlamRemainderBp;

        uint32 nextBonzoRemainder =
            state.BonzoRemainderBp;

        uint32 bedlam = 0;

        if (firstClear)
        {
            bedlam =
                ScaleCurrencyAmount(
                    CalculateBaseAmount(
                        _bedlam,
                        run.GetDepth()),
                    _bedlam,
                    groupMultiplier,
                    segmentMultiplier,
                    state.BedlamRemainderBp,
                    nextBedlamRemainder);
        }

        uint32 const bonzo =
            ScaleCurrencyAmount(
                CalculateBaseAmount(
                    _bonzo,
                    run.GetDepth()),
                _bonzo,
                groupMultiplier,
                segmentMultiplier,
                state.BonzoRemainderBp,
                nextBonzoRemainder);

        uint32 const cacheCount =
            SaturatingAdd(
                wonNormalCache
                    ? 1u
                    : 0u,
                run.GetBonusCacheCount());

        uint32 cacheItemEntry = 0;

        if (cacheCount)
        {
            uint32 playerLevel =
                player
                ? uint32(
                    player->GetLevel())
                : 0;

            if (!run.IsEndgame() &&
                !playerLevel)
            {
                QueryResult levelResult =
                    CharacterDatabase.Query(
                        "SELECT level "
                        "FROM characters "
                        "WHERE guid = {} "
                        "LIMIT 1",
                        characterGuid);

                if (levelResult)
                {
                    playerLevel =
                        uint32(
                            levelResult->
                                Fetch()[0]
                                .Get<uint8>());
                }
            }

            if (!ResolveCacheItemEntry(
                    run.IsEndgame(),
                    run.GetDepth(),
                    playerLevel,
                    cacheItemEntry,
                    characterGuid,
                    uint8(run.GetMode()),
                    run.GetDepth()))
            {
                error =
                    "No enabled Manastorm cache bracket matches "
                    "track=" +
                    std::to_string(
                        uint32(track)) +
                    " depth=" +
                    std::to_string(
                        run.GetDepth()) +
                    " level=" +
                    std::to_string(
                        playerLevel) +
                    ".";

                LOG_ERROR(
                    LOG_FILTER,
                    "Cannot resolve physical Manastorm cache for "
                    "character {}: track={} depth={} level={}.",
                    characterGuid,
                    uint32(track),
                    run.GetDepth(),
                    playerLevel);

                publications.clear();
                return false;
            }
        }

        uint64 const nextBedlamEarned =
            SaturatingAdd(
                state.BedlamEarned,
                bedlam);

        uint64 const nextBonzoEarned =
            SaturatingAdd(
                state.BonzoEarned,
                bonzo);

        uint32 const nextCachesEarned =
            SaturatingAdd(
                state.CachesEarned,
                cacheCount);

        transaction->Append(
            "INSERT INTO "
            "character_manastorm_reward_state "
            "(guid, mode, track, "
            "cache_chance_pct, "
            "bedlam_remainder_bp, "
            "bonzo_remainder_bp, "
            "caches_earned, "
            "bedlam_earned, "
            "bonzo_earned) "
            "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}) "
            "ON DUPLICATE KEY UPDATE "
            "cache_chance_pct = VALUES(cache_chance_pct), "
            "bedlam_remainder_bp = VALUES(bedlam_remainder_bp), "
            "bonzo_remainder_bp = VALUES(bonzo_remainder_bp), "
            "caches_earned = VALUES(caches_earned), "
            "bedlam_earned = VALUES(bedlam_earned), "
            "bonzo_earned = VALUES(bonzo_earned), "
            "updated_at = CURRENT_TIMESTAMP",
            characterGuid,
            uint32(
                uint8(
                    run.GetMode())),
            uint32(track),
            nextCacheChance,
            nextBedlamRemainder,
            nextBonzoRemainder,
            nextCachesEarned,
            nextBedlamEarned,
            nextBonzoEarned);

        std::vector<
            std::pair<uint32, uint32>>
            stacks;

        auto appendQuantity =
            [&stacks, &error](
                uint32 entry,
                uint32 quantity) -> bool
            {
                if (!entry ||
                    !quantity)
                {
                    return true;
                }

                ItemTemplate const* itemTemplate =
                    sObjectMgr->
                        GetItemTemplate(
                            entry);

                if (!itemTemplate)
                {
                    error =
                        "A configured Manastorm reward item "
                        "does not exist in item_template.";

                    return false;
                }

                uint32 const maxStack =
                    std::max<uint32>(
                        1,
                        itemTemplate->
                            GetMaxStackSize());

                uint32 remaining =
                    quantity;

                while (remaining)
                {
                    uint32 const count =
                        std::min(
                            remaining,
                            maxStack);

                    stacks.emplace_back(
                        entry,
                        count);

                    remaining -=
                        count;
                }

                return true;
            };

        auto deferCurrency = [&transaction, characterGuid](uint32 entry, uint32 quantity)
        {
            if (quantity)
                transaction->Append(
                    "INSERT INTO character_manastorm_pending_currency (guid, item_entry, quantity) "
                    "VALUES ({}, {}, {}) ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)",
                    characterGuid, entry, quantity);
        };

        deferCurrency(_bonzo.ItemEntry, bonzo);
        deferCurrency(_bedlam.ItemEntry, bedlam);

        if (!appendQuantity(
                cacheItemEntry,
                cacheCount) ||
            !appendQuantity(
                _treasureKeeper
                    .AbilityCaseItem,
                wildcard ? run.GetBonusAbilityCaseCount() : 0u) ||
            !appendQuantity(
                _treasureKeeper
                    .TalentCaseItem,
                wildcard ? run.GetBonusTalentCaseCount() : 0u))
        {
            publications.clear();
            return false;
        }

        // Optional completion rewards share the existing durable mail transaction.
        // Preserve fractional multipliers independently for every mode and track.
        for (RewardRule const& rule : _completionRewards)
        {
            if ((rule.WildcardOnly && !wildcard) ||
                (rule.NonWildcardOnly && wildcard) ||
                (rule.FirstClearOnly && !firstClear) ||
                (rule.EndgameOnly && track != TrackBit(true)))
                continue;

            uint32 previousRemainder = 0;
            uint64 earned = 0;
            auto* selectState = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_COMPLETION_REWARD);
            selectState->SetData(0, characterGuid);
            selectState->SetData(1, uint8(run.GetMode()));
            selectState->SetData(2, track);
            selectState->SetData(3, rule.Key);
            PreparedQueryResult optionalState = CharacterDatabase.Query(selectState);
            if (optionalState)
            {
                Field* optionalFields = optionalState->Fetch();
                previousRemainder = optionalFields[0].Get<uint32>() % BASIS_POINTS;
                earned = optionalFields[1].Get<uint64>();
            }

            uint32 nextRemainder = previousRemainder;
            uint32 const quantity = ScaleCurrencyAmount(
                CalculateBaseAmount(rule, run.GetDepth()), rule,
                groupMultiplier, segmentMultiplier, previousRemainder, nextRemainder);
            uint32 const itemEntry = rule.Key == "CASE"
                ? (urand(0, 1) == 0 ? rule.ItemEntry : 1278048)
                : rule.ItemEntry;
            if (rule.Key == "MARKS" || rule.Key == "MARKS_FIRST")
                deferCurrency(itemEntry, quantity);
            else if (!appendQuantity(itemEntry, quantity))
            {
                publications.clear();
                return false;
            }

            auto* saveState = CharacterDatabase.GetPreparedStatement(CHAR_REP_MANASTORM_COMPLETION_REWARD);
            saveState->SetData(0, characterGuid);
            saveState->SetData(1, uint8(run.GetMode()));
            saveState->SetData(2, track);
            saveState->SetData(3, rule.Key);
            saveState->SetData(4, nextRemainder);
            saveState->SetData(5, SaturatingAdd(earned, quantity));
            transaction->Append(saveState);
        }

        if (!PrepareItemDelivery(characterGuid, stacks, transaction, publications, error,
            "Manastorm: level " + std::to_string(run.GetDepth())))
            return false;

        LOG_INFO(
            LOG_FILTER,
            "Prepared Manastorm rewards: character={} depth={} "
            "mode={} track={} firstClear={} bedlam={} bonzo={} "
            "normalCache={} bonusCaches={} abilityCases={} "
            "talentCases={} cacheChance={} -> {} "
            "groupMultiplier={:.3f} segmentMultiplier={:.3f}.",
            characterGuid,
            run.GetDepth(),
            ManastormModeName(
                run.GetMode()),
            uint32(track),
            firstClear,
            bedlam,
            bonzo,
            wonNormalCache,
            run.GetBonusCacheCount(),
            run.GetBonusAbilityCaseCount(),
            run.GetBonusTalentCaseCount(),
            state.CacheChancePct,
            nextCacheChance,
            groupMultiplier,
            segmentMultiplier);
    }

    return true;
}

bool ManastormRewards::PrepareItemDelivery(
    ObjectGuid::LowType characterGuid,
    std::vector<std::pair<uint32, uint32>> const& stacks,
    CharacterDatabaseTransaction const& transaction,
    std::vector<std::shared_ptr<ManastormRewardPublication>>& publications,
    std::string& error,
    std::string const& subject) const
{
    Player* itemOwner = ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(characterGuid));
    std::size_t stackIndex = 0;
    uint32 mailPart = 0;

    while (stackIndex <
        stacks.size())
    {
        ++mailPart;

        auto publication =
            std::make_shared<
                ManastormRewardPublication>();

        publication->CharacterGuid =
            characterGuid;

        Mail& mail =
            publication->MailData;

        mail.messageID =
            sObjectMgr->
                GenerateMailID();

        mail.messageType =
            MAIL_CREATURE;

        mail.stationery =
            MAIL_STATIONERY_DEFAULT;

        mail.mailTemplateId = 0;
        mail.sender =
            REWARD_MAIL_SENDER;
        mail.receiver =
            characterGuid;

        mail.subject = subject;

        if (mailPart > 1)
        {
            mail.subject +=
                " (" +
                std::to_string(
                    mailPart) +
                ")";
        }

        mail.body = "Rewards earned by completing Manastorm stages.";

        mail.deliver_time =
            GameTime::GetGameTime()
                .count();

        mail.expire_time =
            mail.deliver_time +
            30 * DAY;

        mail.money = 0;
        mail.COD = 0;
        mail.checked =
            MAIL_CHECK_MASK_HAS_BODY;

        mail.state =
            MAIL_STATE_UNCHANGED;

        uint32 attachmentCount = 0;

        while (stackIndex <
                stacks.size() &&
            attachmentCount <
                MAX_MAIL_ITEMS)
        {
            auto const [entry, count] =
                stacks[stackIndex++];

            std::unique_ptr<Item> item(
                Item::CreateItem(
                    entry,
                    count,
                    itemOwner));

            if (item)
            {
                item->SetOwnerGUID(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            characterGuid));
            }

            if (!item)
            {
                error =
                    "Unable to create a durable "
                    "Manastorm reward item.";

                publications.clear();
                return false;
            }

            item->SaveToDB(
                transaction);

            mail.AddItem(
                item->GetGUID()
                    .GetCounter(),
                entry);

            auto* attachment =
                CharacterDatabase
                    .GetPreparedStatement(
                        CHAR_INS_MAIL_ITEM);

            attachment->SetData(
                0,
                mail.messageID);

            attachment->SetData(
                1,
                item->GetGUID()
                    .GetCounter());

            attachment->SetData(
                2,
                characterGuid);

            transaction->Append(
                attachment);

            publication->Items
                .push_back(
                    std::move(
                        item));

            ++attachmentCount;
        }

        auto* statement =
            CharacterDatabase
                .GetPreparedStatement(
                    CHAR_INS_MAIL);

        statement->SetData(
            0,
            mail.messageID);
        statement->SetData(
            1,
            mail.messageType);
        statement->SetData(
            2,
            int8(
                mail.stationery));
        statement->SetData(
            3,
            mail.mailTemplateId);
        statement->SetData(
            4,
            mail.sender);
        statement->SetData(
            5,
            mail.receiver);
        statement->SetData(
            6,
            mail.subject);
        statement->SetData(
            7,
            mail.body);
        statement->SetData(
            8,
            true);
        statement->SetData(
            9,
            uint32(
                mail.expire_time));
        statement->SetData(
            10,
            uint32(
                mail.deliver_time));
        statement->SetData(
            11,
            mail.money);
        statement->SetData(
            12,
            mail.COD);
        statement->SetData(
            13,
            uint8(
                mail.checked));

        transaction->Append(
            statement);

        publications.push_back(
            publication);
    }

    return true;
}

bool ManastormRewards::SettlePendingCurrency(ObjectGuid::LowType characterGuid) const
{
    if (!_loaded)
        return false;

    QueryResult result = CharacterDatabase.Query(
        "SELECT item_entry, quantity FROM character_manastorm_pending_currency "
        "WHERE guid = {} ORDER BY item_entry", characterGuid);
    if (!result)
        return true;

    std::vector<std::pair<uint32, uint32>> stacks;
    do
    {
        Field* fields = result->Fetch();
        uint32 const entry = fields[0].Get<uint32>();
        uint64 remaining = fields[1].Get<uint64>();
        ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(entry);
        if (!itemTemplate)
        {
            LOG_ERROR(LOG_FILTER, "Cannot settle Manastorm currency item {} for {}.", entry, characterGuid);
            return false;
        }

        uint32 const maxStack = std::max<uint32>(1, itemTemplate->GetMaxStackSize());
        while (remaining)
        {
            uint32 const count = uint32(std::min<uint64>(remaining, maxStack));
            stacks.emplace_back(entry, count);
            remaining -= count;
        }
    }
    while (result->NextRow());

    auto transaction = CharacterDatabase.BeginTransaction();
    std::vector<std::shared_ptr<ManastormRewardPublication>> publications;
    std::string error;
    if (!PrepareItemDelivery(characterGuid, stacks, transaction, publications, error,
        "Manastorm: accumulated currency"))
    {
        LOG_ERROR(LOG_FILTER, "Manastorm settlement preparation failed for {}: {}.", characterGuid, error);
        return false;
    }

    // Publish only after both the payout and removal of the unpaid balance commit.
    // Manager calls are serialized on the world thread; retries see no paid rows.
    transaction->Append(
        "DELETE FROM character_manastorm_pending_currency WHERE guid = {}", characterGuid);
    if (!CharacterDatabase.AsyncCommitTransaction(transaction).m_future.get())
    {
        LOG_ERROR(LOG_FILTER, "Manastorm settlement commit failed for {}. Balance retained.", characterGuid);
        return false;
    }

    PublishCommitted(publications);
    return true;
}

void ManastormRewards::PublishCommitted(
    std::vector<std::shared_ptr<ManastormRewardPublication>>& publications) const
{
    for (std::shared_ptr<ManastormRewardPublication>& publication :
        publications)
    {
        if (!publication)
            continue;

        Player* player =
            ObjectAccessor::
                FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            publication->
                                CharacterGuid));

        //
        // The stage-completion transaction has already committed every reward
        // item into a durable mailbox escrow. This gives us a crash-safe source
        // of truth before we try to make the reward feel immediate.
        //
        // Preferred delivery:
        //   1. Move each attachment directly into the connected character's
        //      inventory when the whole attachment fits.
        //   2. Delete only that attachment's mail_items row and persist the
        //      inventory move.
        //   3. Keep any attachment that cannot fit in the already-committed
        //      reward mail as the overflow safeguard.
        //
        // If the member disconnected after the completion commit, leave the
        // durable reward mail untouched.
        //
        if (!player)
        {
            sMailMgr->OnMailSent(
                publication->
                    CharacterGuid);

            continue;
        }

        CharacterDatabaseTransaction
            inventoryTransaction =
                CharacterDatabase
                    .BeginTransaction();

        uint32 inventoryStacks = 0;
        uint32 mailedStacks = 0;

        for (std::unique_ptr<Item>& item :
            publication->Items)
        {
            if (!item)
                continue;

            ItemPosCountVec destination;

            InventoryResult const result =
                player->CanStoreItem(
                    NULL_BAG,
                    NULL_SLOT,
                    destination,
                    item.get(),
                    false);

            if (result != EQUIP_ERR_OK)
            {
                ++mailedStacks;
                continue;
            }

            ObjectGuid::LowType const
                itemGuid =
                    item->GetGUID()
                        .GetCounter();

            //
            // This item was durably written as a mail attachment by the
            // completion transaction. Remove only its escrow link now that the
            // core has proved there is room in the live character inventory.
            //
            publication->
                MailData
                    .RemoveItem(
                        itemGuid);

            auto* deleteMailItem =
                CharacterDatabase
                    .GetPreparedStatement(
                        CHAR_DEL_MAIL_ITEM);

            deleteMailItem->
                SetData(
                    0,
                    itemGuid);

            inventoryTransaction->
                Append(
                    deleteMailItem);

            //
            // Mirror the normal mailbox "Take Item" path. The item instance is
            // already durable, so mark it unchanged before moving it out of
            // mail storage and let SaveInventoryAndGoldToDB persist its exact
            // bag/slot placement in this follow-up transaction.
            //
            uint32 const deliveredEntry =
                item->GetEntry();

            uint32 const deliveredCount =
                item->GetCount();

            item->SetState(
                ITEM_UNCHANGED);

            player->
                MoveItemToInventory(
                    destination,
                    item.release(),
                    true);

            //
            // MoveItemToInventory performs the real inventory transfer, but it
            // does not send SMSG_ITEM_PUSH_RESULT. Ascension's native toast
            // system listens to the resulting CHAT_MSG_LOOT event, so notify
            // the client through AzerothCore's normal new-item path after the
            // reward has actually reached the player's bags.
            //
            Item* notificationItem = nullptr;

            for (ItemPosCount const& position :
                destination)
            {
                Item* storedItem =
                    player->
                        GetItemByPos(
                            position.pos);

                if (storedItem &&
                    storedItem->GetEntry() ==
                        deliveredEntry)
                {
                    notificationItem =
                        storedItem;

                    break;
                }
            }

            if (notificationItem)
            {
                player->
                    SendNewItem(
                        notificationItem,
                        deliveredCount,
                        true,
                        false,
                        false,
                        true);
            }
            else
            {
                LOG_WARN(
                    LOG_FILTER,
                    "Manastorm delivered item {} x{} to character {} "
                    "but could not resolve the stored stack for the "
                    "native item-push notification.",
                    deliveredEntry,
                    deliveredCount,
                    publication->
                        CharacterGuid);
            }

            ++inventoryStacks;
        }

        if (inventoryStacks)
        {
            if (!publication->
                    MailData
                        .HasItems())
            {
                //
                // Everything fitted. Remove the temporary durable escrow mail
                // entirely; the character sees only the direct inventory
                // reward.
                //
                auto* deleteMail =
                    CharacterDatabase
                        .GetPreparedStatement(
                            CHAR_DEL_MAIL_BY_ID);

                deleteMail->
                    SetData(
                        0,
                        publication->
                            MailData
                                .messageID);

                inventoryTransaction->
                    Append(
                        deleteMail);

                auto* deleteMailItems =
                    CharacterDatabase
                        .GetPreparedStatement(
                            CHAR_DEL_MAIL_ITEM_BY_ID);

                deleteMailItems->
                    SetData(
                        0,
                        publication->
                            MailData
                                .messageID);

                inventoryTransaction->
                    Append(
                        deleteMailItems);
            }

            player->
                SaveInventoryAndGoldToDB(
                    inventoryTransaction);

            CharacterDatabase
                .CommitTransaction(
                    inventoryTransaction);
        }

        if (publication->
                MailData
                    .HasItems())
        {
            //
            // At least one reward attachment did not fit. Keep only those
            // remaining attachments in the already-committed reward mail.
            //
            sMailMgr->OnMailSent(
                publication->
                    CharacterGuid);

            player->
                AddNewMailDeliverTime(
                    publication->
                        MailData
                            .deliver_time);

            player->
                AddMail(
                    new Mail(
                        publication->
                            MailData));

            for (std::unique_ptr<Item>& item :
                publication->Items)
            {
                if (item)
                {
                    player->
                        AddMItem(
                            item.release());
                }
            }

            player->SendNewMail();
        }

        LOG_INFO(
            LOG_FILTER,
            "Published Manastorm stage rewards: character={} "
            "inventoryStacks={} mailedOverflowStacks={}.",
            publication->
                CharacterGuid,
            inventoryStacks,
            mailedStacks);
    }

    publications.clear();
}

uint32 ManastormRewards::GetActiveGameModeMask(ObjectGuid::LowType characterGuid) const
{
    Player* player = ObjectAccessor::FindConnectedPlayer(
        ObjectGuid::Create<HighGuid::Player>(characterGuid));
    if (player)
        if (std::optional<uint32> mask = sScriptMgr->OnPlayerGetGameModeMask(player))
            return *mask;

    // Offline participants and login before the owner publishes 0x90B use
    // that owner's persistent character state. Do not infer mode from class IDs.
    QueryResult result = CharacterDatabase.Query(
        "SELECT gameMode FROM coa_character_gamemode WHERE guid = {} LIMIT 1", characterGuid);
    return result ? result->Fetch()[0].Get<uint32>() : 0;
}

std::vector<ManastormRewardVisibilityRecord>
ManastormRewards::BuildVisibilityRecords(ObjectGuid::LowType characterGuid) const
{
    bool const wildcard = (GetActiveGameModeMask(characterGuid) & GAME_MODE_WILDCARD) != 0;
    std::vector<
        ManastormRewardVisibilityRecord>
        records;

    records.reserve(
        _potentialRewards.size());

    for (PotentialReward const& reward :
        _potentialRewards)
    {
        ManastormRewardVisibilityRecord record;
        record.ItemEntry =
            reward.ItemEntry;

        // Native action values recovered from Extensions.dll:
        //   0 = NONE
        //   1 = HIDE
        //   2 = LOCKED_RATE_LIMIT_EXHAUSTED
        //
        // No reward rate-limit policy is being fabricated here.
        record.Action =
            reward.Enabled &&
                ((reward.ItemEntry != 1278049 && reward.ItemEntry != 1278048 &&
                  reward.ItemEntry != 97885 && reward.ItemEntry != 97886) || wildcard)
            ? 0
            : 1;

        records.push_back(
            record);
    }

    return records;
}

bool ManastormRewards::IsTreasureKeeperEntry(
    uint32 entry) const
{
    return _loaded &&
        _treasureKeeper.Enabled &&
        entry ==
            _treasureKeeper
                .CreatureEntry;
}

bool ManastormRewards::IsActiveTreasureKeeper(
    Creature const* creature,
    ManastormRun const& run) const
{
    return creature &&
        IsTreasureKeeperEntry(
            creature->GetEntry()) &&
        !run.GetTreasureKeeperGuid()
            .IsEmpty() &&
        run.GetTreasureKeeperGuid() ==
            creature->GetGUID();
}

bool ManastormRewards::TrySpawnTreasureKeeper(
    Creature* killedTrash,
    ManastormRun& run) const
{
    if (!_loaded ||
        !_treasureKeeper.Enabled ||
        !killedTrash ||
        run.GetState() !=
            ManastormRunState::Active ||
        run.TreasureKeeperSpawned() ||
        !run.IsStageCreature(
            killedTrash->GetGUID()))
    {
        return false;
    }

    uint32 const trashKills =
        run.IncrementTreasureTrashKills();

    uint64 const rawChance =
        uint64(
            _treasureKeeper
                .BaseChanceBp) +
        uint64(run.GetDepth()) *
            uint64(
                _treasureKeeper
                    .ChancePerDepthBp) +
        uint64(trashKills) *
            uint64(
                _treasureKeeper
                    .ChancePerKillBp);

    uint32 const chanceBp =
        uint32(
            std::min<uint64>(
                _treasureKeeper
                    .MaxChanceBp,
                rawChance));

    if (!chanceBp ||
        urand(1, BASIS_POINTS) >
            chanceBp)
    {
        return false;
    }

    Map* map =
        killedTrash->GetMap();

    if (!map)
        return false;

    run.SetTreasureKeeperSpawned(
        true);

    Position const position =
        killedTrash->
            GetFirstCollisionPosition(
                4.0f,
                frand(
                    0.0f,
                    TWO_PI));

    Creature* keeper =
        map->SummonCreature(
            _treasureKeeper
                .CreatureEntry,
            position);

    if (!keeper)
    {
        run.SetTreasureKeeperSpawned(
            false);

        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} rolled Treasure Keeper "
            "at depth {} but creature {} could not be summoned.",
            run.GetRunId(),
            run.GetDepth(),
            _treasureKeeper
                .CreatureEntry);

        return false;
    }

    run.SetTreasureKeeperGuid(
        keeper->GetGUID());

    keeper->SetImmuneToPC(false);
    keeper->SetImmuneToNPC(false);
    keeper->RemoveNpcFlag(UNIT_NPC_FLAG_BANKER);
    keeper->SetFaction(14);
    keeper->SetReactState(
        REACT_AGGRESSIVE);
    keeper->SetLootRewardDisabled(
        true);
    keeper->
        SetReputationRewardDisabled(
            true);
    keeper->SetLootMode(0);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} spawned Treasure Keeper {} after "
        "{} eligible trash kills at depth {} "
        "(chance={:.2f}%).",
        run.GetRunId(),
        keeper->GetGUID()
            .GetRawValue(),
        trashKills,
        run.GetDepth(),
        double(chanceBp) /
            100.0);

    return true;
}

void ManastormRewards::OnTreasureKeeperKilled(
    ManastormRun& run) const
{
    if (!_loaded ||
        !_treasureKeeper.Enabled)
    {
        return;
    }

    run.ClearTreasureKeeperGuid();

    run.AddBonusCaches(
        _treasureKeeper
            .BonusCacheCount);

    if (_treasureKeeper.CaseCount &&
        (_treasureKeeper.AbilityCaseItem ||
            _treasureKeeper
                .TalentCaseItem))
    {
        bool const ability =
            !_treasureKeeper
                .TalentCaseItem ||
            (_treasureKeeper
                .AbilityCaseItem &&
                urand(0, 1) == 0);

        if (ability)
        {
            run.AddBonusAbilityCases(
                _treasureKeeper
                    .CaseCount);
        }
        else
        {
            run.AddBonusTalentCases(
                _treasureKeeper
                    .CaseCount);
        }
    }

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} secured Treasure Keeper rewards: "
        "bonusCaches={} abilityCases={} talentCases={}.",
        run.GetRunId(),
        run.GetBonusCacheCount(),
        run.GetBonusAbilityCaseCount(),
        run.GetBonusTalentCaseCount());
}
