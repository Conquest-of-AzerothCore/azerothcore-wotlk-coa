/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionCoATalentData.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include "ItemTemplate.h"
#include "Log.h"
#include <algorithm>
#include <cctype>
#include <map>
#include <string>
#include <string_view>
#include <tuple>
#include <unordered_map>
#include <utility>

namespace AscensionCompatData
{
std::vector<CoATalentEntry> CoATalentEntries;
std::vector<CoASelectableFreeEntry> CoASelectableFreeEntries;
std::vector<CoAAutomaticDependency> CoAAutomaticDependencies;
std::vector<CoASpecialization> CoASpecializations;
std::vector<CoATalentBudget> CoATalentBudgets;

namespace
{
constexpr uint32 SHARED_CLASS_TAB_ID = 87;
constexpr uint32 ADVANCEMENT_REQUIRED_COUNT = 3;
constexpr uint32 ADVANCEMENT_RANK_COUNT = 5;
constexpr uint32 ADVANCEMENT_FLAG_FREE_UNLEARN = 0x2000;

constexpr std::array<uint32, 2> IDENTITY_PASSIVES_KEEPING_AUTHORED_GATES = { 4037, 4041 };

enum AdvancementDwordField : uint32
{
    ADVANCEMENT_ID           = 0,
    ADVANCEMENT_TYPE         = 1,
    ADVANCEMENT_REQUIRED     = 2,
    ADVANCEMENT_SPELLS       = 5,
    ADVANCEMENT_AE_COST      = 14,
    ADVANCEMENT_TE_COST      = 15,
    ADVANCEMENT_LEVEL        = 26,
    ADVANCEMENT_GROUP        = 29,
    ADVANCEMENT_CLASS_TYPE   = 32,
    ADVANCEMENT_TAB          = 33,
    ADVANCEMENT_FLAGS        = 73,
};

enum ChrSpecsDwordField : uint32
{
    CHR_SPECS_ID              = 0,
    CHR_SPECS_PRIMARY_STAT    = 8,
    CHR_SPECS_SIGNATURE_SPELL = 24,
    CHR_SPECS_IDENTITY_ENTRY  = 28,
};

enum EssenceDwordField : uint32
{
    ESSENCE_LEVEL = 1,
    ESSENCE_KEY   = 2,
    ESSENCE_FLAGS = 3,
    ESSENCE_AE    = 7,
    ESSENCE_TE    = 8,
};

bool Contains(auto const& values, uint32 value)
{
    return std::find(values.begin(), values.end(), value) != values.end();
}

std::string Upper(std::string_view text)
{
    std::string result(text);
    std::transform(result.begin(), result.end(), result.begin(), [](unsigned char c) { return char(std::toupper(c)); });
    return result;
}

struct Node
{
    CoATalentEntry Entry;
    std::vector<uint32> Required;
    uint32 Group;
    bool ClassTab;
};

std::array<uint8, 3> PrimaryStats(ClientDBC::Record const& record)
{
    static std::array<std::pair<std::string_view, uint8>, 5> const statByName = { {
        { "Agility", ITEM_MOD_AGILITY },
        { "Strength", ITEM_MOD_STRENGTH },
        { "Intellect", ITEM_MOD_INTELLECT },
        { "Spirit", ITEM_MOD_SPIRIT },
        { "Stamina", ITEM_MOD_STAMINA },
    } };

    std::array<uint8, 3> stats{};
    for (uint32 index = 0; index < stats.size(); ++index)
    {
        std::string_view const name = record.GetString(CHR_SPECS_PRIMARY_STAT + index);
        for (auto const& [statName, stat] : statByName)
            if (name == statName)
                stats[index] = stat;
    }
    return stats;
}

bool IsFreeChoice(Node const& node)
{
    return !node.Entry.AECost && !node.Entry.TECost && node.Group;
}

struct AdvancementClassType
{
    uint32 ClassId;
    bool IsCustomClass;
};
}

bool GetCoATalentBudget(std::uint8_t classId, std::uint8_t level, std::uint32_t& ae, std::uint32_t& te)
{
    CoATalentBudget const* row = nullptr;
    for (CoATalentBudget const& budget : CoATalentBudgets)
    {
        if (budget.ClassId != classId || budget.Level > level)
            continue;
        if (!row || budget.Level > row->Level)
            row = &budget;
    }
    if (!row)
        return false;

    ae = row->AE;
    te = row->TE;
    return true;
}

bool LoadCoATalentData()
{
    CoATalentEntries.clear();
    CoASelectableFreeEntries.clear();
    CoAAutomaticDependencies.clear();
    CoASpecializations.clear();
    CoATalentBudgets.clear();

    ClientDBC classes, classTypes, tabTypes, specs, advancement, essence;
    if (!classes.Load(GetClientDBCPath("ChrClasses.dbc"), 56) ||
        !classTypes.Load(GetClientDBCPath("CharacterAdvancementClassTypes.dbc"), 5) ||
        !tabTypes.Load(GetClientDBCPath("CharacterAdvancementTabTypes.dbc"), 2) ||
        !specs.Load(GetClientDBCPath("ChrSpecs.dbc"), 29) ||
        !advancement.Load(GetClientDBCPath("CharacterAdvancement.dbc"), ADVANCEMENT_FLAGS + 1) ||
        !essence.Load(GetClientDBCPath("CharacterAdvancementEssence.dbc"), ESSENCE_TE + 1))
        return false;

    for (uint32 row = 0; row < essence.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = essence.GetRecord(row);
        uint32 const key = record.GetUInt32(ESSENCE_KEY);
        uint32 const level = record.GetUInt32(ESSENCE_LEVEL);
        if (key < 12 || key > 32 || !level || level > 255)
            continue;
        if (record.GetUInt32(ESSENCE_FLAGS) || record.GetUInt32(ESSENCE_FLAGS + 1) ||
            record.GetUInt32(ESSENCE_FLAGS + 2) || record.GetUInt32(ESSENCE_FLAGS + 3))
            continue;

        CoATalentBudgets.push_back({ uint8(key), uint8(level),
            uint8(std::min<uint32>(record.GetUInt32(ESSENCE_AE), 255)),
            uint8(std::min<uint32>(record.GetUInt32(ESSENCE_TE), 255)) });
    }
    std::sort(CoATalentBudgets.begin(), CoATalentBudgets.end(),
        [](CoATalentBudget const& left, CoATalentBudget const& right)
        {
            return std::tie(left.ClassId, left.Level) < std::tie(right.ClassId, right.Level);
        });

    std::unordered_map<uint32, std::string> classTokens;
    for (uint32 row = 0; row < classes.GetRecordCount(); ++row)
        classTokens[classes.GetRecord(row).GetUInt32(0)] = std::string(classes.GetRecord(row).GetString(55));

    std::unordered_map<uint32, AdvancementClassType> classTypeById;
    for (uint32 row = 0; row < classTypes.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = classTypes.GetRecord(row);
        classTypeById[record.GetUInt32(0)] = { record.GetUInt32(2), record.GetUInt32(4) != 0 };
    }

    std::unordered_map<uint32, std::string> tabTokens;
    for (uint32 row = 0; row < tabTypes.GetRecordCount(); ++row)
        tabTokens[tabTypes.GetRecord(row).GetUInt32(0)] = Upper(tabTypes.GetRecord(row).GetString(1));

    std::map<std::pair<std::string, std::string>, uint32> specByClassAndTab;
    std::unordered_map<uint32, uint32> identitySpecByEntry;
    std::vector<std::tuple<uint32, uint32, uint32, std::array<uint8, 3>>> specIdentities;
    for (uint32 row = 0; row < specs.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = specs.GetRecord(row);
        std::pair<std::string, std::string> key(record.GetString(1), record.GetString(2));
        uint32 const specId = record.GetUInt32(CHR_SPECS_ID);
        specByClassAndTab[key] = specId;
        if (uint32 identity = record.GetUInt32(CHR_SPECS_IDENTITY_ENTRY))
        {
            identitySpecByEntry[identity] = specId;
            specIdentities.emplace_back(specId, identity, record.GetUInt32(CHR_SPECS_SIGNATURE_SPELL),
                PrimaryStats(record));
        }
    }

    std::vector<Node> nodes;
    for (uint32 row = 0; row < advancement.GetRecordCount(); ++row)
    {
        ClientDBC::Record record = advancement.GetRecord(row);
        uint32 const entryId = record.GetUInt32(ADVANCEMENT_ID);
        auto classType = classTypeById.find(record.GetUInt32(ADVANCEMENT_CLASS_TYPE));
        if (classType == classTypeById.end() || !classType->second.IsCustomClass ||
            classType->second.ClassId < 12 || classType->second.ClassId > 32)
            continue;

        uint32 const classId = classType->second.ClassId;
        uint32 const tab = record.GetUInt32(ADVANCEMENT_TAB);
        uint32 specId = 0;
        if (tab != SHARED_CLASS_TAB_ID)
        {
            auto spec = specByClassAndTab.find({ classTokens[classId], tabTokens[tab] });
            if (spec == specByClassAndTab.end())
                continue;
            specId = spec->second;
        }

        Node node{};
        node.Entry.EntryId = entryId;
        node.Entry.ClassId = uint8(classId);
        node.Entry.SpecId = uint16(specId);
        node.Entry.AECost = uint8(record.GetUInt32(ADVANCEMENT_AE_COST));
        node.Entry.TECost = uint8(record.GetUInt32(ADVANCEMENT_TE_COST));
        node.Entry.RequiredLevel = uint8(record.GetUInt32(ADVANCEMENT_LEVEL));
        node.Entry.Talent = record.GetString(ADVANCEMENT_TYPE) == "Talent";
        node.Entry.FreeUnlearn = (record.GetUInt32(ADVANCEMENT_FLAGS) & ADVANCEMENT_FLAG_FREE_UNLEARN) != 0;
        node.Group = record.GetUInt32(ADVANCEMENT_GROUP);
        node.ClassTab = tab == SHARED_CLASS_TAB_ID;

        bool tooManyRanks = false;
        for (uint32 field = ADVANCEMENT_SPELLS; field < ADVANCEMENT_SPELLS + ADVANCEMENT_RANK_COUNT; ++field)
        {
            uint32 const spellId = record.GetUInt32(field);
            if (!spellId)
                continue;
            if (node.Entry.SpellCount == node.Entry.SpellIds.size())
            {
                tooManyRanks = true;
                break;
            }
            node.Entry.SpellIds[node.Entry.SpellCount++] = spellId;
        }

        if (tooManyRanks)
        {
            LOG_ERROR("coa", "Skipped CoA talent entry {} with more than 3 ranks", entryId);
            continue;
        }

        for (uint32 field = ADVANCEMENT_REQUIRED; field < ADVANCEMENT_REQUIRED + ADVANCEMENT_REQUIRED_COUNT; ++field)
            if (uint32 requiredId = record.GetUInt32(field))
                node.Required.push_back(requiredId);

        auto identity = identitySpecByEntry.find(entryId);
        if (identity != identitySpecByEntry.end() && identity->second == specId &&
            !Contains(IDENTITY_PASSIVES_KEEPING_AUTHORED_GATES, entryId))
        {
            node.Entry.RequiredLevel = 10;
            node.Required.clear();
        }

        if (node.Entry.AECost || node.Entry.TECost)
            std::copy(node.Required.begin(), node.Required.end(), node.Entry.RequiredEntryIds.begin());

        nodes.push_back(std::move(node));
    }

    std::sort(nodes.begin(), nodes.end(), [](Node const& left, Node const& right)
    {
        return left.Entry.EntryId < right.Entry.EntryId;
    });

    std::unordered_map<uint32, Node const*> nodeById;
    for (Node const& node : nodes)
        nodeById[node.Entry.EntryId] = &node;

    for (Node const& node : nodes)
    {
        CoATalentEntries.push_back(node.Entry);
        if (IsFreeChoice(node))
            CoASelectableFreeEntries.push_back({ node.Entry.EntryId, node.Group });

        if (node.Entry.AECost || node.Entry.TECost || node.Required.empty())
            continue;

        std::vector<uint32> required;
        for (uint32 requiredId : node.Required)
        {
            auto requiredNode = nodeById.find(requiredId);
            bool const paidClassNode = requiredNode != nodeById.end() && requiredNode->second->ClassTab &&
                (requiredNode->second->Entry.AECost || requiredNode->second->Entry.TECost);
            if (!(node.Entry.SpecId && !IsFreeChoice(node) && paidClassNode))
                required.push_back(requiredId);
        }

        if (required.empty())
            continue;

        if (required.size() > 2)
        {
            LOG_ERROR("coa", "Skipped CoA talent entry {} dependencies: {} required entries",
                node.Entry.EntryId, required.size());
            continue;
        }

        CoAAutomaticDependency dependency{ node.Entry.EntryId, {} };
        std::copy(required.begin(), required.end(), dependency.RequiredEntryIds.begin());
        CoAAutomaticDependencies.push_back(dependency);
    }

    for (auto const& [specId, identityId, signatureSpellId, primaryStats] : specIdentities)
    {
        auto identity = nodeById.find(identityId);
        if (identity == nodeById.end() || identity->second->Entry.SpecId != specId)
            continue;

        uint32 signatureId = 0;
        for (Node const& node : nodes)
            if (signatureSpellId && node.Entry.ClassId == identity->second->Entry.ClassId &&
                Contains(node.Entry.SpellIds, signatureSpellId))
            {
                signatureId = node.Entry.EntryId;
                break;
            }
        CoASpecializations.push_back(
            { uint16(specId), identity->second->Entry.ClassId, identityId, signatureId, primaryStats });
    }

    LOG_INFO("coa",
        "Loaded {} CoA talent entries ({} selectable free, {} automatic dependencies, {} specializations, "
        "{} budget rows)",
        CoATalentEntries.size(), CoASelectableFreeEntries.size(), CoAAutomaticDependencies.size(),
        CoASpecializations.size(), CoATalentBudgets.size());
    return true;
}
}
