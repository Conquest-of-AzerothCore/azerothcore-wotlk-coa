/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_FREEPICK_RULES_H
#define ASCENSION_FREEPICK_RULES_H

#include <array>
#include <cstdint>
#include <functional>
#include <string>
#include <unordered_map>
#include <vector>

namespace AscensionFreepick
{
constexpr std::uint32_t HERO_CLASS = 10;
constexpr std::size_t RANK_COUNT = 9;
constexpr std::size_t REQUIRED_COUNT = 3;
constexpr std::size_t CONNECTED_COUNT = 15;
constexpr std::size_t MASTERY_COUNT = 3;
constexpr std::size_t REALM_COUNT = 5;
constexpr std::uint32_t MARK_OF_ASCENSION_ITEM = 375250;

enum EntryType : std::uint32_t
{
    ENTRY_NONE,
    ENTRY_ABILITY,
    ENTRY_TALENT,
    ENTRY_TRAIT,
    ENTRY_TALENT_ABILITY,
    ENTRY_UNKNOWN
};

enum RowFlag : std::uint32_t
{
    ROW_DEPRECATED = 0x1,
    ROW_RETAINED = 0x2,
    ROW_DISABLED = 0x8,
    ROW_MASTERY = 0x1000,
    ROW_FREE_UNLEARN = 0x2000,
    ROW_DISPLAY = 0x20000,
    ROW_AUTOMATIC = 0x100000,
    ROW_CONNECTED_AT_MAX_RANK = 0x200000,
    ROW_MODE_RESTRICTED = 0x1800000
};

enum LearnResult : std::uint32_t
{
    LEARN_OK = 0,
    LEARN_BAD_ABILITY = 3,
    LEARN_DISPLAY_ENTRY = 4,
    LEARN_LOW_LEVEL = 5,
    LEARN_ALREADY_KNOWN = 6,
    LEARN_CONDITIONS_FAILED = 7,
    LEARN_NOT_IN_BATTLEGROUNDS = 8,
    LEARN_WRONG_EXPANSION = 9,
    LEARN_DISABLED = 10,
    LEARN_WRONG_CLASS = 11,
    LEARN_ALREADY_KNOW_A_STARTING_NODE = 12,
    LEARN_MISSING_CONNECTED_ENTRIES = 13,
    LEARN_MISSING_REQUIRED_ID = 14,
    LEARN_WRONG_REALM = 15,
    LEARN_NOT_IN_COMBAT = 16,
    LEARN_DEPRECATED = 17,
    LEARN_BUILD_CREATOR = 18,
    LEARN_INVULNERABLE = 19,
    LEARN_NO_TALENTS_CHALLENGE = 20,
    LEARN_NOT_WHILE_DEAD = 30,
    LEARN_GROUP = 37,
    LEARN_NOT_ENOUGH_INVESTED_AE = 38,
    LEARN_NOT_ENOUGH_INVESTED_TE = 39,
    LEARN_NOT_ENOUGH_INVESTED_POINTS = 40,
    LEARN_MISSING_AE = 41,
    LEARN_MISSING_TE = 42,
    LEARN_MODE_RESTRICTED = 43,
    LEARN_RESULT_COUNT = 45
};

extern std::array<char const*, LEARN_RESULT_COUNT> const LEARN_RESULTS;

enum UpdateResult : std::uint32_t
{
    UPDATE_OK,
    UPDATE_UNKNOWN,
    UPDATE_NO_BUILD,
    UPDATE_BAD_ENTRY,
    UPDATE_NO_DIFF,
    UPDATE_NOT_TRAVERSIBLE,
    UPDATE_BAD_UPDATE_COSTS,
    UPDATE_MISSING_TOKENS,
    UPDATE_RESULT_COUNT
};

extern std::array<char const*, UPDATE_RESULT_COUNT> const UPDATE_RESULTS;

struct Row
{
    std::uint32_t EntryId = 0;
    EntryType Type = ENTRY_UNKNOWN;
    std::array<std::uint32_t, REQUIRED_COUNT> Required{};
    std::array<std::uint32_t, RANK_COUNT> Spells{};
    std::uint32_t AECost = 0;
    std::uint32_t TECost = 0;
    std::uint32_t RequiredLevel = 0;
    std::uint32_t Group = 0;
    std::uint32_t ClassType = 0;
    std::uint32_t Tab = 0;
    std::uint32_t GlobalAEInvestment = 0;
    std::uint32_t GlobalTEInvestment = 0;
    std::uint32_t ClassAEInvestment = 0;
    std::uint32_t ClassTEInvestment = 0;
    std::uint32_t TabAEInvestment = 0;
    std::uint32_t TabTEInvestment = 0;
    std::uint32_t ClassPointValue = 0;
    std::uint32_t ClassPointInvestment = 0;
    bool StartingNode = false;
    std::array<std::uint32_t, CONNECTED_COUNT> Connected{};
    std::uint32_t Expansion = 0;
    std::uint32_t Flags = 0;
    std::array<bool, REALM_COUNT> Realms{};
    std::array<std::uint32_t, MASTERY_COUNT> Masteries{};
    std::string Name;

