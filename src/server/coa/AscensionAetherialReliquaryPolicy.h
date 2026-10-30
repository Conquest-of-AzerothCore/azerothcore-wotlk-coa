/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_AETHERIAL_RELIQUARY_POLICY_H
#define ASCENSION_AETHERIAL_RELIQUARY_POLICY_H

#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <string_view>

namespace AetherialReliquary
{
constexpr std::uint32_t ReliquaryItem = 8263512;
constexpr std::uint32_t RestoreSpell = 8263512;
constexpr std::string_view SettingSource = "core.coa_aetherial_reliquary";
constexpr std::string_view PersistentSettingPrefix = "core.";

static_assert(SettingSource.starts_with(PersistentSettingPrefix));
constexpr std::uint32_t MaxStoredDurationMs = std::numeric_limits<std::int32_t>::max();

enum class BuffKind
{
    Toggle,
    Timed
};

struct StorableBuff
{
    std::uint32_t spellId;
    BuffKind kind;
    std::uint32_t settingIndex;
};

constexpr std::array StorableBuffs = {
    StorableBuff{ 818059, BuffKind::Toggle, 0 },
    StorableBuff{ 818046, BuffKind::Timed, 1 },
};

struct StoredBuffs
{
    std::array<std::uint32_t, StorableBuffs.size()> values{};

    [[nodiscard]] constexpr bool Empty() const
    {
        for (std::uint32_t value : values)
            if (value)
                return false;
        return true;
    }

    constexpr bool operator==(StoredBuffs const&) const = default;
};

[[nodiscard]] constexpr std::uint32_t AddDuration(std::uint32_t held, std::uint32_t added)
{
    std::uint32_t const capped = held > MaxStoredDurationMs ? MaxStoredDurationMs : held;
    std::uint32_t const room = MaxStoredDurationMs - capped;
    return added > room ? MaxStoredDurationMs : capped + added;
}

[[nodiscard]] constexpr std::uint32_t MergeValue(BuffKind kind, std::uint32_t held, std::uint32_t added)
{
    if (kind == BuffKind::Toggle)
        return (held || added) ? 1u : 0u;
    return AddDuration(held, added);
}

[[nodiscard]] constexpr StoredBuffs Merge(StoredBuffs const& held, StoredBuffs const& added)
{
    StoredBuffs merged;
    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
        merged.values[i] = MergeValue(StorableBuffs[i].kind, held.values[i], added.values[i]);
    return merged;
}

[[nodiscard]] constexpr bool HasUniqueEntries()
{
    for (std::size_t i = 0; i < StorableBuffs.size(); ++i)
        for (std::size_t j = i + 1; j < StorableBuffs.size(); ++j)
            if (StorableBuffs[i].spellId == StorableBuffs[j].spellId ||
                StorableBuffs[i].settingIndex == StorableBuffs[j].settingIndex)
                return false;
    return true;
}

static_assert(HasUniqueEntries());
}

#endif
