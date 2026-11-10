/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_CALLBOARD_CONTRACTS_POLICY_H
#define COA_ASCENSION_CALLBOARD_CONTRACTS_POLICY_H

#include "AscensionRaidReleasePolicy.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace CallboardContracts
{
constexpr std::uint16_t RequestViewOpcode = 0x055F;
constexpr std::uint16_t ActivateOpcode = 0x055B;
constexpr std::uint16_t ViewOpcode = 0x0589;
constexpr std::uint32_t BazaarToken = 975001;
constexpr std::int64_t DaySeconds = 86400;
constexpr std::int64_t DaysPerWeek = 7;
constexpr std::size_t MaxTypeNameLength = 64;
constexpr std::uint32_t PointsPerDisplayedPoint = 10;
constexpr std::uint32_t MaxMoneyCost = static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max());

struct ContentType
{
    std::string_view key;
    std::string_view name;
};

constexpr std::array<ContentType, 5> ContentTypes = {{
    { "PvE", "PvE" },
    { "PvP", "PvP" },
    { "Profession", "Professions" },
    { "HighRisk", "High-Risk" },
    { "Misc", "Miscellaneous" },
}};

inline bool IsContentType(std::string_view key)
{
    return std::any_of(ContentTypes.begin(), ContentTypes.end(),
        [key](ContentType const& type) { return type.key == key; });
}

inline std::uint32_t Saturate(std::uint64_t value)
{
    return static_cast<std::uint32_t>(std::min<std::uint64_t>(value, std::numeric_limits<std::uint32_t>::max()));
}

inline std::int64_t WeekStart(std::int64_t nextWeeklyReset)
{
    return nextWeeklyReset - DaysPerWeek * DaySeconds;
}

inline std::uint32_t DaysBegun(std::int64_t nextDailyReset, std::int64_t nextWeeklyReset)
{
    std::int64_t const untilWeekly = nextWeeklyReset - nextDailyReset;
    if (untilWeekly < 0)
        return DaysPerWeek;

    std::int64_t const days = DaysPerWeek - untilWeekly / DaySeconds;
    return static_cast<std::uint32_t>(std::clamp<std::int64_t>(days, 1, DaysPerWeek));
}

inline std::uint32_t Remaining(std::uint32_t daysBegun, std::uint32_t dailyCompletions, std::uint32_t done)
{
    std::uint64_t const earned = std::uint64_t(daysBegun) * dailyCompletions;
    return earned > done ? Saturate(earned - done) : 0;
}

inline std::uint32_t Spare(std::uint32_t remaining, std::uint32_t inLog)
{
    return remaining > inLog ? remaining - inLog : 0;
}

inline std::uint32_t ScaledCost(std::uint32_t reward, double multiplier, std::uint32_t minimum, std::uint32_t maximum)
{
    double const scaled = std::round(double(reward) * std::max(0.0, multiplier));
    std::uint32_t const value = scaled >= double(maximum) ? maximum : static_cast<std::uint32_t>(scaled);
    return std::clamp(value, std::clamp<std::uint32_t>(minimum, 1, maximum), maximum);
}

inline std::uint32_t MoneyCost(std::uint32_t rewardMoney, double multiplier, std::uint32_t minimum)
{
    return ScaledCost(rewardMoney, multiplier, minimum, MaxMoneyCost);
}

inline std::uint32_t TokenCost(std::uint32_t rewardTokens, double multiplier, std::uint32_t minimum)
{
    return ScaledCost(rewardTokens, multiplier, minimum, std::numeric_limits<std::uint32_t>::max());
}

inline std::uint32_t DisplayedCachePoints(std::uint32_t points)
{
    return (points + PointsPerDisplayedPoint - 1) / PointsPerDisplayedPoint;
}

inline bool IsValidTypeName(std::string_view name)
{
    return !name.empty() && name.size() <= MaxTypeNameLength && std::all_of(name.begin(), name.end(),
        [](char c) { return std::isalnum(static_cast<unsigned char>(c)) != 0; });
}