    [[nodiscard]] bool Has(RowFlag flag) const { return (Flags & flag) != 0; }
    [[nodiscard]] std::uint32_t MaxRank() const;
};

struct ClassType
{
    std::uint32_t Class = 0;
    bool Hero = false;
    bool ConquestOfAzeroth = false;
    bool Stock = false;
};

struct Essence
{
    std::uint32_t Level = 0;
    std::uint32_t AE = 0;
    std::uint32_t TE = 0;
};

struct Catalog
{
    std::unordered_map<std::uint32_t, Row> Rows;
    std::vector<std::uint32_t> RowOrder;
    std::unordered_map<std::uint32_t, ClassType> ClassTypes;
    std::unordered_map<std::uint32_t, std::vector<Essence>> Budget;

    [[nodiscard]] Row const* Find(std::uint32_t entryId) const;
};

bool LoadCatalog(Catalog& catalog);

struct Realm
{
    bool Live = false;
    bool Seasonal = false;
    bool League = false;
    bool Ptr = false;
    bool Development = false;
    bool ConquestOfAzeroth = false;
    bool WarcraftReborn = false;
    std::uint32_t Ruleset = 2;
};

bool Visible(Catalog const& catalog, Realm const& realm, Row const& row);
bool ClassAdmits(Catalog const& catalog, Row const& row, std::uint32_t classId);

struct Entry
{
    std::uint32_t EntryId = 0;
    std::uint32_t Rank = 0;
};

using UnitCheck = std::function<bool(std::uint32_t slot, Row const& row)>;

class Build
{
public:
    Build(Catalog const& catalog, Realm const& realm, std::uint32_t level, std::vector<Entry> entries = {},
        std::uint32_t classId = HERO_CLASS);

    [[nodiscard]] std::vector<Entry> const& Entries() const { return _entries; }
    [[nodiscard]] std::uint32_t Level() const { return _level; }
    [[nodiscard]] std::uint32_t Class() const { return _class; }
    [[nodiscard]] Catalog const& Data() const { return *_catalog; }

    [[nodiscard]] std::uint32_t RankOf(std::uint32_t entryId) const;
    [[nodiscard]] bool Has(std::uint32_t entryId) const;
    [[nodiscard]] bool HasGroup(std::uint32_t group, std::uint32_t exceptId) const;

    [[nodiscard]] std::uint32_t AEBudget() const;
    [[nodiscard]] std::uint32_t TEBudget() const;
    [[nodiscard]] std::uint32_t GlobalAE(std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t GlobalTE(std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t ClassAE(std::uint32_t classType, std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t ClassTE(std::uint32_t classType, std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t TabAE(std::uint32_t classType, std::uint32_t tab, std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t TabTE(std::uint32_t classType, std::uint32_t tab, std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t ClassPoints(std::uint32_t classType, std::uint32_t minimum) const;
    [[nodiscard]] std::uint32_t RemainingAE() const;
    [[nodiscard]] std::uint32_t RemainingTE() const;

    [[nodiscard]] std::uint32_t ValidateLearn(std::uint32_t entryId, UnitCheck const& unit) const;
    [[nodiscard]] bool ValidateAll(UnitCheck const& unit, Entry& failed, std::uint32_t& result) const;
    bool Reorder(UnitCheck const& unit, Entry& failed, std::uint32_t& result);

    void SetEntries(std::vector<Entry> entries) { _entries = std::move(entries); }
    void AddRank(std::uint32_t entryId);
    void Remove(std::uint32_t entryId);
    std::uint32_t AutoLearn(UnitCheck const& unit);

private:
    [[nodiscard]] std::uint32_t Spent(bool talentEssence, std::uint32_t Row::* minimumField, std::uint32_t minimum,
        std::int64_t classType, std::int64_t tab) const;
    [[nodiscard]] Essence const* BudgetRow() const;
    [[nodiscard]] bool BuildRuleOk(std::uint32_t slot, Row const& row) const;

    Catalog const* _catalog;
    Realm _realm;
    std::uint32_t _level;
    std::vector<Entry> _entries;
    std::uint32_t _class;
};

struct UnlearnCost
{
    std::uint32_t Money = 0;
    std::uint32_t Marks = 0;
};

UnlearnCost CostToUnlearn(std::uint32_t level, Row const& row);

struct Purse
{
    std::uint32_t Money = 0;
    std::uint32_t Marks = 0;
};

struct ApplyCheck
{
    UpdateResult Result = UPDATE_OK;
    std::uint32_t Learn = LEARN_OK;
    Entry Failed;
    std::uint32_t Money = 0;
    std::uint32_t Marks = 0;
    std::vector<Entry> Entries;
};

ApplyCheck CheckApply(Build const& base, std::vector<Entry> const& upload, UnitCheck const& unit, Purse const& purse);

using LearnedSpells = std::function<std::vector<std::uint32_t>(std::uint32_t spellId)>;

std::vector<std::uint32_t> TaughtSpells(std::uint32_t spellId, LearnedSpells const& learned);
}

#endif
