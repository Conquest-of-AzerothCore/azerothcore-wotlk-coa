/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_SPEC_LOOT_H
#define COA_ASCENSION_SPEC_LOOT_H

#include "Define.h"
#include <array>
#include <utility>
#include <vector>

class Player;
struct ItemTemplate;

namespace AscensionSpecLoot
{
using PrimaryStats = std::array<uint8, 3>;
using StatList = std::vector<std::pair<uint32, int32>>;

enum class Fit : uint8
{
    None,
    Shared,
    Primary,
};

PrimaryStats ActivePrimaryStats(Player const* player);

StatList TemplateStats(ItemTemplate const* item);

Fit ItemFit(PrimaryStats const& stats, ItemTemplate const* item);

Fit StatsFit(PrimaryStats const& stats, StatList const& itemStats);

template <typename Candidate, typename FitOf>
std::vector<Candidate> PreferFit(std::vector<Candidate> const& candidates, FitOf fitOf)
{
    std::vector<Candidate> primary;
    std::vector<Candidate> shared;
    for (Candidate const& candidate : candidates)
    {
        switch (fitOf(candidate))
        {
            case Fit::Primary:
                primary.push_back(candidate);
                break;
            case Fit::Shared:
                shared.push_back(candidate);
                break;
            case Fit::None:
                break;
        }
    }

    if (!primary.empty())
        return primary;
    return shared.empty() ? candidates : shared;
}

template <typename Candidate, typename TemplateOf>
std::vector<Candidate> PreferSpecialization(Player const* player, std::vector<Candidate> const& candidates,
    TemplateOf templateOf)
{
    PrimaryStats const stats = ActivePrimaryStats(player);
    return PreferFit(candidates, [&](Candidate const& candidate) { return ItemFit(stats, templateOf(candidate)); });
}
}

#endif