struct StagedContract
{
    std::string_view type;
    std::uint32_t stage;
};

constexpr std::array<StagedContract, 2> StagedContracts = {{
    { "VanillaHeroicDungeonCrawling", RaidRelease::StageHeroicDungeons },
    { "VanillaMythicDungeonCrawling", RaidRelease::StageMythicDungeons },
}};

[[nodiscard]] constexpr std::uint32_t RequiredReleaseStage(std::string_view type)
{
    for (StagedContract const& staged : StagedContracts)
        if (staged.type == type)
            return staged.stage;
    return 0;
}

[[nodiscard]] constexpr bool IsContractReleased(std::string_view type, std::uint32_t releasedStage)
{
    return RequiredReleaseStage(type) <= releasedStage;
}

inline std::string DisplayName(std::string_view type)
{
    std::string name;
    for (std::size_t i = 0; i < type.size(); ++i)
    {
        unsigned char const c = static_cast<unsigned char>(type[i]);
        if (i && !name.empty() && name.back() != ' ')
        {
            unsigned char const previous = static_cast<unsigned char>(type[i - 1]);
            bool const next = i + 1 < type.size() && std::islower(static_cast<unsigned char>(type[i + 1]));
            bool const wordStart = std::isupper(c) && (std::islower(previous) || std::isdigit(previous)
                || (std::isupper(previous) && next));
            bool const numberStart = std::isdigit(c) && std::isalpha(previous);
            if (wordStart || numberStart)
                name.push_back(' ');
        }
        name.push_back(static_cast<char>(c));
    }
    return name;
}

struct RewardItem
{
    std::uint32_t itemId = 0;
    std::uint32_t amount = 0;
};

struct Reward
{
    std::uint32_t money = 0;
    std::uint32_t honor = 0;
    std::uint32_t arenaPoints = 0;
    std::uint32_t cachePoints = 0;
    std::vector<RewardItem> items;

    [[nodiscard]] std::uint32_t ItemAmount(std::uint32_t itemId) const
    {
        std::uint64_t amount = 0;
        for (RewardItem const& item : items)
            if (item.itemId == itemId)
                amount += item.amount;
        return Saturate(amount);
    }
};

struct SubCategory
{
    std::string type;
    std::string name;
    std::uint32_t remaining = 0;
    std::uint32_t moneyCost = 1;
    std::uint32_t tokenCost = 1;
    std::uint32_t minimumLevel = 0;
    Reward reward;
};

struct Category
{
    std::string contentType;
    std::string name;
    std::vector<SubCategory> subCategories;
};

struct CategoryTotal
{
    std::uint32_t remaining = 0;
    std::uint32_t moneyCost = 1;
    std::uint32_t tokenCost = 1;
    Reward reward;
};

inline CategoryTotal Summarize(Category const& category)
{
    std::uint64_t remaining = 0;
    std::uint64_t money = 0;
    std::uint64_t tokens = 0;
    std::uint64_t rewardMoney = 0;
    std::uint64_t honor = 0;
    std::uint64_t arena = 0;
    std::uint64_t cache = 0;
    std::vector<std::pair<std::uint32_t, std::uint64_t>> items;
    for (SubCategory const& sub : category.subCategories)
    {
        std::uint64_t const times = sub.remaining;
        remaining += times;
        money += times * sub.moneyCost;
        tokens += times * sub.tokenCost;
        rewardMoney += times * sub.reward.money;
        honor += times * sub.reward.honor;
        arena += times * sub.reward.arenaPoints;
        cache += times * sub.reward.cachePoints;
        if (!times)
            continue;

        for (RewardItem const& item : sub.reward.items)
        {
            auto found = std::find_if(items.begin(), items.end(),
                [&item](auto const& entry) { return entry.first == item.itemId; });
            if (found == items.end())
                items.emplace_back(item.itemId, times * item.amount);
            else
                found->second += times * item.amount;
        }
    }

    CategoryTotal total;
    total.remaining = Saturate(remaining);
    total.moneyCost = std::max<std::uint32_t>(1, Saturate(money));
    total.tokenCost = std::max<std::uint32_t>(1, Saturate(tokens));
    total.reward.money = Saturate(rewardMoney);
    total.reward.honor = Saturate(honor);
    total.reward.arenaPoints = Saturate(arena);
    total.reward.cachePoints = Saturate(cache);
    for (auto const& [itemId, amount] : items)
        total.reward.items.push_back({ itemId, Saturate(amount) });
    return total;
}

