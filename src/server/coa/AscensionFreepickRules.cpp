/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFreepickRules.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include "Log.h"
#include <algorithm>
#include <limits>
#include <string_view>
#include <unordered_set>

namespace AscensionFreepick
{
std::array<char const*, LEARN_RESULT_COUNT> const LEARN_RESULTS = { "CA_LEARN_OK", "CA_LEARN_UNKNOWN",
    "CA_LEARN_NOT_IN_WORLD", "CA_LEARN_BAD_ABILITY", "CA_LEARN_DISPLAY_ENTRY", "CA_LEARN_LOW_LEVEL",
    "CA_LEARN_ALREADY_KNOWN", "CA_LEARN_CONDITIONS_FAILED", "CA_LEARN_NOT_IN_BATTLEGROUNDS",
    "CA_LEARN_WRONG_EXPANSION", "CA_LEARN_DISABLED", "CA_LEARN_WRONG_CLASS", "CA_LEARN_ALREADY_KNOW_A_STARTING_NODE",
    "CA_LEARN_MISSING_CONNECTED_ENTRIES", "CA_LEARN_MISSING_REQUIRED_ID", "CA_LEARN_WRONG_REALM",
    "CA_LEARN_NOT_IN_COMBAT", "CA_LEARN_DEPRECATED", "CA_LEARN_BUILD_CREATOR", "CA_LEARN_INVULNERABILE",
    "CA_LEARN_NO_TALENTS_CHALLENGE", "CA_LEARN_TOO_MANY_UNCOMMON_ABILITIES", "CA_LEARN_TOO_MANY_RARE_ABILITIES",
    "CA_LEARN_TOO_MANY_EPIC_ABILITIES", "CA_LEARN_TOO_MANY_LEGENDARY_ABILITIES", "CA_LEARN_WILDCARD_TAME_SPELLS",
    "CA_LEARN_WILDCARD_MASTERIES", "CA_LEARN_WILDCARD_DISABLED", "CA_LEARN_WILDCARD_LOW_LEVEL",
    "CA_LEARN_WILDCARD_STARTER_REPEAT_PROTECTION", "CA_LEARN_NOT_WHILE_DEAD", "CA_LEARN_WILDCARD_NOT_IN_COMBAT",
    "CA_LEARN_WILDCARD_REQUIRED", "CA_LEARN_WILDCARD_LAST_UNLEARNED_ENTRY", "CA_LEARN_WILDCARD_RECENT_ROLL",
    "CA_LEARN_WILDCARD_NOT_IN_BATTLEGROUNDS", "CA_LEARN_WILDCARD_BUCKET", "CA_LEARN_GROUP",
    "CA_LEARN_NOT_ENOUGH_INVESTED_AE", "CA_LEARN_NOT_ENOUGH_INVESTED_TE", "CA_LEARN_NOT_ENOUGH_INVESTED_POINTS",
    "CA_LEARN_MISSING_AE", "CA_LEARN_MISSING_TE", "CA_LEARN_MODE_RESTRICTED", "CA_LEARN_NOT_WILDCARD" };

std::array<char const*, UPDATE_RESULT_COUNT> const UPDATE_RESULTS = { "CA_UPDATE_ENTRIES_OK",
    "CA_UPDATE_ENTRIES_UNKNOWN", "CA_UPDATE_ENTRIES_NO_BUILD", "CA_UPDATE_ENTRIES_BAD_ENTRY",
    "CA_UPDATE_ENTRIES_NO_DIFF", "CA_UPDATE_ENTRIES_NOT_TRAVERSIBLE", "CA_UPDATE_ENTRIES_BAD_UPDATE_COSTS",
    "CA_UPDATE_ENTRIES_MISSING_TOKENS" };

namespace
{
enum AdvancementByte : std::uint32_t
{
    ADVANCEMENT_ID                     = 0,
    ADVANCEMENT_TYPE                   = 4,
    ADVANCEMENT_REQUIRED               = 8,
    ADVANCEMENT_SPELLS                 = 20,
    ADVANCEMENT_AE_COST                = 56,
    ADVANCEMENT_TE_COST                = 60,
    ADVANCEMENT_REQUIRED_LEVEL         = 104,
    ADVANCEMENT_GROUP                  = 116,
    ADVANCEMENT_CLASS_TYPE             = 128,
    ADVANCEMENT_TAB                    = 132,
    ADVANCEMENT_GLOBAL_AE_INVESTMENT   = 136,
    ADVANCEMENT_GLOBAL_TE_INVESTMENT   = 140,
    ADVANCEMENT_CLASS_AE_INVESTMENT    = 144,
    ADVANCEMENT_CLASS_TE_INVESTMENT    = 148,
    ADVANCEMENT_TAB_AE_INVESTMENT      = 152,
    ADVANCEMENT_TAB_TE_INVESTMENT      = 156,
    ADVANCEMENT_CLASS_POINT_VALUE      = 160,
    ADVANCEMENT_CLASS_POINT_INVESTMENT = 164,
    ADVANCEMENT_NAME                   = 188,
    ADVANCEMENT_STARTING_NODE          = 414,
    ADVANCEMENT_CONNECTED              = 415,
    ADVANCEMENT_EXPANSION              = 475,
    ADVANCEMENT_FLAGS                  = 479,
    ADVANCEMENT_REALMS                 = 483,
    ADVANCEMENT_MASTERIES              = 616,
    ADVANCEMENT_END                    = 628,
};

enum ClassTypeDwordField : std::uint32_t
{
    CLASS_TYPE_ID    = 0,
    CLASS_TYPE_CLASS = 2,
    CLASS_TYPE_HERO  = 3,
    CLASS_TYPE_COA   = 4,
    CLASS_TYPE_STOCK = 5,
};

enum EssenceDwordField : std::uint32_t
{
    ESSENCE_LEVEL      = 1,
    ESSENCE_CLASS      = 2,
    ESSENCE_FIRST_MODE = 3,
    ESSENCE_LAST_MODE  = 6,
    ESSENCE_AE         = 7,
    ESSENCE_TE         = 8,
};

constexpr std::array<std::string_view, ENTRY_UNKNOWN> ENTRY_TYPES = { "None", "Ability", "Talent", "Trait",
    "TalentAbility" };
constexpr std::array<std::string_view, 3> EXPANSIONS = { "EXPANSION_CLASSIC", "EXPANSION_THE_BURNING_CRUSADE",
    "EXPANSION_WRATH_OF_THE_LICH_KING" };
constexpr std::array<std::uint32_t, 20> BUILD_SLOTS = { 3, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 17, 18, 37, 38, 39,
    40, 41, 42, 43 };
constexpr std::array<std::uint32_t, 6> UNIT_SLOTS = { 7, 8, 16, 19, 20, 30 };

template <std::size_t Count>
bool Contains(std::array<std::uint32_t, Count> const& slots, std::uint32_t slot)
{
    return std::find(slots.begin(), slots.end(), slot) != slots.end();
}

bool StockClass(std::uint32_t classId)
{
    return (classId >= 1 && classId <= 9) || classId == 11;
}

template <std::size_t Count>
std::uint32_t IndexOf(std::array<std::string_view, Count> const& names, std::string_view name, std::uint32_t missing)
{
    auto const itr = std::find(names.begin(), names.end(), name);
    return itr == names.end() ? missing : std::uint32_t(itr - names.begin());
}

Row ReadRow(ClientDBC::Record const& record)
{
    Row row;
    row.EntryId = record.GetUInt32At(ADVANCEMENT_ID);
    row.Type = EntryType(IndexOf(ENTRY_TYPES, record.GetStringAt(ADVANCEMENT_TYPE), ENTRY_UNKNOWN));
    for (std::size_t index = 0; index < REQUIRED_COUNT; ++index)
        row.Required[index] = record.GetUInt32At(ADVANCEMENT_REQUIRED + 4 * index);
    for (std::size_t index = 0; index < RANK_COUNT; ++index)
        row.Spells[index] = record.GetUInt32At(ADVANCEMENT_SPELLS + 4 * index);
    row.AECost = record.GetUInt32At(ADVANCEMENT_AE_COST);
    row.TECost = record.GetUInt32At(ADVANCEMENT_TE_COST);
    row.RequiredLevel = record.GetUInt32At(ADVANCEMENT_REQUIRED_LEVEL);
    row.Group = record.GetUInt32At(ADVANCEMENT_GROUP);
    row.ClassType = record.GetUInt32At(ADVANCEMENT_CLASS_TYPE);
    row.Tab = record.GetUInt32At(ADVANCEMENT_TAB);
    row.GlobalAEInvestment = record.GetUInt32At(ADVANCEMENT_GLOBAL_AE_INVESTMENT);
    row.GlobalTEInvestment = record.GetUInt32At(ADVANCEMENT_GLOBAL_TE_INVESTMENT);
    row.ClassAEInvestment = record.GetUInt32At(ADVANCEMENT_CLASS_AE_INVESTMENT);
    row.ClassTEInvestment = record.GetUInt32At(ADVANCEMENT_CLASS_TE_INVESTMENT);
    row.TabAEInvestment = record.GetUInt32At(ADVANCEMENT_TAB_AE_INVESTMENT);
    row.TabTEInvestment = record.GetUInt32At(ADVANCEMENT_TAB_TE_INVESTMENT);
    row.ClassPointValue = record.GetUInt32At(ADVANCEMENT_CLASS_POINT_VALUE);
    row.ClassPointInvestment = record.GetUInt32At(ADVANCEMENT_CLASS_POINT_INVESTMENT);
    row.StartingNode = record.GetUInt8(ADVANCEMENT_STARTING_NODE) != 0;
    for (std::size_t index = 0; index < CONNECTED_COUNT; ++index)
        row.Connected[index] = record.GetUInt32At(ADVANCEMENT_CONNECTED + 4 * index);
    row.Expansion = IndexOf(EXPANSIONS, record.GetStringAt(ADVANCEMENT_EXPANSION), 0);
    row.Flags = record.GetUInt32At(ADVANCEMENT_FLAGS);
    for (std::size_t index = 0; index < REALM_COUNT; ++index)
        row.Realms[index] = record.GetUInt8(ADVANCEMENT_REALMS + index) != 0;
    for (std::size_t index = 0; index < MASTERY_COUNT; ++index)
        row.Masteries[index] = record.GetUInt32At(ADVANCEMENT_MASTERIES + 4 * index);
    row.Name = std::string(record.GetStringAt(ADVANCEMENT_NAME));
    return row;
}

std::vector<std::uint32_t> RankUnits(std::vector<Entry> const& entries)
{
    std::vector<std::uint32_t> units;
    for (Entry const& entry : entries)
        units.insert(units.end(), entry.Rank, entry.EntryId);
    return units;
}

bool SameEntries(std::vector<Entry> left, std::vector<Entry> right)
{
    auto const order = [](Entry const& a, Entry const& b)
    {
        return a.EntryId != b.EntryId ? a.EntryId < b.EntryId : a.Rank < b.Rank;
    };
    std::sort(left.begin(), left.end(), order);
    std::sort(right.begin(), right.end(), order);
    return std::equal(left.begin(), left.end(), right.begin(), right.end(),
        [](Entry const& a, Entry const& b) { return a.EntryId == b.EntryId && a.Rank == b.Rank; });
}
}

std::uint32_t Row::MaxRank() const
{
    std::uint32_t ranks = 0;
    while (ranks < RANK_COUNT && Spells[ranks])
        ++ranks;
    return ranks;
}

Row const* Catalog::Find(std::uint32_t entryId) const
{
    auto const itr = Rows.find(entryId);
    return itr == Rows.end() ? nullptr : &itr->second;
}

bool LoadCatalog(Catalog& catalog)
{
    ClientDBC advancement, classTypes, essence;
    if (!advancement.Load(GetClientDBCPath("CharacterAdvancement.dbc"), ADVANCEMENT_END / 4) ||
        !classTypes.Load(GetClientDBCPath("CharacterAdvancementClassTypes.dbc"), CLASS_TYPE_STOCK + 1) ||
        !essence.Load(GetClientDBCPath("CharacterAdvancementEssence.dbc"), ESSENCE_TE + 1))
        return false;

    Catalog loaded;
    for (std::uint32_t index = 0; index < advancement.GetRecordCount(); ++index)
    {
        Row row = ReadRow(advancement.GetRecord(index));
        loaded.RowOrder.push_back(row.EntryId);
        loaded.Rows.emplace(row.EntryId, std::move(row));
    }
    std::sort(loaded.RowOrder.begin(), loaded.RowOrder.end());

    for (std::uint32_t index = 0; index < classTypes.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = classTypes.GetRecord(index);
        loaded.ClassTypes[record.GetUInt32(CLASS_TYPE_ID)] = { record.GetUInt32(CLASS_TYPE_CLASS),
            record.GetUInt32(CLASS_TYPE_HERO) != 0, record.GetUInt32(CLASS_TYPE_COA) != 0,
            record.GetUInt32(CLASS_TYPE_STOCK) != 0 };
    }

    for (std::uint32_t index = 0; index < essence.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = essence.GetRecord(index);
        bool plain = true;
        for (std::uint32_t field = ESSENCE_FIRST_MODE; field <= ESSENCE_LAST_MODE; ++field)
            plain = plain && !record.GetUInt32(field);
        if (plain)
            loaded.Budget[record.GetUInt32(ESSENCE_CLASS)].push_back({ record.GetUInt32(ESSENCE_LEVEL),
                record.GetUInt32(ESSENCE_AE), record.GetUInt32(ESSENCE_TE) });
    }

    LOG_INFO("coa", "Loaded {} free-pick advancement entries, {} class types and {} Hero essence levels",
        loaded.Rows.size(), loaded.ClassTypes.size(), loaded.Budget[HERO_CLASS].size());
    catalog = std::move(loaded);
    return !catalog.Rows.empty() && catalog.Budget.contains(HERO_CLASS) && !catalog.Budget.at(HERO_CLASS).empty();
}

bool Visible(Catalog const& catalog, Realm const& realm, Row const& row)
{
    if (row.Has(ROW_DISABLED) || row.Has(ROW_DEPRECATED))
        return false;
    auto const type = catalog.ClassTypes.find(row.ClassType);
    if (type == catalog.ClassTypes.end())
        return false;
    bool const heroRealm = realm.Development || !(realm.ConquestOfAzeroth || realm.WarcraftReborn);
    if (type->second.Hero != heroRealm && type->second.ConquestOfAzeroth != realm.ConquestOfAzeroth &&
        type->second.Stock != realm.WarcraftReborn)
        return false;
    if ((row.Realms[0] && realm.Live) || (row.Realms[1] && realm.Seasonal) || (row.Realms[2] && realm.League) ||
        (row.Realms[3] && realm.Ptr))
        return true;
    return row.Realms[4] && realm.Development;
}

bool ClassAdmits(Catalog const& catalog, Row const& row, std::uint32_t classId)
{
    auto const type = catalog.ClassTypes.find(row.ClassType);
    if (type == catalog.ClassTypes.end())
        return false;
    if (type->second.Class)
        return classId == type->second.Class;
    if (type->second.Hero)
        return classId == HERO_CLASS;
    if (type->second.ConquestOfAzeroth)
        return classId >= 12 && classId <= 32;
    return type->second.Stock && StockClass(classId);
}

Build::Build(Catalog const& catalog, Realm const& realm, std::uint32_t level, std::vector<Entry> entries,
    std::uint32_t classId)
    : _catalog(&catalog), _realm(realm), _level(level), _entries(std::move(entries)), _class(classId)
{
}

std::uint32_t Build::RankOf(std::uint32_t entryId) const
{
    for (Entry const& entry : _entries)
        if (entry.EntryId == entryId)
            return entry.Rank;
    return 0;
}

bool Build::Has(std::uint32_t entryId) const
{
    return std::any_of(_entries.begin(), _entries.end(),
        [entryId](Entry const& entry) { return entry.EntryId == entryId; });
}

bool Build::HasGroup(std::uint32_t group, std::uint32_t exceptId) const
{
    if (!group)
        return false;
    return std::any_of(_entries.begin(), _entries.end(), [this, group, exceptId](Entry const& entry)
    {
        Row const* row = _catalog->Find(entry.EntryId);
        return row && row->Group == group && entry.EntryId != exceptId;
    });
}

Essence const* Build::BudgetRow() const
{
    auto const budget = _catalog->Budget.find(_class);
    if (budget == _catalog->Budget.end())
        return nullptr;
    auto const itr = std::find_if(budget->second.begin(), budget->second.end(),
        [this](Essence const& essence) { return essence.Level == _level; });
    return itr == budget->second.end() ? nullptr : &*itr;
}

std::uint32_t Build::AEBudget() const
{
    Essence const* essence = BudgetRow();
    return essence ? essence->AE : 0;
}

std::uint32_t Build::TEBudget() const
{
    Essence const* essence = BudgetRow();
    return essence ? essence->TE : 0;
}

std::uint32_t Build::Spent(bool talentEssence, std::uint32_t Row::* minimumField, std::uint32_t minimum,
    std::int64_t classType, std::int64_t tab) const
{
    std::uint32_t total = 0;
    for (Entry const& entry : _entries)
    {
        Row const* row = _catalog->Find(entry.EntryId);
        if (!row || (minimum && row->*minimumField >= minimum))
            continue;
        bool const matches = (classType < 0 || row->ClassType == std::uint32_t(classType)) &&
            (tab < 0 || row->Tab == std::uint32_t(tab));
        if (matches)
            total += (talentEssence ? row->TECost : row->AECost) * entry.Rank;
    }
    return total;
}

std::uint32_t Build::GlobalAE(std::uint32_t minimum) const
{
    return Spent(false, &Row::GlobalAEInvestment, minimum, -1, -1);
}

std::uint32_t Build::GlobalTE(std::uint32_t minimum) const
{
    return Spent(true, &Row::GlobalTEInvestment, minimum, -1, -1);
}

std::uint32_t Build::ClassAE(std::uint32_t classType, std::uint32_t minimum) const
{
    return Spent(false, &Row::ClassAEInvestment, minimum, classType, -1);
}

std::uint32_t Build::ClassTE(std::uint32_t classType, std::uint32_t minimum) const
{
    return Spent(true, &Row::ClassTEInvestment, minimum, classType, -1);
}

std::uint32_t Build::TabAE(std::uint32_t classType, std::uint32_t tab, std::uint32_t minimum) const
{
    return Spent(false, &Row::TabAEInvestment, minimum, classType, tab);
}

std::uint32_t Build::TabTE(std::uint32_t classType, std::uint32_t tab, std::uint32_t minimum) const
{
    return Spent(true, &Row::TabTEInvestment, minimum, classType, tab);
}

std::uint32_t Build::ClassPoints(std::uint32_t classType, std::uint32_t minimum) const
{
    std::uint32_t total = 0;
    for (Entry const& entry : _entries)
        if (Row const* row = _catalog->Find(entry.EntryId))
            if ((!minimum || row->ClassPointInvestment < minimum) && row->ClassType == classType)
                total += row->ClassPointValue * entry.Rank;
    return total;
}

std::uint32_t Build::RemainingAE() const
{
    std::uint32_t const spent = GlobalAE(0), budget = AEBudget();
    return spent < budget ? budget - spent : 0;
}

std::uint32_t Build::RemainingTE() const
{
    std::uint32_t const spent = GlobalTE(0), budget = TEBudget();
    return spent < budget ? budget - spent : 0;
}

bool Build::BuildRuleOk(std::uint32_t slot, Row const& row) const
{
    switch (slot)
    {
        case LEARN_DISPLAY_ENTRY:
            return !row.Has(ROW_DISPLAY);
        case LEARN_LOW_LEVEL:
            return row.RequiredLevel <= _level;
        case LEARN_ALREADY_KNOWN:
            return RankOf(row.EntryId) < row.MaxRank();
        case LEARN_WRONG_EXPANSION:
            return row.Expansion <= _realm.Ruleset;
        case LEARN_DISABLED:
            return !row.Has(ROW_DISABLED);
        case LEARN_WRONG_CLASS:
            return ClassAdmits(*_catalog, row, _class);
        case LEARN_ALREADY_KNOW_A_STARTING_NODE:
            return !row.StartingNode || std::none_of(_entries.begin(), _entries.end(), [this](Entry const& entry)
            {
                Row const* known = _catalog->Find(entry.EntryId);
                return known && known->StartingNode;
            });
        case LEARN_MISSING_CONNECTED_ENTRIES:
        {
            if (std::all_of(row.Connected.begin(), row.Connected.end(), [](std::uint32_t id) { return id == 0; }))
                return true;
            for (std::uint32_t connected : row.Connected)
            {
                if (!connected || !Has(connected))
                    continue;
                if (!row.Has(ROW_CONNECTED_AT_MAX_RANK))
                    return true;
                Row const* other = _catalog->Find(connected);
                if (other && RankOf(connected) == other->MaxRank())
                    return true;
            }
            return false;
        }
        case LEARN_MISSING_REQUIRED_ID:
            return std::all_of(row.Required.begin(), row.Required.end(),
                [this](std::uint32_t id) { return !id || Has(id); });
        case LEARN_WRONG_REALM:
            return Visible(*_catalog, _realm, row);
        case LEARN_DEPRECATED:
            return !row.Has(ROW_DEPRECATED);
        case LEARN_GROUP:
            return !(row.Group != 0 && row.Group != 1 && HasGroup(row.Group, 0));
        case LEARN_NOT_ENOUGH_INVESTED_AE:
        {
            if (std::uint32_t const need = row.GlobalAEInvestment; need && GlobalAE(need) < need)
                return false;
            if (std::uint32_t const need = row.ClassAEInvestment; need && ClassAE(row.ClassType, need) < need)
                return false;
            std::uint32_t const need = row.TabAEInvestment;
            return !need || need <= TabAE(row.ClassType, row.Tab, need);
        }
        case LEARN_NOT_ENOUGH_INVESTED_TE:
        {
            if (std::uint32_t const need = row.GlobalTEInvestment; need && GlobalTE(need) < need)
                return false;
            if (std::uint32_t const need = row.ClassTEInvestment; need && ClassTE(row.ClassType, need) < need)
                return false;
            std::uint32_t const need = row.TabTEInvestment;
            return !need || need <= TabTE(row.ClassType, row.Tab, need);
        }
        case LEARN_NOT_ENOUGH_INVESTED_POINTS:
            return !row.ClassPointInvestment ||
                row.ClassPointInvestment <= ClassPoints(row.ClassType, row.ClassPointInvestment);
        case LEARN_MISSING_AE:
            return !row.AECost || row.AECost <= RemainingAE();
        case LEARN_MISSING_TE:
            return !row.TECost || row.TECost <= RemainingTE();
        case LEARN_MODE_RESTRICTED:
            return !row.Has(ROW_MODE_RESTRICTED);
        default:
            return true;
    }
}

std::uint32_t Build::ValidateLearn(std::uint32_t entryId, UnitCheck const& unit) const
{
    Row const* row = _catalog->Find(entryId);
    if (!row)
        return LEARN_BAD_ABILITY;
    for (std::uint32_t slot = 0; slot < LEARN_RESULT_COUNT; ++slot)
    {
        if (Contains(BUILD_SLOTS, slot) && !BuildRuleOk(slot, *row))
            return slot;
        if (unit && Contains(UNIT_SLOTS, slot) && !unit(slot, *row))
            return slot;
    }
    return LEARN_OK;
}

void Build::AddRank(std::uint32_t entryId)
{
    for (Entry& entry : _entries)
        if (entry.EntryId == entryId)
        {
            ++entry.Rank;
            return;
        }
    _entries.push_back({ entryId, 1 });
}

void Build::Remove(std::uint32_t entryId)
{
    std::erase_if(_entries, [entryId](Entry const& entry) { return entry.EntryId == entryId; });
}

bool Build::ValidateAll(UnitCheck const& unit, Entry& failed, std::uint32_t& result) const
{
    Build walk(*_catalog, _realm, _level, {}, _class);
    for (Entry const& entry : _entries)
        for (std::uint32_t rank = 0; rank < entry.Rank; ++rank)
        {
            result = walk.ValidateLearn(entry.EntryId, unit);
            if (result)
            {
                failed = entry;
                return false;
            }
            walk.AddRank(entry.EntryId);
        }
    result = LEARN_OK;
    return true;
}

bool Build::Reorder(UnitCheck const& unit, Entry& failed, std::uint32_t& result)
{
    std::vector<std::uint32_t> steps = RankUnits(_entries);
    std::stable_sort(steps.begin(), steps.end(), [this](std::uint32_t left, std::uint32_t right)
    {
        Row const* a = _catalog->Find(left);
        Row const* b = _catalog->Find(right);
        if (!a || !b)
            return a != nullptr && b == nullptr;
        if (a->Has(ROW_MASTERY) != b->Has(ROW_MASTERY))
            return a->Has(ROW_MASTERY);
        if (a->RequiredLevel != b->RequiredLevel)
            return a->RequiredLevel < b->RequiredLevel;
        return left < right;
    });

    Build walk(*_catalog, _realm, _level, {}, _class);
    while (!steps.empty())
    {
        bool progress = false;
        for (auto step = steps.begin(); step != steps.end();)
        {
            if (walk.ValidateLearn(*step, unit) == LEARN_OK)
            {
                walk.AddRank(*step);
                step = steps.erase(step);
                progress = true;
            }
            else
                ++step;
        }
        if (!progress)
        {
            failed = { steps.front(), 1 };
            result = walk.ValidateLearn(steps.front(), unit);
            return false;
        }
    }
    _entries = walk._entries;
    result = LEARN_OK;
    return true;
}

std::uint32_t Build::AutoLearn(UnitCheck const& unit)
{
    std::uint32_t added = 0;
    for (bool progress = true; progress;)
    {
        progress = false;
        for (std::uint32_t entryId : _catalog->RowOrder)
        {
            Row const& row = _catalog->Rows.at(entryId);
            if (!row.Has(ROW_AUTOMATIC) || row.AECost || row.TECost)
                continue;
            while (ValidateLearn(entryId, unit) == LEARN_OK)
            {
                AddRank(entryId);
                ++added;
                progress = true;
            }
        }
    }
    return added;
}

UnlearnCost CostToUnlearn(std::uint32_t level, Row const& row)
{
    if (level <= 10 || row.Has(ROW_FREE_UNLEARN))
        return {};
    std::uint32_t const tier = level <= 19 ? 32 : level <= 29 ? 71 : level <= 49 ? 521 : level <= 59 ? 1107 : 2221;
    return { tier * level, 250 };
}

ApplyCheck CheckApply(Build const& base, std::vector<Entry> const& upload, UnitCheck const& unit, Purse const& purse)
{
    ApplyCheck check;
    Catalog const& catalog = base.Data();
    std::vector<Entry> wanted;
    for (Entry const& entry : upload)
    {
        if (!entry.Rank)
            continue;
        Row const* row = catalog.Find(entry.EntryId);
        if (!row || std::any_of(wanted.begin(), wanted.end(), [&catalog, &entry, row](Entry const& seen)
            {
                return seen.EntryId == entry.EntryId || (row->Group && catalog.Find(seen.EntryId)->Group == row->Group);
            }))
        {
            check.Result = UPDATE_BAD_ENTRY;
            check.Failed = entry;
            return check;
        }
        wanted.push_back(entry);
    }

    std::vector<Entry> removed;
    for (Entry const& entry : base.Entries())
        if (std::none_of(wanted.begin(), wanted.end(),
            [&entry](Entry const& kept) { return kept.EntryId == entry.EntryId; }))
            removed.push_back(entry);
    bool const changed = !removed.empty() || std::any_of(wanted.begin(), wanted.end(),
        [&base](Entry const& entry) { return base.RankOf(entry.EntryId) != entry.Rank; });
    if (!changed)
    {
        check.Result = UPDATE_NO_DIFF;
        return check;
    }

    Build target(base);
    target.SetEntries(wanted);

    std::vector<Entry> kept;
    for (Entry const& entry : base.Entries())
        if (Row const* row = catalog.Find(entry.EntryId); row && (row->Group == 1 || row->Has(ROW_RETAINED)))
            kept.push_back(entry);
    bool const onlyRemovals = std::all_of(wanted.begin(), wanted.end(),
        [&base](Entry const& entry) { return base.RankOf(entry.EntryId) == entry.Rank; });
    if (!(onlyRemovals && SameEntries(wanted, kept)) && !target.ValidateAll(unit, check.Failed, check.Learn) &&
        !target.Reorder(unit, check.Failed, check.Learn))
    {
        check.Result = UPDATE_NOT_TRAVERSIBLE;
        return check;
    }

    std::uint32_t marksLeft = purse.Marks;
    for (Entry const& entry : removed)
    {
        UnlearnCost const cost = CostToUnlearn(base.Level(), *catalog.Find(entry.EntryId));
        if (!cost.Money && !cost.Marks)
            continue;
        if (cost.Marks && marksLeft >= cost.Marks)
        {
            marksLeft -= cost.Marks;
            check.Marks += cost.Marks;
            continue;
        }
        if (!cost.Money || purse.Money < check.Money + cost.Money)
        {
            check.Result = UPDATE_BAD_UPDATE_COSTS;
            check.Failed = entry;
            return check;
        }
        check.Money += cost.Money;
    }
    check.Entries = target.Entries();
    return check;
}

std::vector<std::uint32_t> TaughtSpells(std::uint32_t spellId, LearnedSpells const& learned)
{
    std::vector<std::uint32_t> spells;
    std::vector<std::uint32_t> pending = { spellId };
    std::unordered_set<std::uint32_t> seen;
    while (!pending.empty())
    {
        std::uint32_t const current = pending.back();
        pending.pop_back();
        if (!seen.insert(current).second)
            continue;
        std::vector<std::uint32_t> const next = learned(current);
        if (next.empty())
            spells.push_back(current);
        else
            pending.insert(pending.end(), next.rbegin(), next.rend());
    }
    return spells;
}
}
