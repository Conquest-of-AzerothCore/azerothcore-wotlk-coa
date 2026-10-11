/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_WARCRAFT_REBORN_RULES_H
#define ASCENSION_WARCRAFT_REBORN_RULES_H

#include "AscensionFreepickRules.h"
#include <array>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace AscensionWarcraftReborn
{
constexpr std::uint32_t REBORN_SPELL_OFFSET = 1100000;
constexpr std::uint32_t REBORN_SKILL_OFFSET = 11000;
constexpr std::uint32_t ROW_ALTERNATE = 0x80000;
constexpr std::size_t REQUIRED_ABILITY_COUNT = 3;
constexpr std::uint32_t DARK_APOTHEOSIS = 1154321;
constexpr std::array<std::uint32_t, 2> DARK_APOTHEOSIS_PASSIVES = { 1154322, 1154323 };
constexpr std::array<std::uint32_t, 3> DARK_APOTHEOSIS_SPELLS = { 1159674, 1161363, 1161294 };

struct Grant
{
    std::uint32_t Source;
    std::vector<std::uint32_t> Spells;
};

std::vector<Grant> const& Grants();

struct Data
{
    AscensionFreepick::Catalog Catalog;
    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> Ladders;
    std::unordered_map<std::uint32_t, std::uint32_t> FirstRanks;
    std::unordered_set<std::uint32_t> Trainable;
    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> SkillLines;
    std::unordered_set<std::uint32_t> Automatic;

    [[nodiscard]] std::vector<std::uint32_t> const* LadderOf(std::uint32_t spellId) const;
};

bool LoadData(Data& data);

std::vector<std::vector<std::uint32_t>> RankChains(Data const& data);

std::vector<std::uint32_t> StartingSpells(Data const& data, AscensionFreepick::Realm const& realm,
    std::uint32_t classId, std::uint32_t level);
std::vector<std::uint32_t> ClassSkillLines(Data const& data, AscensionFreepick::Realm const& realm,
    std::uint32_t classId);
std::vector<std::uint32_t> AutomaticSpells(Data const& data, AscensionFreepick::Realm const& realm,
    std::uint32_t classId, std::uint32_t level);

struct TrainerSpell
{
    std::uint32_t SpellId = 0;
    std::uint32_t MoneyCost = 0;
    std::uint32_t ReqSkillLine = 0;
    std::uint32_t ReqSkillRank = 0;
    std::array<std::uint32_t, REQUIRED_ABILITY_COUNT> ReqAbility{};
    std::uint32_t ReqLevel = 0;
};

using SpellExists = std::function<bool(std::uint32_t spellId)>;
using RebornRow = std::function<TrainerSpell(std::uint32_t spellId)>;

std::uint32_t RebornSpell(std::uint32_t spellId, SpellExists const& exists);

struct SpellLayout
{
    std::string Name;
    std::array<std::uint32_t, 3> Effects{};
    std::array<std::uint32_t, 3> Auras{};

    bool operator==(SpellLayout const&) const = default;
};

using SpellLayoutOf = std::function<std::optional<SpellLayout>(std::uint32_t spellId)>;

std::vector<std::pair<std::uint32_t, std::uint32_t>> SpellTwins(std::uint32_t spellCount, SpellLayoutOf const& layout);

std::vector<std::pair<std::uint32_t, std::uint32_t>> SpellNamesakes(std::uint32_t spellCount, SpellLayoutOf const& layout);

using LaterRanks = std::function<std::vector<std::uint32_t>(std::uint32_t spellId)>;
using FirstRank = std::function<std::uint32_t(std::uint32_t spellId)>;

std::vector<std::pair<std::uint32_t, std::uint32_t>> RankTwins(std::vector<std::pair<std::uint32_t, std::uint32_t>> const& twins,
    LaterRanks const& laterRanks, FirstRank const& firstRank, SpellLayoutOf const& layout);

std::vector<TrainerSpell> TrainerSpells(Data const& data, AscensionFreepick::Realm const& realm, std::uint32_t classId,
    std::vector<TrainerSpell> const& stock, SpellExists const& exists, RebornRow const& reborn);
}

#endif