class Writer
{
public:
    void U32(std::uint32_t value)
    {
        for (int shift = 0; shift < 32; shift += 8)
            _bytes.push_back(static_cast<std::uint8_t>(value >> shift));
    }

    void CString(std::string_view text)
    {
        _bytes.insert(_bytes.end(), text.begin(), text.end());
        _bytes.push_back(0);
    }

    void Rewards(Reward const& reward)
    {
        U32(reward.money);
        U32(reward.honor);
        U32(reward.arenaPoints);
        U32(reward.cachePoints);
        U32(static_cast<std::uint32_t>(reward.items.size()));
        for (RewardItem const& item : reward.items)
        {
            U32(item.itemId);
            U32(item.amount);
        }
    }

    [[nodiscard]] std::vector<std::uint8_t> Take() { return std::move(_bytes); }

private:
    std::vector<std::uint8_t> _bytes;
};

inline std::vector<std::uint8_t> SerializeView(std::vector<Category> const& categories)
{
    Writer out;
    out.U32(static_cast<std::uint32_t>(categories.size()));
    for (Category const& category : categories)
    {
        CategoryTotal const total = Summarize(category);
        out.CString(category.contentType);
        out.CString(category.name);
        out.U32(total.remaining);
        out.U32(total.moneyCost);
        out.U32(total.tokenCost);
        out.Rewards(total.reward);
        out.U32(static_cast<std::uint32_t>(category.subCategories.size()));
        for (SubCategory const& sub : category.subCategories)
        {
            out.CString(sub.type);
            out.CString(sub.name);
            out.U32(sub.remaining);
            out.U32(std::max<std::uint32_t>(1, sub.moneyCost));
            out.U32(std::max<std::uint32_t>(1, sub.tokenCost));
            out.U32(sub.minimumLevel);
            out.Rewards(sub.reward);
        }
    }
    return out.Take();
}

struct Activation
{
    std::string type;
    bool payWithGold = false;
    std::uint32_t count = 0;

    [[nodiscard]] std::uint32_t Completions() const { return std::max<std::uint32_t>(1, count); }
};

inline std::uint32_t ReadU32(std::uint8_t const* data)
{
    return std::uint32_t(data[0]) | std::uint32_t(data[1]) << 8 | std::uint32_t(data[2]) << 16
        | std::uint32_t(data[3]) << 24;
}

inline std::optional<Activation> ParseActivation(std::uint8_t const* data, std::size_t size)
{
    if (!data || size < sizeof(std::uint32_t))
        return std::nullopt;

    std::uint32_t const length = ReadU32(data);
    if (length > MaxTypeNameLength || size < sizeof(std::uint32_t) + length + 1 + sizeof(std::uint32_t))
        return std::nullopt;

    Activation activation;
    activation.type.assign(reinterpret_cast<char const*>(data + sizeof(std::uint32_t)), length);
    if (!IsValidTypeName(activation.type))
        return std::nullopt;

    std::uint8_t const* tail = data + sizeof(std::uint32_t) + length;
    activation.payWithGold = tail[0] != 0;
    activation.count = ReadU32(tail + 1);
    return activation;
}

template <typename Packet>
std::optional<Activation> ParseActivationPacket(Packet const& packet)
{
    if (packet.empty())
        return std::nullopt;

    return ParseActivation(packet.contents(), packet.size());
}

struct Requests
{
    bool view = false;
    std::vector<Activation> activations;
};

class PendingRequests
{
public:
    using Clock = std::chrono::steady_clock;
    static constexpr std::size_t MaxActivationsPerAccount = 64;
    static constexpr std::chrono::seconds MaxAge{30};

