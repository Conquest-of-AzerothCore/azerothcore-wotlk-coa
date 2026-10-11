/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornRules.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include "Log.h"
#include <algorithm>
#include <map>
#include <set>

namespace AscensionWarcraftReborn
{
namespace
{
using AscensionFreepick::Realm;
using AscensionFreepick::Row;

constexpr std::uint32_t SPELL_RANK_FIRST_SPELL = 1;
constexpr std::uint32_t SPELL_RANK_SPELL = 2;
constexpr std::uint32_t SPELL_RANK_RANK = 3;
constexpr std::uint32_t TRAINER_SPELL = 1;
constexpr std::uint32_t SKILL_LINE_ABILITY_SKILL = 1;
constexpr std::uint32_t SKILL_LINE_ABILITY_SPELL = 2;

bool Stock(Data const& data, Row const& row)
{
    auto const type = data.Catalog.ClassTypes.find(row.ClassType);
    return type != data.Catalog.ClassTypes.end() && type->second.Stock;
}

bool TrainedAbility(Data const& data, Realm const& realm, std::uint32_t classId, Row const& row)
{
    return realm.WarcraftReborn && row.Type == AscensionFreepick::ENTRY_ABILITY &&
        row.Has(AscensionFreepick::ROW_DISPLAY) &&
        !(row.Flags & ROW_ALTERNATE) && row.Spells[0] && Stock(data, row) &&
        AscensionFreepick::ClassAdmits(data.Catalog, row, classId) &&
        AscensionFreepick::Visible(data.Catalog, realm, row);
}

std::vector<std::uint32_t> FirstRanks(Data const& data, Realm const& realm, std::uint32_t classId,
    std::uint32_t level, bool automatic)
{
    std::vector<std::uint32_t> spells;
    for (std::uint32_t id : data.Catalog.RowOrder)
    {
        Row const& row = data.Catalog.Rows.at(id);
        if (TrainedAbility(data, realm, classId, row) && row.Has(AscensionFreepick::ROW_AUTOMATIC) == automatic &&
            row.RequiredLevel <= level)
            spells.push_back(row.Spells[0]);
    }
    return spells;
}
}

std::vector<Grant> const& Grants()
{
    static std::vector<Grant> const grants = {
        { DARK_APOTHEOSIS, { DARK_APOTHEOSIS_SPELLS.begin(), DARK_APOTHEOSIS_SPELLS.end() } },
        { 1101579, { 1101515, 1100883, 1102641, 1100982, 1356991 } },
        { 1160103, { 1100674 } },
        { 1165139, { 1133891, 1105420 } } };
    return grants;
}

std::vector<std::uint32_t> const* Data::LadderOf(std::uint32_t spellId) const
{
    auto const first = FirstRanks.find(spellId);
    return first == FirstRanks.end() ? nullptr : &Ladders.at(first->second);
}

bool LoadData(Data& data)
{
    ClientDBC spellRanks, trainers, abilities;
    if (!AscensionFreepick::LoadCatalog(data.Catalog) ||
        !spellRanks.Load(GetClientDBCPath("SpellRank.dbc"), SPELL_RANK_RANK + 1) ||
        !trainers.Load(GetClientDBCPath("NPCTrainer.dbc"), TRAINER_SPELL + 1) ||
        !abilities.Load(GetClientDBCPath("SkillLineAbility.dbc"), SKILL_LINE_ABILITY_SPELL + 1))
        return false;

    for (std::uint32_t index = 0; index < abilities.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = abilities.GetRecord(index);
        data.SkillLines[record.GetUInt32(SKILL_LINE_ABILITY_SPELL)].push_back(
            record.GetUInt32(SKILL_LINE_ABILITY_SKILL));
    }

    for (std::uint32_t index = 0; index < trainers.GetRecordCount(); ++index)
        data.Trainable.insert(trainers.GetRecord(index).GetUInt32(TRAINER_SPELL));

    std::unordered_set<std::uint32_t> firstRanks;
    for (auto const& [id, row] : data.Catalog.Rows)
        if (row.Spells[0] && Stock(data, row))
        {
            firstRanks.insert(row.Spells[0]);
            if (row.Has(AscensionFreepick::ROW_AUTOMATIC) || (row.Flags & ROW_ALTERNATE))
                data.Automatic.insert(row.Spells[0]);
        }

    std::map<std::uint32_t, std::map<std::uint32_t, std::uint32_t>> ranks;
    for (std::uint32_t index = 0; index < spellRanks.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = spellRanks.GetRecord(index);
        std::uint32_t const first = record.GetUInt32(SPELL_RANK_FIRST_SPELL);
        if ((firstRanks.contains(first) || first >= REBORN_SPELL_OFFSET) && record.GetUInt32(SPELL_RANK_RANK))
            ranks[first][record.GetUInt32(SPELL_RANK_RANK)] = record.GetUInt32(SPELL_RANK_SPELL);
    }
    for (auto const& [first, chain] : ranks)
    {
        std::vector<std::uint32_t> ladder;
        for (auto const& [rank, spellId] : chain)
        {
            if (rank != ladder.size() + 1 || !spellId)
                break;
            ladder.push_back(spellId);
        }
        auto const trainable = [&data](std::uint32_t id) { return data.Trainable.contains(id); };
        auto const ranked = [&data](std::uint32_t id) { return data.FirstRanks.contains(id); };
        bool const trained = firstRanks.contains(first) ||
            std::find(DARK_APOTHEOSIS_SPELLS.begin(), DARK_APOTHEOSIS_SPELLS.end(), first) !=
                DARK_APOTHEOSIS_SPELLS.end() ||
            std::any_of(ladder.begin(), ladder.end(), trainable);
        if (!trained || ladder.size() < 2 || ladder.front() != first ||
            std::any_of(ladder.begin(), ladder.end(), ranked))
            continue;
        for (std::uint32_t spellId : ladder)
            data.FirstRanks[spellId] = first;
        data.Ladders[first] = std::move(ladder);
    }

    LOG_INFO("coa", "Warcraft Reborn: {} rank ladders, {} trainer spells", data.Ladders.size(), data.Trainable.size());
    return true;
}

std::vector<std::vector<std::uint32_t>> RankChains(Data const& data)
{
    std::vector<std::vector<std::uint32_t>> chains;
    for (auto const& [first, ladder] : data.Ladders)
        chains.push_back(ladder);
    return chains;
}

std::vector<std::uint32_t> StartingSpells(Data const& data, Realm const& realm, std::uint32_t classId,
    std::uint32_t level)
{
    return FirstRanks(data, realm, classId, level, false);
}

std::vector<std::uint32_t> ClassSkillLines(Data const& data, Realm const& realm, std::uint32_t classId)
{
    std::set<std::uint32_t> skills;
    for (std::uint32_t id : data.Catalog.RowOrder)
    {
        Row const& row = data.Catalog.Rows.at(id);
        if (!TrainedAbility(data, realm, classId, row))
            continue;
        if (auto const lines = data.SkillLines.find(row.Spells[0]); lines != data.SkillLines.end())
            for (std::uint32_t skillId : lines->second)
                if (skillId >= REBORN_SKILL_OFFSET)
                    skills.insert(skillId);
    }
    return { skills.begin(), skills.end() };
}

std::vector<std::uint32_t> AutomaticSpells(Data const& data, Realm const& realm, std::uint32_t classId,
    std::uint32_t level)
{
    return FirstRanks(data, realm, classId, level, true);
}

std::uint32_t RebornSpell(std::uint32_t spellId, SpellExists const& exists)
{
    return spellId && spellId < REBORN_SPELL_OFFSET && exists(spellId + REBORN_SPELL_OFFSET) ?
        spellId + REBORN_SPELL_OFFSET : spellId;
}

std::vector<TrainerSpell> TrainerSpells(Data const& data, Realm const& realm, std::uint32_t classId,
    std::vector<TrainerSpell> const& stock, SpellExists const& exists, RebornRow const& reborn)
{
    std::unordered_set<std::uint32_t> abilities;
    for (std::uint32_t id : data.Catalog.RowOrder)
    {
        Row const& row = data.Catalog.Rows.at(id);
        if (!TrainedAbility(data, realm, classId, row) || row.Has(AscensionFreepick::ROW_AUTOMATIC))
            continue;
        if (std::vector<std::uint32_t> const* ladder = data.LadderOf(row.Spells[0]))
            abilities.insert(ladder->begin(), ladder->end());
        else
            abilities.insert(row.Spells[0]);
    }

    std::vector<TrainerSpell> spells;
    std::unordered_set<std::uint32_t> listed;
    bool teachesAbilities = false;
    std::uint32_t maxLevel = 0;
    for (TrainerSpell spell : stock)
    {
        maxLevel = std::max(maxLevel, spell.ReqLevel);
        std::uint32_t const spellId = RebornSpell(spell.SpellId, exists);
        if (spellId != spell.SpellId)
        {
            TrainerSpell const retuned = reborn(spellId);
            spell.SpellId = spellId;
            spell.ReqLevel = retuned.ReqLevel;
            spell.MoneyCost = retuned.MoneyCost;
        }
        for (std::uint32_t& ability : spell.ReqAbility)
            ability = RebornSpell(ability, exists);
        if (!listed.insert(spell.SpellId).second)
            continue;
        teachesAbilities = teachesAbilities || abilities.contains(spell.SpellId);
        spells.push_back(spell);
    }
    if (!teachesAbilities)
        return spells;

    std::vector<std::uint32_t> const classLines = ClassSkillLines(data, realm, classId);
    for (std::uint32_t spellId : data.Trainable)
    {
        auto const lines = data.SkillLines.find(spellId);
        std::vector<std::uint32_t> const* ladder = data.LadderOf(spellId);
        if (spellId < REBORN_SPELL_OFFSET || lines == data.SkillLines.end() ||
            data.Automatic.contains(ladder ? ladder->front() : spellId))
            continue;
        if (std::any_of(lines->second.begin(), lines->second.end(), [&classLines](std::uint32_t line)
            { return std::find(classLines.begin(), classLines.end(), line) != classLines.end(); }))
            abilities.insert(spellId);
    }

    std::vector<std::uint32_t> missing;
    for (std::uint32_t spellId : abilities)
        if (data.Trainable.contains(spellId) && !listed.contains(spellId) && exists(spellId))
            missing.push_back(spellId);
    std::sort(missing.begin(), missing.end());
    for (std::uint32_t spellId : missing)
    {
        TrainerSpell spell = reborn(spellId);
        if (spell.ReqLevel <= maxLevel)
            spells.push_back(spell);
    }
    return spells;
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> SpellTwins(std::uint32_t spellCount, SpellLayoutOf const& layout)
{
    std::vector<std::pair<std::uint32_t, std::uint32_t>> twins;
    for (std::uint32_t spellId = 1; spellId < REBORN_SPELL_OFFSET && spellId + REBORN_SPELL_OFFSET < spellCount; ++spellId)
    {
        std::optional<SpellLayout> const stock = layout(spellId);
        if (stock && stock == layout(spellId + REBORN_SPELL_OFFSET))
            twins.emplace_back(spellId, spellId + REBORN_SPELL_OFFSET);
    }
    return twins;
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> SpellNamesakes(std::uint32_t spellCount, SpellLayoutOf const& layout)
{
    std::vector<std::pair<std::uint32_t, std::uint32_t>> namesakes;
    for (std::uint32_t spellId = 1; spellId < REBORN_SPELL_OFFSET && spellId + REBORN_SPELL_OFFSET < spellCount; ++spellId)
    {
        std::optional<SpellLayout> const stock = layout(spellId);
        std::optional<SpellLayout> const reborn = stock ? layout(spellId + REBORN_SPELL_OFFSET) : std::nullopt;
        if (reborn && reborn->Name == stock->Name && *reborn != *stock)
            namesakes.emplace_back(spellId, spellId + REBORN_SPELL_OFFSET);
    }
    return namesakes;
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> RankTwins(std::vector<std::pair<std::uint32_t, std::uint32_t>> const& twins,
    LaterRanks const& laterRanks, FirstRank const& firstRank, SpellLayoutOf const& layout)
{
    std::unordered_map<std::uint32_t, std::uint32_t> sources;
    for (auto const& [source, twin] : twins)
        sources[twin] = source;

    std::vector<std::pair<std::uint32_t, std::uint32_t>> ranked;
    for (auto const& [source, twin] : twins)
    {
        if (firstRank(source) != source || firstRank(twin) != twin)
            continue;
        std::optional<SpellLayout> const head = layout(twin);
        for (std::uint32_t rank : laterRanks(twin))
        {
            auto const known = sources.find(rank);
            if (known != sources.end() && firstRank(known->second) == source)
                continue;
            if (layout(rank) == head)
                ranked.emplace_back(source, rank);
        }
    }
    return ranked;
}
}
