/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "WorldSession.h"
#include <algorithm>
#include <map>
#include <vector>

namespace
{
constexpr uint16 SkillValuePerStep = 75;

struct KnownRank
{
    uint32 spellId;
    SpellLearnSkillNode const* node;
};

std::map<uint16, std::vector<KnownRank>> KnownProfessionRanks(Player const* player)
{
    std::map<uint16, std::vector<KnownRank>> ranks;
    for (auto const& [spellId, playerSpell] : player->GetSpellMap())
    {
        if (playerSpell->State == PLAYERSPELL_REMOVED)
            continue;

        SpellLearnSkillNode const* node = sSpellMgr->GetSpellLearnSkill(spellId);
        if (node && IsProfessionSkill(node->skill))
            ranks[node->skill].push_back({ spellId, node });
    }
    return ranks;
}

void LowerProfessionToStep(Player* player, uint16 skill, std::vector<KnownRank> ranks, uint16 maxStep)
{
    auto const aboveBegin = std::partition(ranks.begin(), ranks.end(),
        [maxStep](KnownRank const& rank) { return rank.node->step <= maxStep; });
    auto const highest = std::max_element(ranks.begin(), aboveBegin,
        [](KnownRank const& left, KnownRank const& right) { return left.node->step < right.node->step; });
    bool const rankAbove = aboveBegin != ranks.end();
    if (highest == aboveBegin
        || (!rankAbove && player->GetPureMaxSkillValue(skill) <= maxStep * SkillValuePerStep))
        return;

    uint16 const value = player->GetPureSkillValue(skill);
    for (auto rank = aboveBegin; rank != ranks.end(); ++rank)
        player->removeSpell(rank->spellId, SPEC_MASK_ALL, false);

    auto active = player->GetSpellMap().find(highest->spellId);
    if (active != player->GetSpellMap().end() && !active->second->Active)
    {
        active->second->Active = true;
        player->SendLearnPacket(highest->spellId, true);
    }

    uint16 const maxValue = highest->node->maxvalue;
    player->SetSkill(skill, highest->node->step, std::min(value, maxValue), maxValue);
}

class ascension_profession_ranks_player : public PlayerScript
{
public:
    ascension_profession_ranks_player() : PlayerScript("ascension_profession_ranks_player", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        uint16 const maxStep = GetMaxProfessionSkillStep(player->GetSession()->Expansion());
        for (auto const& [skill, ranks] : KnownProfessionRanks(player))
            LowerProfessionToStep(player, skill, ranks, maxStep);
    }
};
}

void AddSC_AscensionProfessionRanks()
{
    new ascension_profession_ranks_player();
}