    void RequestView(std::uint32_t accountId, Clock::time_point now)
    {
        std::lock_guard lock(_mutex);
        Requests& requests = EntryFor(accountId, now).requests;
        if (requests.view)
            return;

        requests.view = true;
        _pending.fetch_add(1, std::memory_order_release);
    }

    bool Activate(std::uint32_t accountId, Activation activation, Clock::time_point now)
    {
        std::lock_guard lock(_mutex);
        Requests& requests = EntryFor(accountId, now).requests;
        if (requests.activations.size() >= MaxActivationsPerAccount)
            return false;

        requests.activations.push_back(std::move(activation));
        _pending.fetch_add(1, std::memory_order_release);
        return true;
    }

    [[nodiscard]] Requests Take(std::uint32_t accountId, Clock::time_point now)
    {
        if (!_pending.load(std::memory_order_acquire))
            return {};

        std::lock_guard lock(_mutex);
        auto const found = _requests.find(accountId);
        if (found == _requests.end())
            return {};

        Entry entry = std::move(found->second);
        _requests.erase(found);
        _pending.fetch_sub(Count(entry.requests), std::memory_order_release);
        return Expired(entry, now) ? Requests{} : std::move(entry.requests);
    }

    void DropExpired(Clock::time_point now)
    {
        if (!_pending.load(std::memory_order_acquire))
            return;

        std::lock_guard lock(_mutex);
        for (auto entry = _requests.begin(); entry != _requests.end();)
        {
            if (!Expired(entry->second, now))
            {
                ++entry;
                continue;
            }

            _pending.fetch_sub(Count(entry->second.requests), std::memory_order_release);
            entry = _requests.erase(entry);
        }
    }

    [[nodiscard]] std::size_t Size() const { return _pending.load(std::memory_order_acquire); }

private:
    struct Entry
    {
        Requests requests;
        Clock::time_point queuedAt;
    };

    static std::size_t Count(Requests const& requests)
    {
        return requests.activations.size() + (requests.view ? 1 : 0);
    }

    static bool Expired(Entry const& entry, Clock::time_point now) { return now - entry.queuedAt > MaxAge; }

    Entry& EntryFor(std::uint32_t accountId, Clock::time_point now)
    {
        auto [found, inserted] = _requests.try_emplace(accountId);
        if (inserted)
            found->second.queuedAt = now;
        return found->second;
    }

    std::mutex _mutex;
    std::unordered_map<std::uint32_t, Entry> _requests;
    std::atomic<std::size_t> _pending{0};
};

class WeekLedger
{
public:
    void Roll(std::int64_t weekStart)
    {
        if (weekStart == _weekStart)
            return;

        _weekStart = weekStart;
        _completions.clear();
    }

    void Set(std::string const& type, std::uint32_t completions) { _completions[type] = completions; }

    std::uint32_t Add(std::string const& type)
    {
        std::uint32_t& completions = _completions[type];
        if (completions < std::numeric_limits<std::uint32_t>::max())
            ++completions;
        return completions;
    }

    [[nodiscard]] std::uint32_t Completions(std::string const& type, std::int64_t weekStart) const
    {
        if (weekStart != _weekStart)
            return 0;

        auto const found = _completions.find(type);
        return found == _completions.end() ? 0 : found->second;
    }

    void Merge(WeekLedger const& stored)
    {
        if (stored._weekStart != _weekStart)
            return;

        for (auto const& [type, completions] : stored._completions)
        {
            std::uint32_t& current = _completions[type];
            current = Saturate(std::uint64_t(current) + completions);
        }
    }

    [[nodiscard]] std::vector<std::string> Types() const
    {
        std::vector<std::string> types;
        types.reserve(_completions.size());
        for (auto const& entry : _completions)
            types.push_back(entry.first);
        return types;
    }

    [[nodiscard]] std::int64_t WeekStartTime() const { return _weekStart; }

private:
    std::int64_t _weekStart = std::numeric_limits<std::int64_t>::min();
    std::unordered_map<std::string, std::uint32_t> _completions;
};
}

#endif
