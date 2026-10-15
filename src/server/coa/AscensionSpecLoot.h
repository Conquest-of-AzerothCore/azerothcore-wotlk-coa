/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_SPEC_LOOT_H
#define COA_ASCENSION_SPEC_LOOT_H

#include "Define.h"
#include <array>
#include <vector>

class Player;
struct ItemTemplate;

namespace AscensionSpecLoot
{
using PrimaryStats = std::array<uint8, 3>;

enum class Fit : uint8
{
    None,
    Shared,
    Primary,
};

PrimaryStats ActivePrimaryStats(Player const* player);

Fit ItemFit(PrimaryStats const& stats, ItemTemplate const* item);

template <typename Candidate, typename TemplateOf>
std::vector<Candidate> PreferSpecialization(Player const* player, std::vector<Candidate> const& candidates,
    TemplateOf templateOf)
{
    PrimaryStats const stats = ActivePrimaryStats(player);
    std::vector<Candidate> primary;
    std::vector<Candidate> shared;
    for (Candidate const& candidate : candidates)
    {
        switch (ItemFit(stats, templateOf(candidate)))
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
}

#endif
